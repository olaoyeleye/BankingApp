terraform {
  backend "s3" {
    bucket  = "techbleat-bank-application"
    key     = "banking-app/terraform.tfstate" # Overridden via -backend-config at terraform init
    region  = "eu-west-1"
    encrypt = true
  }
}
