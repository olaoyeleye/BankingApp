terraform {
  backend "s3" {
    bucket  = "techbleat-bank-app"
    key     = "bank-app-statefile/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}