# AWS Configuration
aws_region = "us-east-1"
environment = "dev"
project_name = "tech-challenge"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Database Configuration
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_max_allocated_storage = 100
db_backup_retention_period = 7
db_name = "tech_challenge"

# Monitoring Configuration
enable_monitoring = true
enable_performance_insights = true
alert_email = ""  # Optional for dev

# Security Configuration
# Provide at least one of these for RDS access:
# Option 1: Allow access from specific security groups (recommended)
allowed_security_group_ids = []
# Example: allowed_security_group_ids = ["sg-12345678"]

# Option 2: Allow access from CIDR blocks
allowed_cidr_blocks = []
# Example: allowed_cidr_blocks = ["10.0.0.0/16"]

