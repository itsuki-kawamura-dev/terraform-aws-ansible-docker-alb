# variables.tf
variable "aws_region" {
  description = "default region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "instance_type" {
  description = "type of ec2 instance"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
}

variable "ansible_transfer_bucket_name" {
  description = "ansible transfer bucket name"
  type        = string
}