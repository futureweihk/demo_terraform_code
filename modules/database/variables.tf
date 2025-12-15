# Database Module Variables

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where RDS will be deployed"
}

variable "db_subnet_group_name" {
  type        = string
  description = "Name of the DB subnet group (from network module)"
}

variable "db_identifier" {
  type        = string
  description = "RDS instance identifier"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.small"
}

variable "engine_version" {
  type        = string
  description = "MySQL engine version"
  default     = "8.0"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage for autoscaling in GB"
  default     = 100
}

variable "storage_type" {
  type        = string
  description = "Storage type (gp2, gp3, io1)"
  default     = "gp3"
}

variable "database_name" {
  type        = string
  description = "Initial database name"
}

variable "master_username" {
  type        = string
  description = "Master username for RDS"
}

variable "master_password" {
  type        = string
  description = "Master password for RDS"
  sensitive   = true
}

variable "database_port" {
  type        = number
  description = "Database port"
  default     = 3306
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for single-AZ deployment"
  default     = null
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period in days"
  default     = 7
}

variable "backup_window" {
  type        = string
  description = "Preferred backup window"
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type        = string
  description = "Preferred maintenance window"
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying"
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "List of log types to export to CloudWatch"
  default     = ["error", "general", "slowquery"]
}

variable "monitoring_interval" {
  type        = number
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  default     = 0
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable Performance Insights"
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Apply changes immediately"
  default     = false
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "Enable automatic minor version upgrades"
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false
}

variable "enable_encryption" {
  type        = bool
  description = "Enable storage encryption"
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption"
  default     = null
}

variable "max_connections" {
  type        = string
  description = "Maximum number of connections"
  default     = "1000"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs allowed to access RDS"
  default     = []
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access RDS"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
