# modules/react_app/main.tf
variable "s3_bucket_name" {}
variable "cloudfront_distribution_id" {}
variable "region" {}
variable "app_name" {}
variable "github_repo" {}
variable "github_branch" {}
variable "codestar_connection_arn" {}

# S3 Bucket Data Source
data "aws_s3_bucket" "react_app" {
  bucket = var.s3_bucket_name
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name}"
}

# CloudFront Distribution (Fixed)
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = data.aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3Origin-${var.app_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${var.app_name} distribution"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin-${var.app_name}"

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
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.app_name}-codebuild-role"

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

# CodeBuild Project (Fixed)
resource "aws_codebuild_project" "react_app_build" {
  name          = "${var.app_name}-build"
  description   = "Build for ${var.app_name}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 10

  source {
    type      = "GITHUB"
    location  = "https://github.com/${var.github_repo}.git"
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
    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = aws_cloudfront_distribution.s3_distribution.id
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

# Outputs (Fixed)
output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = data.aws_s3_bucket.react_app.bucket
}
