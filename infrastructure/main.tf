# infrastructure/main.tf
terraform {
  required_version = ">= 1.5.0"
}

# Keep your existing provider.tf and backend.tf AS IS
# Keep your existing outputs.tf AS IS

module "react_app" {
  source = "./modules/react_app"

  # Required variables
  app_name                = "my-react-app"
  github_repo             = "ankitkanojia786/Deploying-a-React-Application-with-CI-CD"
  github_branch           = "main"
  s3_bucket_name          = "my-react-app-b38bc729"
  cloudfront_distribution_id = "E2G08P571G5PON"
}
