### Application LoadBalancer SG ########
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "alb" { # http traffic will be going to the alb
  name        = "alb_sg"
  description = "Security Group for Application LB"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "ec2_sg"
  description = "EC2 application security group"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id = aws_security_group.ec2.id
  referenced_security_group_id =    aws_security_group.alb.id
  from_port         = var.app_port
  ip_protocol       = "tcp"
  to_port           = var.app_port
}





















