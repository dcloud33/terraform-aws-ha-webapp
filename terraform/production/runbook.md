# Runbook: Terraform AWS High-Availability Web App

## 1. Purpose

This runbook provides step-by-step instructions to deploy, validate, troubleshoot, roll back, and destroy the Terraform AWS High-Availability Web App infrastructure.

The infrastructure may include:

- VPC
- Public subnets
- Private subnets
- Internet Gateway
- NAT Gateway
- Application Load Balancer
- Target Group
- Auto Scaling Group
- EC2 instances
- Security groups

The goal of this runbook is to give another engineer a clear checklist to operate the environment without guessing.

---

## 2. When to Use This Runbook

Use this runbook when:

- Deploying the infrastructure for the first time
- Updating Terraform modules
- Validating application availability
- Troubleshooting networking, ALB, ASG, or EC2 issues
- Rolling back failed Terraform changes
- Destroying a lab or development environment

---

## 3. Prerequisites

Before using this runbook, verify the following:

- Terraform is installed
- AWS CLI is installed
- AWS credentials are configured
- You are using the correct AWS account
- You are in the correct Terraform environment folder

### Verify Terraform

```bash
terraform version
```

Expected result:

```text
Terraform returns the installed version.
```

### Verify AWS CLI

```bash
aws --version
```

Expected result:

```text
AWS CLI returns the installed version.
```

### Verify AWS Identity

```bash
aws sts get-caller-identity
```

Expected result:

```text
The AWS account ID should match the expected lab or project account.
```

Do not continue if the AWS account ID is not the expected account.

---

## 4. Important Project Paths

| Path | Purpose |
|---|---|
| `environments/dev/` | Dev root Terraform environment |
| `modules/network/` | VPC, subnets, route tables, Internet Gateway, NAT Gateway |
| `modules/security_groups/` | ALB and EC2 security groups |
| `modules/alb/` | Application Load Balancer, listener, and target group |
| `modules/compute_asg/` | Launch template and Auto Scaling Group |
| `runbook.md` | Operations and troubleshooting guide |
| `architecture.md` | Architecture explanation |
| `diagrams/` | Architecture diagrams |

---

## 5. Deployment Procedure

### Step 1: Enter the environment folder

```bash
cd environments/dev
```

Expected result:

```text
You are now inside the Terraform root module for the dev environment.
```

### Step 2: Format Terraform files

```bash
terraform fmt -recursive
```

Expected result:

```text
Terraform formats all configuration files successfully.
```

### Step 3: Initialize Terraform

```bash
terraform init
```

Expected result:

```text
Terraform initializes the backend, downloads providers, and loads modules.
```

### Step 4: Validate Terraform

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

### Step 5: Review the Terraform plan

```bash
terraform plan
```

Expected result:

```text
Terraform shows the resources that will be created, changed, or destroyed.
```

Before continuing, review the plan carefully.

Do not apply if Terraform plans to destroy important resources unexpectedly.

### Step 6: Apply the configuration

```bash
terraform apply
```

Expected result:

```text
Apply complete.
```

---

## 6. Validation Procedure

After deployment, validate that the infrastructure works.

### Step 1: Check Terraform outputs

```bash
terraform output
```

Expected outputs may include:

```text
vpc_id
public_subnet_ids
private_subnet_ids
alb_dns_name
autoscaling_group_name
target_group_arn
```

### Step 2: Test the ALB endpoint

```bash
curl http://<alb_dns_name>
```

Expected result:

```text
HTTP 200 response from the web application.
```

If the ALB returns `503`, go to the troubleshooting section for ALB 503 errors.

### Step 3: Check target group health

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target_group_arn>
```

Expected result:

```text
Targets should show healthy.
```

### Step 4: Check Auto Scaling Group capacity

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <autoscaling_group_name>
```

Expected result:

```text
The desired capacity should match the expected number of EC2 instances.
```

---

## 7. Troubleshooting Procedures

