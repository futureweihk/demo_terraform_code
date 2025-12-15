output "security_group_id" {
  value       = aws_security_group.endpoints.id
  description = "Security group ID for VPC endpoints"
}

output "s3_endpoint_id" {
  value       = try(aws_vpc_endpoint.s3[0].id, null)
  description = "S3 VPC endpoint ID"
}

output "secrets_manager_endpoint_id" {
  value       = try(aws_vpc_endpoint.secrets_manager[0].id, null)
  description = "Secrets Manager VPC endpoint ID"
}

output "ecr_api_endpoint_id" {
  value       = try(aws_vpc_endpoint.ecr_api[0].id, null)
  description = "ECR API VPC endpoint ID"
}

output "ecr_dkr_endpoint_id" {
  value       = try(aws_vpc_endpoint.ecr_dkr[0].id, null)
  description = "ECR DKR VPC endpoint ID"
}

output "rds_endpoint_id" {
  value       = try(aws_vpc_endpoint.rds[0].id, null)
  description = "RDS VPC endpoint ID"
}

output "endpoint_dns_entries" {
  value = {
    secrets_manager = try(aws_vpc_endpoint.secrets_manager[0].dns_entry, [])
    ecr_api         = try(aws_vpc_endpoint.ecr_api[0].dns_entry, [])
    ecr_dkr         = try(aws_vpc_endpoint.ecr_dkr[0].dns_entry, [])
    rds             = try(aws_vpc_endpoint.rds[0].dns_entry, [])
  }
  description = "DNS entries for interface endpoints"
}
