variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_name" {
  default = "terraform-vpc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet1" {
  default = "10.0.1.0/24"
}

variable "public_subnet2" {
  default = "10.0.2.0/24"
}

variable "private_subnet1" {
  default = "10.0.11.0/24"
}

variable "private_subnet2" {
  default = "10.0.12.0/24"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair Name"
  default     = "terraform-key"
}