terraform {
  backend "s3" {
    bucket  = "techbleat-bank-application"
    key     = "banking-app/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}