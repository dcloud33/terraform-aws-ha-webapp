# Security Groups Module

## Overview

This module creates security groups for the Terraform AWS High-Availability Web App.

Security groups control which traffic is allowed between the internet, Application Load Balancer, EC2 instances, and database.

## What This Module Builds

This module may create:

- ALB security group
- EC2 application security group
- Database security group
- Security group ingress rules
- Security group egress rules

## Architecture Role

This module defines the network access rules between the application layers.

```text
Internet
  ↓
ALB Security Group
  ↓
EC2 Security Group
  ↓
Database Security Group
```

## Recommended Security Flow

The recommended access pattern is:

```text
Internet → ALB
ALB → EC2
EC2 → Database
EC2 → Internet outbound through NAT Gateway
```

The EC2 instances should not allow direct inbound traffic from the internet.

## Example Usage

```hcl
module "security_groups" {
  source = "../../modules/security_groups"

  project_name = "ha-web-app"
  environment  = "dev"
  vpc_id       = module.network.vpc_id

  app_port = 80
  db_port  = 3306
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---:|---|
| project_name | string | yes | Project name used for resource naming |
| environment | string | yes | Environment name such as `dev`, `stage`, or `prod` |
| vpc_id | string | yes | VPC ID where security groups are created |
| app_port | number | no | Application port allowed from ALB to EC2 |
| db_port | number | no | Database port allowed from EC2 to database |
| allowed_http_cidrs | list(string) | no | CIDR blocks allowed to reach the ALB on HTTP |
| allowed_https_cidrs | list(string) | no | CIDR blocks allowed to reach the ALB on HTTPS |
| tags | map(string) | no | Additional tags applied to resources |

## Outputs

| Name | Description |
|---|---|
| alb_security_group_id | Security group ID for the Application Load Balancer |
| ec2_security_group_id | Security group ID for EC2 application instances |
| db_security_group_id | Security group ID for the database |

## Design Notes

- The ALB security group may allow inbound HTTP or HTTPS from the internet.
- The EC2 security group should only allow inbound application traffic from the ALB security group.
- The database security group should only allow inbound database traffic from the EC2 security group.
- Avoid allowing direct inbound traffic to EC2 from `0.0.0.0/0`.
- Avoid allowing database access from `0.0.0.0/0`.
- Start with simple rules for a lab, then tighten them as the design improves.

## Common Issues

### ALB Cannot Reach EC2

Possible causes:

- EC2 security group does not allow inbound traffic from ALB security group
- Wrong application port
- EC2 instances are not listening on the expected port
- Target group health check port does not match the app port

### Database Cannot Be Reached from EC2

Possible causes:

- Database security group does not allow traffic from EC2 security group
- Wrong database port
- Database is in the wrong subnet
- Application uses the wrong database endpoint

### EC2 Is Exposed to the Internet

Possible causes:

- EC2 security group allows inbound traffic from `0.0.0.0/0`
- EC2 instance is launched in a public subnet
- EC2 instance has a public IP address

## Validation

Check security group rules:

```bash
aws ec2 describe-security-groups \
  --group-ids <security_group_id>
```

Expected application flow:

```text
ALB SG:
Inbound 80/443 from allowed CIDRs

EC2 SG:
Inbound app port from ALB SG only

DB SG:
Inbound database port from EC2 SG only
```

## Security Reminder

Security groups are stateful. If inbound traffic is allowed, the response traffic is automatically allowed back out. Still, outbound rules should be reviewed and tightened based on the application requirements.
