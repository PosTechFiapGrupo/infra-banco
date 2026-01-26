# =============================================================================
# Network - RDS (Security Group + Subnet Group)
# =============================================================================

# Security Group for RDS (na VPC vinda do remote state)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS MySQL instance"
  vpc_id      = local.vpc_id


  # Allow ingress from specific security groups (passed as variable)
  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "MySQL from allowed security group"
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # Or allow from CIDR blocks (for flexibility)
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      description = "MySQL from CIDR block"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# DB Subnet Group for RDS (subnets privadas vindas do remote state)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = local.private_subnet_ids


  tags = {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
