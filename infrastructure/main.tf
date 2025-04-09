module "react_app" {
  source = "./modules/react_app"

  # Required arguments
  app_name                = "my-react-app"
  github_repo             = "ankitkanojia786/Deploying-a-React-Application-with-CI-CD"
  github_branch           = "main"
  s3_bucket_name          = "my-react-app-b38bc729"
  cloudfront_distribution_id = "E2G08P571G5PON"
  codestar_connection_arn = "arn:aws:codestar-connections:ap-south-1:860265990835:connection/b9b175eb-c417-44dc-8e1b-332d71300d5a" # ADD THIS LINE
}
