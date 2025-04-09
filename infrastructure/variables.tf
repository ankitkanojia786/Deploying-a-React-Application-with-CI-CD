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