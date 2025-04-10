variable "s3_bucket_name" {
  description = "Name of the S3 bucket for hosting the React application (must be globally unique)"
  type        = string
}

variable "app_name" {
  description = "Application name used for resource naming and tags"
  type        = string
  default     = "my-react-app"
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo-name' (e.g., 'my-org/my-react-app')"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to monitor for changes"
  type        = string  
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar connection to GitHub (created in AWS Console first)"
  type        = string
}

variable "notification_email" {
  description = "Email address to receive pipeline failure notifications"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1" # Explicitly set to your region
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild image identifier"
  type        = string
  default     = "aws/codebuild/standard:6.0"
}

variable "cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID"
  type        = string
  default     = "" # Empty string means create new by default
}

variable "cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID"
  type        = string
  default     = "" # Empty string means create new by default
}
