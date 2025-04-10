# S3 Bucket Configuration
resource "aws_s3_bucket" "react_app" {
  bucket = var.s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# CloudFront Distribution
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3-${var.app_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.app_name}"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# CodeBuild Project
resource "aws_iam_role" "codebuild_role" {
  name = "${var.app_name}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole", 
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_codebuild_project" "react_app_build" {
  name         = "${var.app_name}-build"
  service_role = aws_iam_role.codebuild_role.arn
  source {
    type     = "GITHUB"
    location = "https://github.com/${var.github_repo}.git"
    buildspec = "buildspec.yml"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "S3_BUCKET"
      value = var.s3_bucket_name
    }
  }
  artifacts { type = "NO_ARTIFACTS" }
}

# CodePipeline
resource "aws_codepipeline" "react_pipeline" {
  name     = "${var.app_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "S3"
      configuration = {
        BucketName = var.s3_bucket_name
        Extract    = "true"
      }
    }
  }
}

# Outputs (ONLY DEFINED HERE - NO outputs.tf FILE)
output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.react_app.bucket
}

output "codepipeline_name" {
  description = "CodePipeline Name"
  value       = aws_codepipeline.react_pipeline.name
}

# Add these resources ABOVE the codepipeline definition

# Pipeline Artifacts Bucket
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.app_name}-pipeline-artifacts"
  force_destroy = true
}

# Pipeline IAM Role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

# Pipeline IAM Policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.app_name}-pipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.pipeline_artifacts.arn}/*"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ],
        Effect   = "Allow",
        Resource = var.codestar_connection_arn
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Effect   = "Allow",
        Resource = aws_codebuild_project.react_app_build.arn
      }
    ]
  })
}
