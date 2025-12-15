# RDS MySQL Database Module

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.environment}-mysql-params"
  family = "mysql${var.engine_version}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-mysql-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier     = var.db_identifier
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.enable_encryption
  kms_key_id            = var.enable_encryption ? var.kms_key_arn : null

  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.database_port

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability
  multi_az               = var.multi_az
  availability_zone      = var.multi_az ? null : var.availability_zone

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot     = true

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled && var.enable_encryption ? var.kms_key_arn : null

  # Other
  parameter_group_name        = aws_db_parameter_group.main.name
  apply_immediately           = var.apply_immediately
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  deletion_protection         = var.deletion_protection

  tags = merge(
    var.tags,
    {
      Name = var.db_identifier
    }
  )

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }

  depends_on = [
    aws_security_group.rds
  ]
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
