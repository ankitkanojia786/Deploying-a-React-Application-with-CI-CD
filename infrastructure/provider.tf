terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0" # Pinned version
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Mumbai
  default_tags {
    tags = {
      Project = "react-app"
    }
  }
}