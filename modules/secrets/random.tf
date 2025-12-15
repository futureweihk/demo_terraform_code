# Generate random password for RDS
resource "random_password" "rds_master" {
  length           = var.password_length
  special          = var.password_special_chars
  override_special = var.password_override_special
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Generate random suffix for secret name
resource "random_id" "secret_suffix" {
  byte_length = 16
}
