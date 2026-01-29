# CloudWatch Alarms for RDS MySQL

locals {
  # Cria alarmes somente quando o monitoramento estiver habilitado
  create_rds_alarms = var.enable_monitoring
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-cpu-utilization-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-cpu-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-database-connections-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80 # OBS: isso é 80 conexões (não 80% do max_connections)
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-connections-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Read Latency Alarm
resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-read-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.5 # 500ms
  alarm_description   = "This metric monitors RDS read latency"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-read-latency-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Write Latency Alarm
resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-write-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.5 # 500ms
  alarm_description   = "This metric monitors RDS write latency"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-write-latency-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-free-storage-space-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000 # 5 GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-storage-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Freeable Memory Alarm
resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-freeable-memory-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100000000 # 100 MB in bytes
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-memory-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Read IOPS Alarm
resource "aws_cloudwatch_metric_alarm" "rds_read_iops" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-read-iops-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000 # Ajuste conforme sua instância/workload
  alarm_description   = "This metric monitors RDS read IOPS"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-read-iops-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Write IOPS Alarm
resource "aws_cloudwatch_metric_alarm" "rds_write_iops" {
  count = local.create_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-write-iops-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteIOPS"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000 # Ajuste conforme sua instância/workload
  alarm_description   = "This metric monitors RDS write IOPS"
  alarm_actions       = var.environment == "prod" && var.alert_email != "" ? [aws_sns_topic.rds_alerts[0].arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-write-iops-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SNS Topic for RDS Alerts (optional, only created if email is provided)
resource "aws_sns_topic" "rds_alerts" {
  count = var.environment == "prod" && var.alert_email != "" ? 1 : 0
  name  = "${var.project_name}-rds-alerts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-rds-alerts"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "rds_alerts_email" {
  count     = var.environment == "prod" && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.rds_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}
