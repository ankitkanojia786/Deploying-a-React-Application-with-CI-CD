output "app_url" {
  description = "CloudFront URL for the application"
  value       = module.react_app.cloudfront_url
}

output "s3_bucket" {
  description = "Name of the S3 bucket hosting the app"
  value       = module.react_app.s3_bucket_name
}

output "pipeline" {
  description = "Name of the CodePipeline"
  value       = module.react_app.codepipeline_name
}
