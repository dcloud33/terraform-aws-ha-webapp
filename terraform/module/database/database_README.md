# Database Module

## Overview

This module creates the database layer for the Terraform AWS High-Availability Web App.

The database should be deployed in private subnets and should not be publicly accessible. Application EC2 instances connect to the database through a database security group.

## What This Module Builds

This module may create:

- DB subnet group
- RDS database instance
- Database security group association
- Database parameter configuration
- Database tags

Depending on your design, this module may also be expanded later to support:

- Multi-AZ RDS
- Aurora cluster
- Read replicas
- Automated backups
- Secrets Manager integration

## Architecture Role

The database sits in private subnets and only allows inbound traffic from the application layer.

```text
EC2 instances
  ↓
Database Security Group
  ↓
RDS database in private subnets
```

## Example Usage

```hcl
module "database" {
  source = "../../modules/database"

  project_name         = "ha-web-app"
  environment          = "dev"
  private_subnet_ids    = module.network.private_subnet_ids
  db_security_group_id  = module.security_groups.db_security_group_id

  db_name     = "appdb"
  db_username = var.db_username
  db_password = var.db_password

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  multi_az          = false
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---:|---|
| project_name | string | yes | Project name used for resource naming |
| environment | string | yes | Environment name such as `dev`, `stage`, or `prod` |
| private_subnet_ids | list(string) | yes | Private subnet IDs used for the DB subnet group |
| db_security_group_id | string | yes | Security group ID attached to the database |
| db_name | string | yes | Name of the application database |
| db_username | string | yes | Master database username |
| db_password | string | yes | Master database password |
| engine | string | no | Database engine such as `mysql` or `postgres` |
| engine_version | string | no | Database engine version |
| instance_class | string | no | RDS instance class |
| allocated_storage | number | no | Storage size in GB |
| multi_az | bool | no | Whether to enable Multi-AZ deployment |
| tags | map(string) | no | Additional tags applied to resources |

## Outputs

| Name | Description |
|---|---|
| db_instance_id | ID of the database instance |
| db_endpoint | Database endpoint |
| db_port | Database port |
| db_name | Name of the created database |
| db_subnet_group_name | Name of the DB subnet group |

## Security Notes

- The database should be deployed in private subnets.
- The database should not be publicly accessible.
- The database security group should only allow inbound traffic from the EC2 application security group.
- Database passwords should not be hardcoded in Terraform files.
- Sensitive values should be passed through variables, environment variables, AWS Secrets Manager, or SSM Parameter Store.

## Common Issues

### Application Cannot Connect to Database

Possible causes:

- Database security group does not allow traffic from EC2 security group
- Wrong database endpoint
- Wrong database port
- Database is still creating
- Private subnet routing or DNS settings are incorrect
- Incorrect username or password

### Terraform Fails Creating RDS

Possible causes:

- DB subnet group has invalid subnet IDs
- Subnets are not in enough Availability Zones for Multi-AZ
- Invalid engine version
- Invalid instance class
- Password does not meet RDS requirements

### Database Is Publicly Accessible

Possible causes:

- Public accessibility is enabled
- Database was placed in public subnets
- Security group allows inbound traffic from `0.0.0.0/0`

## Validation

Check database status:

```bash
aws rds describe-db-instances \
  --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]" \
  --output table
```

Expected result:

```text
Database status should be available
```

Test connectivity from an EC2 instance in the private subnet:

```bash
mysql -h <db_endpoint> -u <db_username> -p
```

Expected result:

```text
Successful database connection
```
