# RDS MySQL Outputs
output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "rds_database_name" {
  description = "RDS MySQL database name"
  value       = aws_db_instance.mysql.db_name
}

output "rds_instance_id" {
  description = "RDS MySQL instance identifier"
  value       = aws_db_instance.mysql.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "rds_master_secret_arn" {
  description = "ARN of master credentials secret"
  value       = aws_secretsmanager_secret.db_master_credentials.arn
}

output "rds_app_secret_arn" {
  description = "ARN of app user credentials secret"
  value       = aws_secretsmanager_secret.db_app_credentials.arn
}

output "rds_migration_secret_arn" {
  description = "ARN of migration user credentials secret"
  value       = aws_secretsmanager_secret.db_migration_credentials.arn
}

output "rds_admin_secret_arn" {
  description = "ARN of admin user credentials secret"
  value       = aws_secretsmanager_secret.db_admin_credentials.arn
}


output "app_secrets_read_policy_arn" {
  description = "ARN of IAM policy for app to read secrets"
  value       = aws_iam_policy.app_secrets_read.arn
}

output "migration_secrets_read_policy_arn" {
  description = "ARN of IAM policy for migration jobs to read secrets"
  value       = aws_iam_policy.migration_secrets_read.arn
}

