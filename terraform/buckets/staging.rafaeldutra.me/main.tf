provider "aws" {
  region  = "${var.provider["region"]}"
  profile = "${var.provider["profile"]}"
}

resource "aws_s3_bucket" "staging-rafaeldutra-me" {
  bucket = "staging.rafaeldutra.me"
  acl    = "public-read"
  policy = "${file("staging-policy-rafaeldutra.me.json")}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }
  
  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags {
    Name        = "Bucket Terraform staging.rafaeldutra.me"
    Environment = "staging"
  }
}