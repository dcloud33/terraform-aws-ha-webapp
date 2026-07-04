# Compute ASG Module

## Overview

This module creates the compute layer for the Terraform AWS High-Availability Web App.

The compute layer uses an Auto Scaling Group to launch EC2 instances across private subnets. The instances are registered with the Application Load Balancer target group.

## What This Module Builds

This module may create:

- Launch template
- Auto Scaling Group
- EC2 instance configuration
- User data configuration
- Target group attachment through the ASG
- ASG tags

## Architecture Role

The compute module runs the application behind the ALB.

```text
Application Load Balancer
  ↓
Target Group
  ↓
Auto Scaling Group
  ↓
EC2 instances in private subnets
```

## Example Usage

```hcl
module "compute_asg" {
  source = "../../modules/compute_asg"

  project_name         = "ha-web-app"
  environment          = "dev"
  private_subnet_ids    = module.network.private_subnet_ids
  ec2_security_group_id = module.security_groups.ec2_security_group_id
  target_group_arn      = module.alb.target_group_arn

  ami_id           = var.ami_id
  instance_type    = "t3.micro"
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "Hello from Terraform ASG" > /var/www/html/index.html
  EOF
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---:|---|
| project_name | string | yes | Project name used for resource naming |
| environment | string | yes | Environment name such as `dev`, `stage`, or `prod` |
| private_subnet_ids | list(string) | yes | Private subnet IDs where EC2 instances are launched |
| ec2_security_group_id | string | yes | Security group ID attached to EC2 instances |
| target_group_arn | string | yes | ALB target group ARN used by the ASG |
| ami_id | string | yes | AMI ID used by the launch template |
| instance_type | string | yes | EC2 instance type |
| min_size | number | yes | Minimum number of EC2 instances |
| max_size | number | yes | Maximum number of EC2 instances |
| desired_capacity | number | yes | Desired number of EC2 instances |
| user_data | string | no | Startup script used when EC2 instances launch |
| tags | map(string) | no | Additional tags applied to resources |

## Outputs

| Name | Description |
|---|---|
| autoscaling_group_name | Name of the Auto Scaling Group |
| autoscaling_group_arn | ARN of the Auto Scaling Group |
| launch_template_id | ID of the launch template |
| launch_template_latest_version | Latest version of the launch template |

## Design Notes

- EC2 instances should be launched in private subnets.
- The Auto Scaling Group should span multiple Availability Zones for high availability.
- The ASG should attach instances to the ALB target group.
- The ALB target group should use `ELB` health checks when checking application availability.
- User data should install and start the web server or application.
- Security groups should only allow inbound application traffic from the ALB security group.

## Common Issues

### EC2 Instances Are Not Launching

Possible causes:

- Invalid AMI ID
- Invalid subnet IDs
- Missing IAM permissions
- Launch template configuration error
- Requested instance type is unavailable in the selected Availability Zone

### EC2 Instances Are Unhealthy

Possible causes:

- Web server failed to install
- Web server failed to start
- User data script has an error
- EC2 security group blocks ALB traffic
- Target group health check path is incorrect

### ASG Launches Instances but ALB Returns 503

Possible causes:

- Instances are not registered with the target group
- Target group health checks are failing
- Application is not listening on the expected port
- Security group rules are incorrect

## Validation

Check Auto Scaling Group capacity:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg_name>
```

Check running EC2 instances:

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --output table
```

Check target health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target_group_arn>
```

Expected result:

```text
Targets should show healthy
```
