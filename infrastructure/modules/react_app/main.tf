# modules/react_app/main.tf
variable "s3_bucket_name" {}
variable "cloudfront_distribution_id" {}
variable "app_name" {}
variable "github_repo" {}
variable "github_branch" {}

# S3 Configuration
resource "aws_s3_bucket" "react_app" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

# CloudFront Configuration
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3Origin"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  enabled             = true
  default_root_object = "index.html"
  # ... (rest of your CloudFront config) ...
}

# CodePipeline with DEPLOY STAGE
resource "aws_codepipeline" "react_pipeline" {
  # ... (source and build stages) ...

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        BucketName = var.s3_bucket_name
        Extract    = "true"
      }
    }
  }
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
