# Production Environment Configuration

# Environment
environment = "prod"
aws_region  = "ap-east-1"

# Project
project_name = "infrastructure"

# Network Configuration
vpc_cidr           = "10.2.0.0/16"
az_count           = 2  # High availability
enable_nat_gateway = true
single_nat_gateway = false  # NAT Gateway per AZ for redundancy

# VPC Endpoints
enable_s3_endpoint              = true
enable_secrets_manager_endpoint = true
enable_ecr_api_endpoint         = true
enable_ecr_dkr_endpoint         = true
enable_rds_endpoint             = false

# VPC Flow Logs
enable_vpc_flow_logs = true  # Enable for production monitoring

# Compute Configuration
instance_type      = "t3.large"
ec2_instance_count = 2
os_type            = "linux"
key_name           = null  # Set your key pair name if needed

# SSH/RDP Access (Add your IP addresses)
allowed_ssh_cidr_blocks = []
# Example: ["1.2.3.4/32", "5.6.7.8/32"]

# RDS Configuration
rds_instance_class          = "db.t3.large"
rds_allocated_storage       = 100
rds_engine_version          = "8.0"
rds_multi_az                = true  # Multi-AZ for high availability
rds_backup_retention_period = 30    # 30 days retention for production
rds_master_username         = "admin"
rds_database_name           = "appdb"

# KMS Encryption
enable_kms_encryption   = true
kms_key_deletion_window = 30  # Maximum window for production safety

# AWS Backup (Daily and Monthly backups enabled for PROD)
enable_aws_backup        = true
backup_daily_retention   = 7   # 7 days for daily backups
backup_monthly_retention = 30  # 30 days for monthly backups

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "Terraform"
  Project     = "Infrastructure"
  CostCenter  = "Production"
  Criticality = "High"
}
