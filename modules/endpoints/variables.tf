variable "environment" {
  type        = string
  description = "Environment name (dev/uat/prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "endpoint_subnet_ids" {
  type        = list(string)
  description = "List of dedicated endpoint subnet IDs for interface endpoints"
}

variable "route_table_ids" {
  type        = list(string)
  description = "List of route table IDs for gateway endpoints"
  default     = []
}

variable "enable_s3_endpoint" {
  type        = bool
  description = "Enable S3 VPC endpoint (Gateway type)"
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
  default     = false
}

variable "enable_ecr_dkr_endpoint" {
  type        = bool
  description = "Enable ECR DKR VPC endpoint"
  default     = false
}

variable "enable_rds_endpoint" {
  type        = bool
  description = "Enable RDS VPC endpoint"
  default     = false
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access endpoints"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}
