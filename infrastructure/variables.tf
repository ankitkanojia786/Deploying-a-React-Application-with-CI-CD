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
