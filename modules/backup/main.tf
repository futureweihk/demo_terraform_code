# AWS Backup Module

# Backup Vault
resource "aws_backup_vault" "main" {
  name        = var.backup_vault_name
  kms_key_arn = var.kms_key_arn

  tags = var.tags
}

# Backup Plan
resource "aws_backup_plan" "main" {
  name = "${var.environment}-backup-plan"

  # Daily Backup Rule (for PROD only)
  dynamic "rule" {
    for_each = var.enable_daily_backup ? [1] : []
    content {
      rule_name         = "daily-backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM UTC

      lifecycle {
        delete_after = var.daily_retention_days
      }

      recovery_point_tags = merge(
        var.tags,
        {
          BackupType = "Daily"
        }
      )
    }
  }

  # Monthly Backup Rule (for PROD only)
  dynamic "rule" {
    for_each = var.enable_monthly_backup ? [1] : []
    content {
      rule_name         = "monthly-backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 3 1 * ? *)" # Monthly on 1st at 3 AM UTC

      lifecycle {
        delete_after = var.monthly_retention_days
      }

      recovery_point_tags = merge(
        var.tags,
        {
          BackupType = "Monthly"
        }
      )
    }
  }

  tags = var.tags
}

# Backup Selection
resource "aws_backup_selection" "main" {
  name         = "${var.environment}-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = var.backup_resource_arns

  # Selection by tags (optional)
  dynamic "selection_tag" {
    for_each = var.backup_tag_key != null ? [1] : []
    content {
      type  = "STRINGEQUALS"
      key   = var.backup_tag_key
      value = var.backup_tag_value
    }
  }
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup" {
  name = var.backup_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AWS Backup service role policy
resource "aws_iam_role_policy_attachment" "backup_service" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Attach restore policy
resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}
