provider "aws" {
  region  = "${var.provider["region"]}"
  profile = "${var.provider["profile"]}"
}

resource "aws_s3_bucket" "www-rafaeldutra-me" {
  bucket = "www.rafaeldutra.me"
  acl    = "public-read"
  policy = "${file("policy-rafaeldutra.me.json")}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  website {
    redirect_all_requests_to = "https://rafaeldutra.me"
  }

  tags {
    Name        = "Bucket Terraform rafaeldutra.me"
    Environment = "prod"
  }
}