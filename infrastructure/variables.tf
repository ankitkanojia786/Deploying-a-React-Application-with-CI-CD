variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in format owner/repo"
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "GitHub branch to monitor"
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar GitHub connection"
  type        = string
  default     = "arn:aws:codestar-connections:ap-south-1:860265990835:connection/b9b175eb-c417-44dc-8e1b-332d71300d5a"
}

# New variables for email alerts
variable "notification_email" {
  description = "Email address to receive pipeline failure notifications"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for hosting the React app"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID (if any)"
  type        = string
  default     = ""
}
