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

  app_name                = var.app_name
  github_repo             = var.github_repo
  github_branch           = var.github_branch
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
}