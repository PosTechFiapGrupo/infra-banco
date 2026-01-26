# =============================================================================
# Random password for master user
# =============================================================================

resource "random_password" "db_master_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# =============================================================================
# RDS MySQL Instance
# =============================================================================

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql-${var.environment}"

  # Engine
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # Database
  db_name  = var.db_name
  username = "admin"
  password = random_password.db_master_password.result

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 3306

  # Backup
  backup_retention_period = var.db_backup_retention_period
  backup_window           = "03:00-04:00"
  copy_tags_to_snapshot   = true

  # Maintenance
  maintenance_window          = "mon:04:00-mon:05:00"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  # High Availability
  multi_az = true

  # Performance Insights
  performance_insights_enabled = var.environment == "prod" ? var.enable_performance_insights : false
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

  # =============================================================================
  # DESTROY-SAFE CONTROLS
  # =============================================================================

  # Aplica imediatamente quando o objetivo é desligar proteção / pular snapshot
  apply_immediately = (
    var.force_disable_deletion_protection || var.force_skip_final_snapshot
  )

  # Deletion protection (prod por padrão; pode forçar desligar)
  deletion_protection = (
    var.environment == "prod" && !var.force_disable_deletion_protection
  )

  # Pular snapshot fora de prod OU quando forçado
  skip_final_snapshot = (
    var.environment != "prod" || var.force_skip_final_snapshot
  )

  # Só define nome do snapshot quando REALMENTE vai criar snapshot final
  final_snapshot_identifier = (
    var.environment == "prod" && !var.force_skip_final_snapshot
    ? coalesce(
        var.final_snapshot_identifier,
        "${var.project_name}-final-${formatdate("YYYYMMDD-hhmm", timestamp())}"
      )
    : null
  )

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

# =============================================================================
# Secrets Manager - Master credentials
# =============================================================================

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
