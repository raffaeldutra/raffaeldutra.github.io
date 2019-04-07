provider "aws" {
  region  = "${var.provider["region"]}"
  profile = "${var.provider["profile"]}"
}

terraform {
  backend "s3" {
    bucket  = "rafaeldutra-me"
    key     = "terraform.tfstate"
    region  = "sa-east-1"
    profile = "rafaeldutra-me"
  }
}