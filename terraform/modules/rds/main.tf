data "aws_caller_identity" "current" {}

# Customer-managed key for storage and Performance Insights (CKV_AWS_354)
resource "aws_kms_key" "db" {
  description             = "${var.name} RDS storage and Performance Insights"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AccountAdministration"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
  tags = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "PostgreSQL access for ${var.name}" # CKV_AWS_23
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from application nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }
  tags = var.tags
}

# Query logging (CKV2_AWS_30) and TLS-only connections
resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-pg16"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "ddl"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  # Encryption in transit: reject non-TLS connections
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  tags = var.tags
}

# Enhanced monitoring (CKV_AWS_118)
resource "aws_iam_role" "monitoring" {
  name = "${var.name}-rds-monitoring"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "monitoring.rds.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  # checkov:skip=CKV_AWS_157:Multi-AZ is set per environment (prod = true). Dev and staging run single-AZ to control cost.
  identifier                          = var.name
  engine                              = "postgres"
  engine_version                      = "16"
  instance_class                      = var.instance_class
  allocated_storage                   = var.storage_gb
  db_name                             = var.db_name
  username                            = "app_admin"
  manage_master_user_password         = true
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.db.id]
  parameter_group_name                = aws_db_parameter_group.this.name
  multi_az                            = var.multi_az
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.db.arn
  iam_database_authentication_enabled = true
  backup_retention_period             = var.backup_days
  deletion_protection                 = true # CKV_AWS_293: always on; disable deliberately before a planned teardown
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${var.name}-final"
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = aws_kms_key.db.arn
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.monitoring.arn
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  tags                                = var.tags

  depends_on = [aws_iam_role_policy_attachment.monitoring]
}

variable "name" { type = string }
variable "db_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "storage_gb" {
  type    = number
  default = 20
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "backup_days" {
  type    = number
  default = 7
}
variable "tags" {
  type    = map(string)
  default = {}
}
output "endpoint" { value = aws_db_instance.this.endpoint }
