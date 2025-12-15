# KMS Module Variables

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "key_deletion_window" {
  type        = number
  description = "KMS key deletion window in days"
  default     = 10
}

variable "ec2_key_alias" {
  type        = string
  description = "Alias for EC2 KMS key"
}

variable "rds_key_alias" {
  type        = string
  description = "Alias for RDS KMS key"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to KMS keys"
  default     = {}
}
