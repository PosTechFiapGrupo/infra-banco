# AWS Configuration
aws_region = "us-east-1"
environment = "staging"
project_name = "tech-challenge"

# VPC Configuration
vpc_cidr = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Database Configuration
db_instance_class = "db.t3.small"
db_allocated_storage = 50
db_max_allocated_storage = 200
db_backup_retention_period = 14
db_name = "tech_challenge"

# Monitoring Configuration
enable_monitoring = true
enable_performance_insights = true
alert_email = ""  # Set to email address for staging alerts

# Security Configuration
# Provide at least one of these for RDS access:
# Option 1: Allow access from specific security groups (recommended)
allowed_security_group_ids = []
# Example: allowed_security_group_ids = ["sg-12345678"]

# Option 2: Allow access from CIDR blocks
allowed_cidr_blocks = []
# Example: allowed_cidr_blocks = ["10.1.0.0/16"]

