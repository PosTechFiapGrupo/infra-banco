# Random password for master user
resource "random_password" "db_master_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql-${var.environment}"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # Database configuration
  db_name  = var.db_name
  username = "admin"
  password = random_password.db_master_password.result

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  # No public access
  port                   = 3306

  # Backup configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window          = "03:00-04:00"  # UTC time
  copy_tags_to_snapshot  = true

  # Maintenance configuration
  maintenance_window         = "mon:04:00-mon:05:00"  # UTC time
  auto_minor_version_upgrade = true
  allow_major_version_upgrade = false

  # High Availability
  multi_az = true  # Enable multi-AZ for HA

  # Performance Insights (muitos tipos/configs não suportam; em dev pode desligar)
  performance_insights_enabled = var.environment == "prod" ? var.enable_performance_insights : false

  # só setar retention quando PI estiver ligado (evita combinações ruins)
  performance_insights_retention_period = (
    var.environment == "prod" && var.enable_performance_insights
  ) ? 7 : null



  # Monitoring
  monitoring_interval = var.enable_monitoring ? 60 : 0
  monitoring_role_arn = var.enable_monitoring ? aws_iam_role.rds_enhanced_monitoring.arn : null

  enabled_cloudwatch_logs_exports = [
    "error",
    "general",
    "slowquery"
  ]


  # Parameter group
  parameter_group_name = aws_db_parameter_group.mysql.name

  # Deletion protection (set to false for dev, true for prod)
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment != "prod"

  # Final snapshot name (only if deletion_protection is false)
  final_snapshot_identifier = var.environment != "prod" ? "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  tags = {
    Name        = "${var.project_name}-mysql-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds,
    aws_db_parameter_group.mysql
  ]
}

# Store master credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_master_credentials" {
  name        = "${var.project_name}/rds/mysql/master-credentials"
  description = "Master database credentials for RDS MySQL"

  tags = {
    Name        = "${var.project_name}-db-master-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_master_credentials" {
  secret_id = aws_secretsmanager_secret.db_master_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.mysql.username
    password = random_password.db_master_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })
}

