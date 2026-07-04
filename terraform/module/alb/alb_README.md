# ALB Module

## Overview

This module creates the Application Load Balancer layer for the Terraform AWS High-Availability Web App.

The Application Load Balancer receives public web traffic and forwards it to EC2 instances running in private subnets through a target group.

## What This Module Builds

This module may create:

- Application Load Balancer
- ALB target group
- HTTP listener
- Health check configuration
- ALB tags

## Architecture Role

The ALB sits in the public subnets and forwards traffic to EC2 instances in private subnets.

```text
User
  ↓
Application Load Balancer
  ↓
Target Group
  ↓
EC2 instances in private subnets
```

## Example Usage

```hcl
module "alb" {
  source = "../../modules/alb"

  project_name          = "ha-web-app"
  environment           = "dev"
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id

  target_port       = 80
  health_check_path = "/"
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---:|---|
| project_name | string | yes | Project name used for resource naming |
| environment | string | yes | Environment name such as `dev`, `stage`, or `prod` |
| vpc_id | string | yes | VPC ID where the target group is created |
| public_subnet_ids | list(string) | yes | Public subnet IDs where the ALB is deployed |
| alb_security_group_id | string | yes | Security group ID attached to the ALB |
| target_port | number | no | Port used by the backend EC2 targets |
| health_check_path | string | no | Path used by the target group health check |
| tags | map(string) | no | Additional tags applied to resources |

## Outputs

| Name | Description |
|---|---|
| alb_arn | ARN of the Application Load Balancer |
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_zone_id | Hosted zone ID of the Application Load Balancer |
| target_group_arn | ARN of the ALB target group |
| listener_arn | ARN of the ALB listener |

## Design Notes

- The ALB should be deployed in public subnets.
- The ALB security group should allow inbound HTTP or HTTPS traffic from users.
- EC2 instances should not allow direct inbound traffic from the internet.
- EC2 instances should only allow inbound traffic from the ALB security group.
- The health check path must return a successful HTTP response, usually `200`.

## Common Issues

### ALB Returns 503

Possible causes:

- No healthy targets are registered
- EC2 instances are not running
- EC2 security group blocks traffic from the ALB
- Web server is not running on the EC2 instances
- Target group health check path is incorrect

### Targets Are Unhealthy

Possible causes:

- Application is not listening on the target port
- User data failed during EC2 launch
- Security group rule is missing
- Health check path does not exist
- EC2 instances are still starting

## Validation

After deployment, check the ALB DNS name:

```bash
terraform output
```

Test the endpoint:

```bash
curl http://<alb_dns_name>
```

Expected result:

```text
HTTP 200 response from the web application
```

Check target health in the AWS Console:

```text
EC2 → Target Groups → Targets
```

Expected result:

```text
Targets should show healthy
```
