resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = "${var.app_name}-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags = {
    Project = var.app_name
  }
}

resource "aws_s3_bucket_ownership_controls" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "website_access" {
  bucket = aws_s3_bucket.app_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name}"
}

resource "aws_s3_bucket_policy" "app_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.app_bucket,
    aws_s3_bucket_public_access_block.website_access
  ]
  bucket = aws_s3_bucket.app_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { AWS = aws_cloudfront_origin_access_identity.oai.iam_arn },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.app_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.app_bucket.bucket}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.app_bucket.bucket}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.app_name}-cb-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cb_s3_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# CodeBuild project
resource "aws_codebuild_project" "react_build" {
  name          = "${var.app_name}-build"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
  }
  source {
    type = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 16
    commands:
      - npm install
  build:
    commands:
      - npm run build
artifacts:
  base-directory: build
  files:
    - '**/*'
EOF
  }
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-cp-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cp_full_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CodePipeline
resource "aws_codepipeline" "react_pipeline" {
  name     = "${var.app_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.app_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn = var.codestar_connection_arn
        FullRepositoryId = var.github_repo
        BranchName = var.github_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.react_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      input_artifacts  = ["build_output"]
      version          = "1"
      configuration = {
        BucketName = aws_s3_bucket.app_bucket.bucket
        Extract    = "true"
      }
    }
  }
}
