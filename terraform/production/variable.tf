variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.98.0.0/16"
  type    = string
}

variable "vpc_id" {
  type    = string
  default = "vpc_network"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "user_data" {
  type    = string
  default = "./src/app.py"
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "ami_id" {
  type = string
}
























