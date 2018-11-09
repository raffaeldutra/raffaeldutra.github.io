resource "aws_s3_bucket" "rafaeldutra_me" {
  bucket = "rafaeldutra.me"
  acl    = "public-read"
  policy = "${file("rafaeldutra.me.json")}"

  tags {
    Name        = "rafaeldutra.me"
    Environment = "prod"
  }
}

resource "aws_s3_bucket_object" "resume" {
  bucket = "${aws_s3_bucket.rafaeldutra_me.id}"
  acl    = "private"
  key    = "resume/"
  source = "/dev/null"
}
