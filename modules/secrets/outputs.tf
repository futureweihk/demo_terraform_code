# Secrets Module Outputs

output "secret_arn" {
  description = "ARN of the RDS master credentials secret"
  value       = aws_secretsmanager_secret.rds_master.arn
  sensitive   = true
}

output "secret_name" {
  description = "Name of the RDS master credentials secret"
  value       = aws_secretsmanager_secret.rds_master.name
}

output "secret_id" {
  description = "ID of the RDS master credentials secret"
  value       = aws_secretsmanager_secret.rds_master.id
}

output "rds_password" {
  description = "Generated RDS master password"
  value       = random_password.rds_master.result
  sensitive   = true
}

output "rds_username" {
  description = "RDS master username"
  value       = var.rds_master_username
}
