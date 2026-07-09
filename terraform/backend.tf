terraform {
  backend "s3" {
    bucket  = "techbleat-bank-application"
    key     = "ecobank-bank-app-statefile/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}