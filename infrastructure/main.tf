terraform {
  required_version = ">= 1.5.0"
}

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.app_name}-github-connection"
  provider_type = "GitHub"
  tags = {
    Project = var.app_name
  }
}

module "react_app" {
  source = "./modules/react_app"

  # Required arguments from earlier errors
  s3_bucket_name            = "my-react-app-b38bc729"  # Your existing bucket
  cloudfront_distribution_id = "E2G08P571G5PON"        # Your existing CloudFront ID
  region                    = "ap-south-1"             # Mumbai region

  # GitHub/Codestar arguments
  app_name                = var.app_name
  github_repo             = var.github_repo
  github_branch           = var.github_branch
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
}
