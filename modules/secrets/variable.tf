variable "environment" {
  type        = string
  description = "Environment name (dev/uat/prod)"
}

variable "rds_master_username" {
  type        = string
  description = "RDS master username"
  default     = "dbadmin"
}

variable "secret_name_prefix" {
  type        = string
  description = "Prefix for secret names"
  default     = "rds"
}

variable "password_length" {
  type        = number
  description = "Length of generated password"
  default     = 32
}

variable "password_special_chars" {
  type        = bool
  description = "Include special characters in password"
  default     = true
}

variable "password_override_special" {
  type        = string
  description = "Override special characters to use"
  default     = "!#$%&*()-_=+[]{}<>:?"
}

variable "recovery_window_days" {
  type        = number
  description = "Number of days to recover deleted secret"
  default     = 7
  
  validation {
    condition     = var.recovery_window_days >= 7 && var.recovery_window_days <= 30
    error_message = "Recovery window must be between 7 and 30 days"
  }
}

variable "enable_rotation" {
  type        = bool
  description = "Enable automatic secret rotation"
  default     = false
}

variable "rotation_days" {
  type        = number
  description = "Number of days between automatic rotations"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}
