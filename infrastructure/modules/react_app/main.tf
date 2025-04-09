# modules/react_app/main.tf
variable "s3_bucket_name" {
  default = "my-react-app-b38bc729" # Your existing bucket
}

variable "cloudfront_distribution_id" {
  default = "E2G08P571G5PON" # Your existing CloudFront ID
}

variable "region" {
  default = "ap-south-1" # Mumbai region
}

variable "app_name" {
  default = "my-react-app" # Fixed app name
}

variable "github_repo" {
  default = "ankitkanojia786/Deploying-a-React-Application-with-CI-CD"
}

variable "github_branch" {
  default = "main"
}

variable "codestar_connection_arn" {}

# S3 Bucket Data Source
data "aws_s3_bucket" "react_app" {
  bucket = var.s3_bucket_name
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = data.aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3-my-react-app"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-my-react-app"

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

# CodePipeline Resources
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "my-react-app-pipeline-artifacts"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "my-react-app-pipeline-role"

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

resource "aws_codepipeline" "react_pipeline" {
  name     = "my-react-app-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
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
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "my-react-app-build"
      }
    }
  }
}

# Outputs
output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3_bucket_name" {
  value = data.aws_s3_bucket.react_app.bucket
}

output "codepipeline_name" {
  value = aws_codepipeline.react_pipeline.name
}
