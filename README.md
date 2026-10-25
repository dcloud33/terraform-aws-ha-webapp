# Terraform AWS High-Availability Web App

## Overview

This project deploys a high-availability web application infrastructure on AWS using Terraform.

The infrastructure is designed with reusable Terraform modules for networking, security groups, load balancing, and compute. The application runs on EC2 instances inside private subnets and receives traffic through an internet-facing Application Load Balancer.

The goal of this project is to practice building reusable Terraform modules while also creating a realistic AWS architecture that follows common cloud design patterns.

---

## Architecture

The architecture includes:

* One VPC
* Public subnets across multiple Availability Zones
* Private subnets across multiple Availability Zones
* Internet Gateway
* NAT Gateway for private subnet outbound internet access
* Application Load Balancer in public subnets
* Auto Scaling Group running EC2 instances in private subnets
* Security groups separating ALB and EC2 traffic

### Traffic Flow

```text
User
  ↓
Application Load Balancer
  ↓
Target Group
  ↓
EC2 instances in private subnets
```

### Outbound Internet Flow for Private EC2 Instances

```text
Private EC2 Instance
  ↓
Private Route Table
  ↓
NAT Gateway
  ↓
Internet Gateway
  ↓
Internet
```

---

## What This Project Builds

This Terraform project builds the following AWS resources:

| Resource                  | Purpose                                                           |
| ------------------------- | ----------------------------------------------------------------- |
| VPC                       | Provides the isolated network for the application                 |
| Public Subnets            | Host public-facing resources such as the ALB and NAT Gateway      |
| Private Subnets           | Host EC2 application instances                                    |
| Internet Gateway          | Allows public subnet resources to reach the internet              |
| NAT Gateway               | Allows private subnet resources to reach the internet outbound    |
| Route Tables              | Control traffic flow between subnets and gateways                 |
| Security Groups           | Control inbound and outbound network access                       |
| Application Load Balancer | Distributes traffic across EC2 instances                          |
| Target Group              | Registers EC2 instances behind the ALB                            |
| Launch Template           | Defines how EC2 instances are launched                            |
| Auto Scaling Group        | Maintains desired EC2 capacity across multiple Availability Zones |

---

## Repository Structure

```text
terraform-aws-ha-web-app/
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
│
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── security_groups/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── compute_asg/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── runbook.md
├── architecture.md
└── README.md
```

---

## Prerequisites

Before deploying, you need:

* Terraform installed
* AWS CLI installed
* AWS credentials configured
* An AWS account with permission to create VPC, EC2, ALB, Auto Scaling, IAM, and networking resources

Verify AWS access:

```bash
aws sts get-caller-identity
```

Verify Terraform:

```bash
terraform version
```

---

## How to Deploy

From the environment folder:

```bash
cd environments/dev
```

Initialize Terraform:

```bash
terraform init
```

Format Terraform files:

```bash
terraform fmt -recursive
```

Validate the configuration:

```bash
terraform validate
```

Review the execution plan:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

---

## How to Validate

After deployment, get the Terraform outputs:

```bash
terraform output
```

Look for the ALB DNS name.

Test the application:

```bash
curl http://<alb_dns_name>
```

Expected result:

```text
HTTP 200 response from the web application
```

You can also validate the application through the AWS Console:

```text
EC2 → Target Groups → Targets
```

Expected target health:

```text
healthy
```

---

## How to Destroy

To remove the infrastructure:

```bash
terraform destroy
```

After destroying, confirm the following resources were removed:

* EC2 instances
* Auto Scaling Group
* Application Load Balancer
* Target Group
* NAT Gateway
* Elastic IP
* Route Tables
* Subnets
* VPC

---

## Modules Used

| Module          | Purpose                                                               |
| --------------- | --------------------------------------------------------------------- |
| network         | Creates VPC, subnets, route tables, Internet Gateway, and NAT Gateway |
| security_groups | Creates ALB and EC2 security groups                                   |
| alb             | Creates Application Load Balancer, target group, and listener         |
| compute_asg     | Creates launch template and Auto Scaling Group                        |

---

## Inputs

Common input variables for this project may include:

