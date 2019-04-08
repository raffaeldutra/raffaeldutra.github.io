provider "aws" {
  region  = "${var.provider["region"]}"
  profile = "${var.provider["profile"]}"
}

resource "aws_s3_bucket" "rafaeldutra-me" {
  bucket = "rafaeldutra.me"
  acl    = "public-read"
  policy = "${file("policy-rafaeldutra.me.json")}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  tags {
    Name        = "Bucket Terraform rafaeldutra.me"
    Environment = "prod"
  }
}