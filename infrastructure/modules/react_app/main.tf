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

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  # ... (keep your existing CloudFront config) ...
}

# CodePipeline Resources
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.app_name}-pipeline-artifacts"
}

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

resource "aws_codepipeline" "react_pipeline" {
  name     = "${var.app_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
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
        ProjectName = aws_codebuild_project.react_app_build.name
      }
    }
  }
}

# Outputs
output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = data.aws_s3_bucket.react_app.bucket
}

output "codepipeline_name" {
  value = aws_codepipeline.react_pipeline.name
}
