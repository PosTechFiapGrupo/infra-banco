# Infrastructure - Database (RDS MySQL)

This repository contains Terraform code for provisioning AWS RDS MySQL database infrastructure.

## Resources Provisioned

- **VPC** with public and private subnets
- **RDS MySQL 8.0** instance with Multi-AZ support
- **DB Parameter Group** for MySQL performance tuning
- **DB Subnet Group** for RDS placement
- **Security Groups** for RDS access control
- **Secrets Manager** secrets for database credentials:
  - Master credentials
  - App user credentials
  - Migration user credentials
  - Admin user credentials
- **IAM Policies** for secret access
- **CloudWatch Alarms** for monitoring:
  - CPU utilization
  - Database connections
  - Read/Write latency
  - Free storage space
  - Freeable memory
  - Read/Write IOPS
- **SNS Topic** for alerting (optional, prod only)

## Prerequisites

- Terraform >= 1.13.0
- AWS CLI configured with appropriate credentials
- S3 bucket for remote state storage
- DynamoDB table for state locking

## Usage

### 1. Configure Backend

Edit `backend.tf` to configure your remote state backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "infra-db/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 2. Configure Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and update values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Changes

```bash
terraform plan
```

### 5. Apply Infrastructure

```bash
terraform apply
```

### 6. Review Outputs

After applying, view outputs:

```bash
terraform output
```

## Configuration

### Required Variables

- `aws_region` - AWS region for resources
- `environment` - Environment name (dev, staging, prod)
- `project_name` - Project name for resource naming

### Database Configuration

- `db_instance_class` - RDS instance class (default: `db.t3.micro`)
- `db_allocated_storage` - Initial storage in GB (default: 20)
- `db_max_allocated_storage` - Max storage for autoscaling (default: 100)
- `db_backup_retention_period` - Backup retention in days (default: 7)
- `db_name` - Database name (default: `tech_challenge`)

### Security Configuration

- `allowed_security_group_ids` - List of security group IDs allowed to access RDS
- `allowed_cidr_blocks` - List of CIDR blocks allowed to access RDS

**Note**: At least one of `allowed_security_group_ids` or `allowed_cidr_blocks` should be provided for RDS access.

### Monitoring Configuration

- `enable_monitoring` - Enable enhanced monitoring (default: `true`)
- `enable_performance_insights` - Enable Performance Insights (default: `true`)
- `alert_email` - Email for CloudWatch alerts (optional, prod only)

## Outputs

This module outputs the following values that can be referenced by other infrastructure repos:

- `rds_endpoint` - RDS MySQL endpoint
- `rds_port` - RDS MySQL port (3306)
- `rds_database_name` - Database name
- `rds_instance_id` - RDS instance identifier
- `rds_security_group_id` - RDS security group ID
- `rds_master_secret_arn` - ARN of master credentials secret
- `rds_app_secret_arn` - ARN of app user credentials secret
- `rds_migration_secret_arn` - ARN of migration user credentials secret
- `rds_admin_secret_arn` - ARN of admin user credentials secret
- `vpc_id` - VPC ID
- `private_subnet_ids` - Private subnet IDs
- `public_subnet_ids` - Public subnet IDs
- `app_secrets_read_policy_arn` - IAM policy ARN for app secret access
- `migration_secrets_read_policy_arn` - IAM policy ARN for migration secret access

## Integration with Other Repos

### Referencing from infra-k8s

```hcl
# In infra-k8s/terraform/main.tf
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "infra-db/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use outputs
locals {
  db_endpoint = data.terraform_remote_state.db.outputs.rds_endpoint
  db_port     = data.terraform_remote_state.db.outputs.rds_port
  db_secret_arn = data.terraform_remote_state.db.outputs.rds_app_secret_arn
}

# Allow app security group to access RDS
resource "aws_security_group_rule" "app_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = data.terraform_remote_state.db.outputs.rds_security_group_id
}
```

## Database User Setup

After provisioning, execute the SQL scripts in `db-scripts/` to create database users:

1. Connect to RDS using master credentials from Secrets Manager
2. Execute scripts in order:
   - `app_user.sql`
   - `migration_user.sql`
   - `admin_user.sql`

**Important**: Replace `CHANGE_ME_IN_SECRETS_MANAGER` with actual passwords from Secrets Manager.

## Security Notes

1. **Passwords**: All passwords are generated by Terraform and stored in Secrets Manager
2. **Access Control**: RDS security group only allows access from specified security groups or CIDR blocks
3. **Encryption**: RDS storage is encrypted at rest
4. **Network**: RDS is deployed in private subnets with no public access
5. **Monitoring**: CloudWatch alarms configured for key metrics
6. **Backups**: Automated backups enabled with configurable retention

## Maintenance

### Updating RDS Instance

To change instance class or storage:

1. Update variables in `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

**Note**: Some changes (like instance class) may cause downtime.

### Rotating Passwords

Passwords are stored in Secrets Manager. To rotate:

1. Update password in Secrets Manager
2. Update database user password using SQL
3. Update application configuration to use new password

## Troubleshooting

### Cannot Connect to RDS

1. Verify security group rules allow access from your IP/security group
2. Check VPC and subnet configuration
3. Verify RDS instance is in `available` state
4. Check CloudWatch logs for connection errors

### High CPU/Memory Usage

1. Review CloudWatch metrics
2. Check slow query log
3. Consider upgrading instance class
4. Review application query patterns

## Cost Optimization

- Use `db.t3.micro` for development
- Enable storage autoscaling to avoid over-provisioning
- Set appropriate backup retention periods
- Use Multi-AZ only for production environments
- Monitor unused resources and clean up

## Support

For issues or questions, please refer to:
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

