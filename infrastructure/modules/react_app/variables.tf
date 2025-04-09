variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID" 
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "my-react-app"
}

variable "github_repo" {
  description = "GitHub repo in owner/repo format"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch name"
  type        = string  
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "CodeStar connection ARN"
  type        = string
}
