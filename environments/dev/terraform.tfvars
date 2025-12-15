# Development Environment Configuration

# Environment
environment = "dev"
aws_region  = "ap-southeast-1"

# Project
project_name = "mbridge"

# Network Configuration
vpc_cidr           = "10.0.0.0/24"
az_count           = 2
enable_nat_gateway = true
single_nat_gateway = true  # Cost optimization for dev

# VPC Endpoints
enable_s3_endpoint              = true
enable_secrets_manager_endpoint = true
enable_ecr_api_endpoint         = false
enable_ecr_dkr_endpoint         = false
enable_rds_endpoint             = false

# VPC Flow Logs (Optional)
enable_vpc_flow_logs = false

# Compute Configuration
instance_type      = "t3.large"
ec2_instance_count = 1
os_type            = "linux"
key_name           = null  # Set your key pair name if needed

# SSH/RDP Access (Add your IP addresses)
allowed_ssh_cidr_blocks = []
# Example: ["1.2.3.4/32", "5.6.7.8/32"]

# RDS Configuration
rds_instance_class          = "db.t3.small"
rds_allocated_storage       = 20
rds_engine_version          = "8.0"
rds_multi_az                = false  # Single AZ for dev
rds_backup_retention_period = 1      # Minimum retention for dev
rds_master_username         = "admin"
rds_database_name           = "appdb"

# KMS Encryption
enable_kms_encryption  = true
kms_key_deletion_window = 7

# AWS Backup
enable_aws_backup       = false  # No backup for dev
backup_daily_retention  = 7
backup_monthly_retention = 30

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "Infrastructure"
  CostCenter  = "Development"
}
