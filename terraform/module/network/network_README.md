# Network Module

## Overview

This module creates the network foundation for the Terraform AWS High-Availability Web App.

The network module creates a VPC with public and private subnets across multiple Availability Zones. Public subnets are used for internet-facing resources such as the Application Load Balancer and NAT Gateway. Private subnets are used for EC2 application instances and databases.

## What This Module Builds

This module may create:

- VPC
- Public subnets
- Private subnets
- Internet Gateway
- Elastic IPs for NAT Gateway
- NAT Gateway
- Public route table
- Private route table
- Route table associations
- Network-related tags

## Architecture Role

The network module provides the foundation that all other modules use.

```text
VPC
├── Public Subnet A
│   ├── Application Load Balancer
│   └── NAT Gateway
│
├── Public Subnet B
│   └── Application Load Balancer
│
├── Private Subnet A
│   └── EC2 instance
│
└── Private Subnet B
    └── EC2 instance
```

## Example Usage

```hcl
module "network" {
  source = "../../modules/network"

  project_name = "ha-web-app"
  environment  = "dev"

  vpc_cidr = "10.98.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.98.10.0/24",
    "10.98.20.0/24"
  ]

  private_subnet_cidrs = [
    "10.98.11.0/24",
    "10.98.21.0/24"
  ]

  enable_nat_gateway = true
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---:|---|
| project_name | string | yes | Project name used for resource naming |
| environment | string | yes | Environment name such as `dev`, `stage`, or `prod` |
| vpc_cidr | string | yes | CIDR block for the VPC |
| availability_zones | list(string) | yes | Availability Zones used for subnet placement |
| public_subnet_cidrs | list(string) | yes | CIDR blocks for public subnets |
| private_subnet_cidrs | list(string) | yes | CIDR blocks for private subnets |
| enable_nat_gateway | bool | no | Whether to create a NAT Gateway |
| single_nat_gateway | bool | no | Whether to create one NAT Gateway instead of one per AZ |
| tags | map(string) | no | Additional tags applied to resources |

## Outputs

| Name | Description |
|---|---|
| vpc_id | ID of the created VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| public_route_table_ids | IDs of the public route tables |
| private_route_table_ids | IDs of the private route tables |
| nat_gateway_ids | IDs of the NAT Gateways |
| internet_gateway_id | ID of the Internet Gateway |

## Design Notes

- Public subnets should route `0.0.0.0/0` to the Internet Gateway.
- Private subnets should route `0.0.0.0/0` to the NAT Gateway.
- NAT Gateway should be deployed in a public subnet.
- Application EC2 instances should be deployed in private subnets.
- The ALB should be deployed in public subnets.
- For production, consider using one NAT Gateway per Availability Zone.
- For dev or lab environments, a single NAT Gateway can reduce cost.

## Common Issues

### Private EC2 Instances Cannot Reach the Internet

Possible causes:

- NAT Gateway does not exist
- NAT Gateway is in a private subnet
- NAT Gateway does not have an Elastic IP
- Private route table does not route to NAT Gateway
- Public route table does not route to Internet Gateway

### ALB Cannot Be Created

Possible causes:

- Not enough public subnets
- Public subnets are not in multiple Availability Zones
- Subnet IDs are incorrect
- VPC ID is incorrect

### Terraform Subnet CIDR Error

Possible causes:

- Subnet CIDR is outside the VPC CIDR range
- Public and private subnet CIDRs overlap
- CIDR block is too large or invalid

## Validation

Check VPC:

```bash
aws ec2 describe-vpcs \
  --vpc-ids <vpc_id>
```

Check subnets:

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<vpc_id>" \
  --output table
```

Check route tables:

```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=<vpc_id>" \
  --output table
```

Expected routing:

```text
Public subnet route table:
0.0.0.0/0 → Internet Gateway

Private subnet route table:
0.0.0.0/0 → NAT Gateway
```