| Input                | Description                               | Example                              |
| -------------------- | ----------------------------------------- | ------------------------------------ |
| project_name         | Name of the project                       | `ha-web-app`                         |
| environment          | Deployment environment                    | `dev`                                |
| vpc_cidr             | CIDR block for the VPC                    | `10.98.0.0/16`                       |
| public_subnet_cidrs  | CIDR blocks for public subnets            | `["10.98.10.0/24", "10.98.20.0/24"]` |
| private_subnet_cidrs | CIDR blocks for private subnets           | `["10.98.11.0/24", "10.98.21.0/24"]` |
| availability_zones   | Availability Zones used by the deployment | `["us-east-1a", "us-east-1b"]`       |
| instance_type        | EC2 instance type                         | `t3.micro`                           |
| min_size             | Minimum number of EC2 instances           | `2`                                  |
| max_size             | Maximum number of EC2 instances           | `4`                                  |
| desired_capacity     | Desired number of EC2 instances           | `2`                                  |

---

## Outputs

Common outputs for this project may include:

| Output                 | Description                               |
| ---------------------- | ----------------------------------------- |
| vpc_id                 | ID of the created VPC                     |
| public_subnet_ids      | IDs of the public subnets                 |
| private_subnet_ids     | IDs of the private subnets                |
| alb_dns_name           | DNS name of the Application Load Balancer |
| target_group_arn       | ARN of the ALB target group               |
| autoscaling_group_name | Name of the Auto Scaling Group            |

---

## Common Issues

### ALB Returns 503

Possible causes:

* EC2 instances are unhealthy
* Target group has no registered targets
* Health check path is incorrect
* EC2 security group does not allow traffic from the ALB security group
* Web server failed to start during user data execution

### EC2 Instances Cannot Reach the Internet

Possible causes:

* NAT Gateway is missing
* NAT Gateway is in the wrong subnet
* Private route table does not route `0.0.0.0/0` to the NAT Gateway
* Public route table does not route `0.0.0.0/0` to the Internet Gateway
* NAT Gateway does not have an Elastic IP

### Terraform Cannot Find a Module

Possible causes:

* Incorrect module source path
* Running Terraform from the wrong folder
* Module folder name does not match the source path

Example:

```hcl
module "network" {
  source = "../../modules/network"
}
```

After fixing a module path issue, run:

```bash
terraform init
```

---

## Runbook

Operational steps for deploying, validating, troubleshooting, rolling back, and destroying this project are documented in:

```text
runbook.md
```

The runbook includes:

* Deployment procedure
* Validation procedure
* ALB troubleshooting
* EC2 troubleshooting
* NAT Gateway troubleshooting
* Terraform module troubleshooting
* Rollback procedure
* Destroy procedure

---

## Diagram

The architecture diagram should show:

* AWS Region
* VPC boundary
* Public subnets
* Private subnets
* Application Load Balancer
* Auto Scaling Group
* EC2 instances
* NAT Gateway
* Internet Gateway
* Traffic flow arrows

Recommended diagram path:

```text
diagrams/architecture.mmd
```

Recommended documentation path:

```text
architecture.md
```

---

## EC2 Auto Scaling Failure Recovery Test

### Objective
Validate that the AWS Auto Scaling Group automatically replaces a failed EC2 instance while the Application Load Balancer continues serving traffic through healthy instances.

### Test Environment
- **Infrastructure:** Terraform-managed AWS resources
- **Compute:** EC2 instances in private subnets
- **Load Balancing:** Application Load Balancer
- **Recovery:** EC2 Auto Scaling Group
- **Availability:** Multiple Availability Zones

### Test Procedure
1. Confirmed that the Auto Scaling Group had healthy EC2 instances.
2. Manually stopped one running EC2 instance to simulate an infrastructure failure.
3. Observed the Auto Scaling Group's response through the AWS Console.
4. Verified that the Auto Scaling Group automatically launched a replacement EC2 instance.
5. Confirmed that the Application Load Balancer continued serving application traffic through a remaining healthy instance.

### Observed Results

| Validation | Result |
|---|---|
| EC2 instance stopped | Confirmed |
| Auto Scaling detected instance failure | Confirmed through replacement behavior |
| Replacement EC2 instance launched | Passed |
| Manual intervention required | No |
| ALB continued serving application traffic | Passed |

### Outcome
The failure test demonstrated that the Auto Scaling Group could automatically restore instance capacity while the Application Load Balancer maintained application availability through a healthy backend instance.

**Scope:** This was a controlled failure test in a personal AWS lab environment, not a production availability test.
