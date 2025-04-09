output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  description = "Name of the hosting S3 bucket"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "codepipeline_name" {
  value = aws_codepipeline.react_pipeline.name
}

