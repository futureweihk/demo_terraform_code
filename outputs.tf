# Root Outputs

# VPC and Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.network.nat_gateway_ids
}

# KMS Outputs
output "ec2_kms_key_id" {
  description = "KMS key ID for EC2 encryption"
  value       = var.enable_kms_encryption ? module.kms[0].ec2_kms_key_id : null
}

output "rds_kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = var.enable_kms_encryption ? module.kms[0].rds_kms_key_id : null
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS instance address"
  value       = module.database.db_address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.database.db_name
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.database.db_instance_id
}

# Secrets Manager Outputs
output "rds_secret_arn" {
  description = "ARN of the RDS credentials secret"
  value       = module.secrets.secret_arn
  sensitive   = true
}

output "rds_secret_name" {
  description = "Name of the RDS credentials secret"
  value       = module.secrets.secret_name
}

# Compute Outputs
output "ec2_instance_ids" {
  description = "List of EC2 instance IDs"
  value       = module.compute.instance_ids
}

output "ec2_private_ips" {
  description = "List of EC2 private IP addresses"
  value       = module.compute.private_ips
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer hosted zone ID"
  value       = module.compute.alb_zone_id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = module.compute.alb_arn
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = module.compute.ec2_security_group_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.compute.alb_security_group_id
}

# Backup Outputs
output "backup_vault_name" {
  description = "AWS Backup vault name"
  value       = var.enable_aws_backup ? module.backup[0].backup_vault_name : null
}

output "backup_plan_id" {
  description = "AWS Backup plan ID"
  value       = var.enable_aws_backup ? module.backup[0].backup_plan_id : null
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment           = var.environment
    region                = var.aws_region
    availability_zones    = local.availability_zones
    vpc_id                = module.network.vpc_id
    vpc_cidr              = module.network.vpc_cidr
    public_subnets        = length(module.network.public_subnet_ids)
    private_subnets       = length(module.network.private_subnet_ids)
    nat_gateways          = length(module.network.nat_gateway_ids)
    ec2_instance_count    = var.ec2_instance_count
    ec2_instance_type     = var.instance_type
    os_type               = var.os_type
    rds_instance_class    = var.rds_instance_class
    rds_engine            = "mysql"
    rds_engine_version    = var.rds_engine_version
    rds_multi_az          = var.rds_multi_az
    rds_allocated_storage = var.rds_allocated_storage
    kms_encryption        = var.enable_kms_encryption
    vpc_flow_logs         = var.enable_vpc_flow_logs
    aws_backup_enabled    = var.enable_aws_backup
    alb_dns               = module.compute.alb_dns_name
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for accessing resources"
  value = {
    alb_url               = "http://${module.compute.alb_dns_name}"
    rds_endpoint          = module.database.db_address
    rds_port              = module.database.db_port
    rds_database          = module.database.db_name
    secret_arn            = module.secrets.secret_arn
    ec2_connect_command   = var.os_type == "linux" ? "aws ssm start-session --target <instance-id>" : "Connect via RDP to private IP through bastion"
  }
  sensitive = true
}
