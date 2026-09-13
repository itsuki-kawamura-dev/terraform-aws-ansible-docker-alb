resource "aws_s3_bucket" "ansible_transfer" {
  bucket = var.ansible_transfer_bucket_name
}