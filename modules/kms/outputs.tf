# KMS Module Outputs

output "ec2_kms_key_id" {
  description = "ID of the KMS key for EC2 EBS encryption"
  value       = aws_kms_key.ec2.id
}

output "ec2_kms_key_arn" {
  description = "ARN of the KMS key for EC2 EBS encryption"
  value       = aws_kms_key.ec2.arn
}

output "ec2_kms_key_alias" {
  description = "Alias of the KMS key for EC2"
  value       = aws_kms_alias.ec2.name
}

output "rds_kms_key_id" {
  description = "ID of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.id
}

output "rds_kms_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "rds_kms_key_alias" {
  description = "Alias of the KMS key for RDS"
  value       = aws_kms_alias.rds.name
}
