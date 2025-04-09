output "app_url" {
  description = "Application URL via CloudFront"
  value       = module.react_app.cloudfront_url
}

output "bucket_name" {
  description = "S3 bucket name hosting the app"
  value       = module.react_app.s3_bucket_name
}

output "pipeline_name" {
  description = "CodePipeline name"
  value       = module.react_app.codepipeline_name
}