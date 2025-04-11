# S3 Bucket for React App (updated for AWS S3 ACL changes)
resource "aws_s3_bucket" "react_app" {
  bucket = var.s3_bucket_name
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

resource "aws_s3_bucket_ownership_controls" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_bucket_policy" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.react_app.arn}/*"
      }
    ]
  })
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
  is_ipv6_enabled     = true
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

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

# IAM Roles and Policies
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

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.app_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.react_app.arn,
          "${aws_s3_bucket.react_app.arn}/*",
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudfront:CreateInvalidation",
          "sns:Publish"
        ],
        Resource = ["*"]
      }
    ]
  })
}

# CodeBuild Project
resource "aws_codebuild_project" "react_app_build" {
  name          = "${var.app_name}-build"
  service_role  = aws_iam_role.codebuild_role.arn
  
  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }
  
  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    
    environment_variable {
      name  = "S3_BUCKET"
      value = var.s3_bucket_name
    }
    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = aws_cloudfront_distribution.s3_distribution.id
    }
    environment_variable {
      name  = "TERRAFORM_FAILURE_TOPIC_ARN"
      value = aws_sns_topic.terraform_failures.arn
    }
    environment_variable {
      name  = "APP_NAME"
      value = var.app_name
    }
  }
  
  artifacts {
    type = "CODEPIPELINE"
  }

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

# Pipeline Artifacts Bucket (updated for ACL changes)
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.app_name}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

resource "aws_s3_bucket_ownership_controls" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_caller_identity" "current" {}

# CodePipeline Resources
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.app_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.react_app.arn,
          "${aws_s3_bucket.react_app.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

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
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration    = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
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
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration    = {
        ProjectName = aws_codebuild_project.react_app_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration   = {
        BucketName = var.s3_bucket_name
        Extract    = "true"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

# Alerting System
resource "aws_sns_topic" "terraform_failures" {
  name = "${var.app_name}-terraform-failures"
  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.terraform_failures.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.terraform_failures.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com", "events.amazonaws.com"]
    }
    resources = [aws_sns_topic.terraform_failures.arn]
  }
}

# Outputs
output "cloudfront_url" {
  description = "The CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.react_app.bucket
}

output "codepipeline_name" {
  description = "The name of the CodePipeline"
  value       = aws_codepipeline.react_pipeline.name
}

output "sns_topic_arn" {
  description = "ARN of the failure notification topic"
  value       = aws_sns_topic.terraform_failures.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.react_app_build.name
}
