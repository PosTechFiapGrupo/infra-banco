# =============================================================================
# Security Group - RDS
# =============================================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS MySQL instance"
  vpc_id      = local.vpc_id

  # MySQL a partir dos SGs permitidos (EKS incluso automaticamente)
  dynamic "ingress" {
    for_each = local.effective_allowed_security_group_ids
    content {
      description     = "MySQL from allowed security group"
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # Opcional: acesso via CIDR
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
