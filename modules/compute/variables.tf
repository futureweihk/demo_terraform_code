# Compute Module Variables

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for ALB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EC2 instances"
}

# EC2 Configuration
variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.large"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
  default     = null
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 30
}

variable "detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for EC2"
  default     = false
}

variable "os_type" {
  type        = string
  description = "Operating system type (linux/windows)"
  default     = "linux"
}

variable "ec2_name_prefix" {
  type        = string
  description = "Name prefix for EC2 instances"
}

variable "ec2_role_name" {
  type        = string
  description = "IAM role name for EC2 instances"
}

# User Data
variable "user_data_script" {
  type        = string
  description = "User data script for EC2 instances"
  default     = null
}

variable "db_endpoint" {
  type        = string
  description = "RDS database endpoint"
  default     = ""
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = ""
}

variable "secret_arn" {
  type        = string
  description = "ARN of the secret containing database credentials"
  default     = null
}

# ALB Configuration
variable "alb_name" {
  type        = string
  description = "Application Load Balancer name"
}

variable "target_group_name" {
  type        = string
  description = "Target group name"
}

variable "target_group_port" {
  type        = number
  description = "Target group port"
  default     = 80
}

variable "target_group_protocol" {
  type        = string
  description = "Target group protocol"
  default     = "HTTP"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for ALB"
  default     = false
}

variable "enable_stickiness" {
  type        = bool
  description = "Enable sticky sessions"
  default     = true
}

variable "deregistration_delay" {
  type        = number
  description = "Deregistration delay in seconds"
  default     = 30
}

# Health Check Configuration
variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}

variable "health_check_interval" {
  type        = number
  description = "Health check interval in seconds"
  default     = 30
}

variable "health_check_timeout" {
  type        = number
  description = "Health check timeout in seconds"
  default     = 5
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "Healthy threshold count"
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "Unhealthy threshold count"
  default     = 2
}

variable "health_check_matcher" {
  type        = string
  description = "Health check response codes"
  default     = "200"
}

# HTTPS Configuration
variable "enable_https" {
  type        = bool
  description = "Enable HTTPS listener"
  default     = false
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS"
  default     = null
}

variable "ssl_policy" {
  type        = string
  description = "SSL policy for HTTPS listener"
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# Security
variable "allowed_ssh_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed for SSH/RDP access"
  default     = []
}

# RDS security group ID is no longer passed as variable
# Security group rules for EC2<->RDS are created in root main.tf
# to avoid count dependency issues

# Encryption
variable "enable_encryption" {
  type        = bool
  description = "Enable EBS encryption"
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for EBS encryption"
  default     = null
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for IAM policy"
  default     = null
}

# IAM Policies
variable "enable_s3_access" {
  type        = bool
  description = "Enable S3 access for EC2 instances"
  default     = false
}

variable "s3_bucket_arns" {
  type        = list(string)
  description = "S3 bucket ARNs for IAM policy"
  default     = ["*"]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
