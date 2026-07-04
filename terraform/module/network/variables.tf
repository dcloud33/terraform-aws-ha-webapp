
variable "aws_region"{
    description = "AWS Region"
    default = "us-east-1"
}


variable "vpc_cidr" {
  default = "10.98.0.0/16"
  type    = string
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





















































