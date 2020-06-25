variable "role_arn" {
  type = map

  default = {
    prd = "arn:aws:iam::007676985961:role/rafaeldutra-me"
  }
}

provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn = var.role_arn[terraform.workspace]
  }
}

resource "aws_s3_bucket" "this" {
  bucket = "rafaeldutra.me"
  acl    = "public-read"
  policy = file(format("%s-policy-rafaeldutra.me.json", terraform.workspace))

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  website {
    redirect_all_requests_to = "https://rafaeldutra.me"
  }

  tags = {
    Name        = "Bucket Terraform rafaeldutra.me"
    Environment = terraform.workspace
  }
}

resource "aws_s3_bucket_object" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "resume/"
  source = "/dev/null"
}