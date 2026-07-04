# Launch Template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

resource "aws_launch_template" "ec2_template" {
  name = "example"
  image_id = "ami-test"
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    var.ec2_security_group_id
    ]

  tag_specifications {
    resource_type = "instance"
  }

  user_data = filebase64(var.user_data)
}

# Auto Scaling Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group

resource "aws_launch_template" "example" {
  name_prefix   = "example"
  image_id      = var.ami_id
  instance_type = var.instance_type
}


resource "aws_autoscaling_group" "asg" {
  name = "asg"
  vpc_zone_identifier = var.private_subnet_ids
  
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

  target_group_arns = [
    var.target_group_arn
  ]

  health_check_type = "ELB"
  health_check_grace_period = 300

      launch_template {
      id = aws_launch_template.ec2_template.id

    }
}
























