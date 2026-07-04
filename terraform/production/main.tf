terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.52.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


module "network" {
  source               = "../module/network"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

}

module "security_groups" {
  source = "../module/security_groups"
  vpc_id = module.network.vpc_id
}

module "alb" {
  source = "../module/alb"

  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  target_port           = 80
  health_check_path     = "/"
}


module "compute" {
  source                = "../module/compute_asg"
  ec2_security_group_id = module.security_groups.ec2_security_group_id
  private_subnet_ids    = module.network.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn

  ami_id           = var.ami_id
  instance_type    = var.instance_type
  user_data        = var.user_data
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity


}






























































