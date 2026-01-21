data "aws_iam_policy_document" "rds_monitoring_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${var.project_name}-rds-enhanced-monitoring-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_attach" {
  role      = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
