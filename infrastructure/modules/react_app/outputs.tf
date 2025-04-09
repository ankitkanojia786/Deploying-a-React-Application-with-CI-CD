output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.react_app.bucket
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.react_pipeline.name
}
