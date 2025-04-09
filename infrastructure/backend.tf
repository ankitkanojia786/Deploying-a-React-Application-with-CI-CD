terraform {
  backend "s3" {
    bucket         = "ankit-tf-state-bucket-name-2025" 
    key            = "react-app-infra/terraform.tfstate"
    region         = "ap-south-1"                     
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}