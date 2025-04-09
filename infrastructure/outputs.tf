output "app_url" {
  description = "CloudFront URL for the React application"
  value       = module.react_app.cloudfront_url
}

output "bucket_name" {
  description = "Name of the S3 bucket hosting the app"
  value       = module.react_app.s3_bucket_name
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.react_app.codepipeline_name
}
