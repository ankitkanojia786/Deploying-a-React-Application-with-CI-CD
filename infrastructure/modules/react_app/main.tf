# infrastructure/modules/react-app/main.tf
variable "s3_bucket_name" {}
variable "cloudfront_distribution_id" {}
variable "region" {}

# S3 Bucket (reference existing bucket)
data "aws_s3_bucket" "react_app" {
  bucket = var.s3_bucket_name
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.s3_bucket_name}"
}

# S3 Bucket Policy (update existing)
resource "aws_s3_bucket_policy" "react_app" {
  bucket = data.aws_s3_bucket.react_app.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = aws_cloudfront_origin_access_identity.oai.iam_arn },
      Action    = "s3:GetObject",
      Resource  = "${data.aws_s3_bucket.react_app.arn}/*"
    }]
  })
}

# CloudFront Distribution (update existing)
resource "aws_cloudfront_distribution" "react_app" {
  origin {
    domain_name = data.aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3-${var.s3_bucket_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    # ... (keep existing cache behavior config)
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

# CodeBuild Project (new)
resource "aws_codebuild_project" "react_app_build" {
  # ... (add your CodeBuild config here)
}


