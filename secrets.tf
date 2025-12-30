# Random password for app user
resource "random_password" "db_app_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Random password for migration user
resource "random_password" "db_migration_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Random password for admin user
resource "random_password" "db_admin_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secret for app user credentials
resource "aws_secretsmanager_secret" "db_app_credentials" {
  name        = "${var.project_name}/rds/mysql/app-credentials"
  description = "Application database user credentials for RDS MySQL"

  tags = {
    Name        = "${var.project_name}-db-app-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_app_credentials" {
  secret_id = aws_secretsmanager_secret.db_app_credentials.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db_app_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })

  depends_on = [aws_db_instance.mysql]
}

# Secret for migration user credentials
resource "aws_secretsmanager_secret" "db_migration_credentials" {
  name        = "${var.project_name}/rds/mysql/migration-credentials"
  description = "Migration database user credentials for RDS MySQL"

  tags = {
    Name        = "${var.project_name}-db-migration-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_migration_credentials" {
  secret_id = aws_secretsmanager_secret.db_migration_credentials.id
  secret_string = jsonencode({
    username = "migration_user"
    password = random_password.db_migration_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })

  depends_on = [aws_db_instance.mysql]
}

# Secret for admin user credentials (restricted access)
resource "aws_secretsmanager_secret" "db_admin_credentials" {
  name        = "${var.project_name}/rds/mysql/admin-credentials"
  description = "Admin database user credentials for RDS MySQL (restricted access)"

  tags = {
    Name        = "${var.project_name}-db-admin-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_admin_credentials" {
  secret_id = aws_secretsmanager_secret.db_admin_credentials.id
  secret_string = jsonencode({
    username = "admin_user"
    password = random_password.db_admin_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })

  depends_on = [aws_db_instance.mysql]
}

# IAM policy for app to read secrets
resource "aws_iam_policy" "app_secrets_read" {
  name        = "${var.project_name}-app-secrets-read"
  description = "Policy for application to read database secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_app_credentials.arn,
          aws_secretsmanager_secret.db_master_credentials.arn
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-app-secrets-read"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for migration user to read migration secrets
resource "aws_iam_policy" "migration_secrets_read" {
  name        = "${var.project_name}-migration-secrets-read"
  description = "Policy for migration jobs to read database secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_migration_credentials.arn,
          aws_secretsmanager_secret.db_master_credentials.arn
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-migration-secrets-read"
    Environment = var.environment
    Project     = var.project_name
  }
}

