# Global Variables for Terraform AWS Infrastructure

variable "environment" {
  type        = string
  description = "Environment name (dev/uat/prod)"
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, uat, or prod"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-east-1"
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones (1 for dev, 2 for uat/prod)"
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "AZ count must be between 1 and 3"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

# Network Configuration
variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT Gateway for private subnets"
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use single NAT Gateway (true for dev, false for prod/uat)"
  default     = false
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support in VPC"
  default     = true
}

# VPC Endpoints Configuration
variable "enable_s3_endpoint" {
  type        = bool
  description = "Enable S3 VPC endpoint"
  default     = true
}

variable "enable_secrets_manager_endpoint" {
  type        = bool
  description = "Enable Secrets Manager VPC endpoint"
  default     = true
}

variable "enable_ecr_api_endpoint" {
  type        = bool
  description = "Enable ECR API VPC endpoint"
  default     = true
}

variable "enable_ecr_dkr_endpoint" {
  type        = bool
  description = "Enable ECR DKR VPC endpoint"
  default     = true
}

variable "enable_rds_endpoint" {
  type        = bool
  description = "Enable RDS VPC endpoint"
  default     = false
}

# VPC Flow Logs (Optional)
variable "enable_vpc_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs for network monitoring"
  default     = false
}

# Compute Configuration
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.large"
}

variable "ec2_instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 1
  validation {
    condition     = var.ec2_instance_count >= 1 && var.ec2_instance_count <= 10
    error_message = "EC2 instance count must be between 1 and 10"
  }
}

variable "os_type" {
  type        = string
  description = "Operating system type (windows/linux)"
  default     = "linux"
  validation {
    condition     = contains(["windows", "linux"], var.os_type)
    error_message = "OS type must be windows or linux"
  }
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH/RDP access"
  default     = null
}

variable "allowed_ssh_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH/RDP to EC2 instances"
  default     = []
}

# RDS Configuration
variable "rds_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.small"
}

variable "rds_allocated_storage" {
  type        = number
  description = "RDS allocated storage in GB"
  default     = 20
  validation {
    condition     = var.rds_allocated_storage >= 20 && var.rds_allocated_storage <= 65536
    error_message = "RDS allocated storage must be between 20 and 65536 GB"
  }
}

variable "rds_engine_version" {
  type        = string
  description = "MySQL engine version"
  default     = "8.0"
}

variable "rds_multi_az" {
  type        = bool
  description = "Enable Multi-AZ for RDS (recommended for prod)"
  default     = false
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS backup retention period in days"
  default     = 7
  validation {
    condition     = var.rds_backup_retention_period >= 0 && var.rds_backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days"
  }
}

variable "rds_master_username" {
  type        = string
  description = "RDS master username"
  default     = "admin"
}

variable "rds_database_name" {
  type        = string
  description = "Initial database name"
  default     = "appdb"
}

# AWS Backup Configuration
variable "enable_aws_backup" {
  type        = bool
  description = "Enable AWS Backup service"
  default     = false
}

variable "backup_daily_retention" {
  type        = number
  description = "Number of days to retain daily backups"
  default     = 7
}

variable "backup_monthly_retention" {
  type        = number
  description = "Number of days to retain monthly backups"
  default     = 30
}

# KMS Configuration
variable "enable_kms_encryption" {
  type        = bool
  description = "Enable KMS encryption for EC2 and RDS"
  default     = true
}

variable "kms_key_deletion_window" {
  type        = number
  description = "KMS key deletion window in days"
  default     = 10
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days"
  }
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "mbridge"
}
