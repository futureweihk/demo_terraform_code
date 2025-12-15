# RDS Master Credentials Secret
resource "aws_secretsmanager_secret" "rds_master" {
  name_prefix             = "${var.environment}-${var.secret_name_prefix}-master-"
  description             = "RDS master credentials for ${var.environment} environment"
  recovery_window_in_days = var.recovery_window_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-rds-master-secret"
      Environment = var.environment
      Purpose     = "RDS Master Credentials"
    }
  )
}

# Store RDS credentials in Secrets Manager
resource "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = aws_secretsmanager_secret.rds_master.id
  
  secret_string = jsonencode({
    username = var.rds_master_username
    password = random_password.rds_master.result
  })

  # IGNORE CHANGES:
  # This is crucial. If rotation is enabled, AWS updates the secret value externally.
  # We tell Terraform to ignore changes to the string so it doesn't overwrite
  # the rotated password with the original random generated one.
  lifecycle {
    ignore_changes = [secret_string]
  }
}
