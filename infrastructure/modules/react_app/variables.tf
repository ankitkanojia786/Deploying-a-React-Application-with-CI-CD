variable "app_name" {
  type        = string
  description = "Name prefix for all resources"
}

variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region for deployment"
}

variable "codestar_connection_arn" {
  type        = string
  description = "ARN of AWS CodeStar GitHub connection"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/repo format"
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "GitHub branch to monitor"
}