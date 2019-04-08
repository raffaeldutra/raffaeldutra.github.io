resource "aws_s3_bucket_object" "resume" {
  bucket = "${aws_s3_bucket.www-rafaeldutra-me.id}"
  acl    = "private"
  key    = "resume/"
  source = "/dev/null"
}
