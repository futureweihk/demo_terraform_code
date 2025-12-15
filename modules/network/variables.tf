variable "environment" {
  type        = string
  description = "Environment name (dev/uat/prod)"
  
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, uat, or prod"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones (1 for dev, 2 for uat/prod)"
  
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "AZ count must be between 1 and 3"
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT Gateway for private subnets"
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use single NAT Gateway for all private subnets (cost optimization for dev)"
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

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}