## Troubleshooting: ALB Returns 503

### Symptom

The ALB DNS name loads, but the response is:

```text
503 Service Temporarily Unavailable
```

### Meaning

The ALB is reachable, but it does not have healthy backend targets.

### Checks

1. Check target group health.
2. Confirm EC2 instances are running.
3. Confirm the Auto Scaling Group registered instances with the target group.
4. Confirm the EC2 security group allows traffic from the ALB security group.
5. Confirm the web server is installed and running.
6. Confirm the target group health check path is correct.

### Commands

Check running EC2 instances:

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]" \
  --output table
```

Check target group health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target_group_arn>
```

### Expected Result

```text
Targets should show healthy.
```

### Common Fixes

- Fix EC2 security group rules.
- Fix the target group health check path.
- Fix the EC2 user data script.
- Start Apache or Nginx on the EC2 instances.
- Confirm the Auto Scaling Group is attached to the correct target group.

---

## Troubleshooting: EC2 Targets Are Unhealthy

### Symptom

The ALB target group shows EC2 instances as unhealthy.

### Meaning

The ALB cannot successfully reach the application running on the EC2 instances.

### Checks

1. Is the EC2 instance running?
2. Is the web server installed?
3. Is the web server running?
4. Is the application listening on the correct port?
5. Does the EC2 security group allow traffic from the ALB security group?
6. Is the target group health check path correct?

### Commands

Check EC2 instance state:

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --output table
```

If you can use SSH or AWS Systems Manager Session Manager, check web server status.

For Apache:

```bash
sudo systemctl status httpd
```

For Nginx:

```bash
sudo systemctl status nginx
```

### Common Fixes

- Update the user data script.
- Start the web server.
- Open the correct EC2 security group rule.
- Change the health check path to `/`.
- Confirm the application is listening on the expected port.

---

## Troubleshooting: Private EC2 Cannot Reach the Internet

### Symptom

EC2 instances in private subnets cannot install packages or reach public repositories.

Example failures:

```text
yum install fails
dnf install fails
curl google.com fails
```

### Meaning

The private subnet probably does not have working outbound internet access.

### Checks

1. Confirm NAT Gateway exists.
2. Confirm NAT Gateway is in a public subnet.
3. Confirm NAT Gateway has an Elastic IP.
4. Confirm the public subnet route table routes `0.0.0.0/0` to the Internet Gateway.
5. Confirm the private subnet route table routes `0.0.0.0/0` to the NAT Gateway.
6. Confirm the EC2 security group allows outbound traffic.

### Expected Routing

Public route table:

```text
0.0.0.0/0 -> Internet Gateway
```

Private route table:

```text
0.0.0.0/0 -> NAT Gateway
```

### Common Fixes

- Move NAT Gateway to a public subnet.
- Add a route from the private route table to the NAT Gateway.
- Add a route from the public route table to the Internet Gateway.
- Confirm the NAT Gateway Elastic IP exists.
- Confirm the NAT Gateway status is available.

---

## Troubleshooting: Terraform Cannot Find Module

### Symptom

Terraform returns an error like:

```text
Unreadable module directory
Module not found
Unable to evaluate directory symlink
```

### Meaning

The `source` path in the module block is probably wrong.

### Checks

Confirm where you are running Terraform from.

Example root folder:

```text
environments/dev/
```

If your modules folder is here:

```text
modules/network/
```

Then your module source should usually be:

```hcl
source = "../../modules/network"
```

### Common Fix

Update the module path:

```hcl
module "network" {
  source = "../../modules/network"
}
```

Then run:

```bash
terraform init
```

---

## Troubleshooting: Missing Required Variable

### Symptom

Terraform returns an error like:

```text
The argument "vpc_cidr" is required, but no definition was found.
```

### Meaning

The module expects an input variable, but the root module did not pass a value and the variable has no default.

### Check

Open the module's `variables.tf` file.

Example:

```hcl
variable "vpc_cidr" {
  type = string
}
```

This variable is required because it has no default.

### Fix Option 1: Pass the variable from the root module

```hcl
module "network" {
  source = "../../modules/network"

