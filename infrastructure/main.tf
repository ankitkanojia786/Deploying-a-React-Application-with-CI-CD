# infrastructure/main.tf
terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket = "my-react-app-tfstate"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "react_app" {
  source = "./modules/react_app"

  # Required variables
  app_name                = "my-react-app"
  github_repo             = "ankitkanojia786/Deploying-a-React-Application-with-CI-CD"
  github_branch           = "main"
  s3_bucket_name          = "my-react-app-b38bc729"
  cloudfront_distribution_id = "E2G08P571G5PON"
}

output "app_url" {
  value = module.react_app.cloudfront_url
}
