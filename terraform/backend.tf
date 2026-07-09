terraform {
  backend "s3" {
    bucket  = "techbleats-bank-app"
    key     = "uba-bank-app-statefile/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}