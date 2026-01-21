# RDS Parameter Group for MySQL Performance Tuning
resource "aws_db_parameter_group" "mysql" {
  name   = "${var.project_name}-mysql-params"
  family = "mysql8.0"

  # Connection settings
  parameter {
    name  = "max_connections"
    value = "100"  # Adjust based on instance size (db.t3.micro supports up to 87)
  }

  # InnoDB settings (for db.t3.micro with 1GB RAM)
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"  # 75% of RAM
  }

  parameter {
    name  = "innodb_log_file_size"
    value = "134217728"   # 128 MB em bytes
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "innodb_flush_log_at_trx_commit"
    value = "2"  # Better performance, safe for RDS with backups
  }

  # Query cache (disabled in MySQL 8.0, but keeping for reference)
  # MySQL 8.0 removed query cache, so no parameters needed

  # Logging settings for monitoring
  parameter {
    name  = "general_log"
    value = "0"  # Disable general log (use slow query log instead)
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "1"  # Log queries taking longer than 1 second
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = "1"
  }

  tags = {
    Name        = "${var.project_name}-mysql-params"
    Environment = var.environment
    Project     = var.project_name
  }
}