  vpc_cidr = "10.98.0.0/16"
}
```

### Fix Option 2: Add a default inside the module

```hcl
variable "vpc_cidr" {
  type    = string
  default = "10.98.0.0/16"
}
```

### Recommended Practice

For reusable modules, pass important environment-specific values from the root environment instead of hiding too many defaults inside the module.

---

## Troubleshooting: Terraform Plan Wants to Destroy Unexpected Resources

### Symptom

`terraform plan` shows resources will be destroyed, but you did not expect destruction.

### Meaning

Terraform detected a configuration change that requires resource replacement or deletion.

### Checks

1. Review recent code changes.
2. Check if resource names changed.
3. Check if module paths changed.
4. Check if Terraform state was modified.
5. Check if a resource was manually changed or deleted in AWS.

### Commands

Review recent Git changes:

```bash
git diff
```

List Terraform state resources:

```bash
terraform state list
```

### Common Fixes

- Revert accidental Terraform code changes.
- Restore the correct module source path.
- Avoid renaming Terraform resources unless you plan to move state.
- Use `terraform state mv` only when you understand exactly what resource address is changing.

---

## 8. Rollback Procedure

Rollback means returning the infrastructure to a previous working Terraform configuration.

### Step 1: Review recent changes

```bash
git log --oneline
```

### Step 2: Revert to a previous commit

```bash
git checkout <previous_commit>
```

### Step 3: Review Terraform plan

```bash
terraform plan
```

Expected result:

```text
Terraform shows the changes needed to return to the previous configuration.
```

### Step 4: Apply rollback

```bash
terraform apply
```

Expected result:

```text
Terraform applies the previous working configuration.
```

### Important Warning

Do not apply a rollback if Terraform plans to destroy important resources unexpectedly.

Review carefully before applying changes to production or shared infrastructure.

---

## 9. Destroy Procedure

Use this procedure only for lab, development, or temporary environments.

### Step 1: Enter the environment folder

```bash
cd environments/dev
```

### Step 2: Review resources in state

```bash
terraform state list
```

### Step 3: Destroy infrastructure

```bash
terraform destroy
```

Expected result:

```text
Destroy complete.
```

### Step 4: Confirm cleanup in AWS

After destroy, confirm the following resources are removed:

- EC2 instances
- Auto Scaling Groups
- Launch templates
- Application Load Balancers
- Target groups
- NAT Gateways
- Elastic IPs
- Route tables
- Subnets
- VPC
- Security groups

### Cost Reminder

Pay close attention to NAT Gateways, Elastic IPs, and Load Balancers because they can continue creating costs if they are left behind.

---

## 10. Escalation Notes

Stop and review before applying Terraform if:

- Terraform wants to destroy the VPC unexpectedly
- Terraform wants to destroy a database
- Terraform wants to replace the ALB unexpectedly
- Terraform state errors appear
- The AWS account ID does not match the expected account
- The environment is production
- You are unsure why Terraform wants to replace a resource

For a real team environment, escalate to a senior engineer, cloud engineer, or platform owner before continuing.

---

## 11. Interview Talking Point

A strong way to explain this runbook in an interview:

```text
I created a runbook for my Terraform AWS High-Availability Web App so another engineer could deploy, validate, troubleshoot, roll back, and destroy the environment without guessing.

The runbook includes Terraform commands, expected results, validation checks for the ALB and target group, and troubleshooting steps for common issues like ALB 503 errors, unhealthy EC2 targets, NAT Gateway routing problems, and module path errors.
```

---

## 12. Final Notes

A good runbook should be updated whenever the infrastructure changes.

Update this runbook when:

- A new module is added
- A Terraform command changes
- New outputs are added
- A common issue is discovered
- A new validation step is needed
- The architecture changes
