
variable "private_subnet_ids"{
    type = list(string)
}

variable "ec2_security_group_id"{
    type = string
}

variable target_group_arn{
    type = string
}

variable "ami_id"{
    type = string
}


variable "instance_type"{
    type = string
}

variable "user_data"{
    type = string
    default = ""
}

variable "min_size"{
    type = number
}

variable "max_size"{
    type = number
}

variable "desired_capacity"{
    type = number
}








































