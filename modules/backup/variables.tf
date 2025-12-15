# Backup Module Variables

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "backup_vault_name" {
  type        = string
  description = "Name of the backup vault"
}

variable "backup_role_name" {
  type        = string
  description = "IAM role name for AWS Backup"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for backup encryption"
  default     = null
}

variable "enable_daily_backup" {
  type        = bool
  description = "Enable daily backups"
  default     = false
}

variable "enable_monthly_backup" {
  type        = bool
  description = "Enable monthly backups"
  default     = false
}

variable "daily_retention_days" {
  type        = number
  description = "Number of days to retain daily backups"
  default     = 7
}

variable "monthly_retention_days" {
  type        = number
  description = "Number of days to retain monthly backups"
  default     = 30
}

variable "backup_resource_arns" {
  type        = list(string)
  description = "List of resource ARNs to backup"
  default     = []
}

variable "backup_tag_key" {
  type        = string
  description = "Tag key for backup selection"
  default     = null
}

variable "backup_tag_value" {
  type        = string
  description = "Tag value for backup selection"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
