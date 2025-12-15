# Local Variables for Terraform AWS Infrastructure

locals {
  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Availability Zones
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Common tags to be applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Timestamp   = timestamp()
    }
  )

  # Environment-specific configurations
  is_production = var.environment == "prod"
  is_uat        = var.environment == "uat"
  is_dev        = var.environment == "dev"

  # Backup configuration per environment
  enable_daily_backup = var.enable_aws_backup && (local.is_production || local.is_uat)
  enable_monthly_backup = var.enable_aws_backup && local.is_production

  # VPC Flow Logs configuration
  flow_logs_retention_days = local.is_production ? 30 : (local.is_uat ? 14 : 7)

  # KMS key aliases
  kms_ec2_key_alias = "alias/${local.name_prefix}-ec2"
  kms_rds_key_alias = "alias/${local.name_prefix}-rds"

  # RDS configuration
  rds_port = 3306 # MySQL default port

  # Security Group naming
  sg_alb_name      = "${local.name_prefix}-alb-sg"
  sg_ec2_name      = "${local.name_prefix}-ec2-sg"
  sg_rds_name      = "${local.name_prefix}-rds-sg"
  sg_endpoints_name = "${local.name_prefix}-endpoints-sg"

  # ALB configuration
  alb_name = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"

  # EC2 configuration
  ec2_name_prefix = "${local.name_prefix}-ec2"
  
  # RDS configuration
  rds_identifier = "${local.name_prefix}-mysql"
  
  # Note: Subnet CIDRs and DB subnet group are managed by the network module
  # - Public subnets (ALB): cidrsubnet(vpc_cidr, 4, 0..az_count-1)
  # - Private subnets (EC2): cidrsubnet(vpc_cidr, 4, az_count..(az_count*2-1))
  # - Database subnets (RDS): cidrsubnet(vpc_cidr, 4, (az_count*2)..(az_count*3-1))
  # - Endpoint subnets (VPC Endpoints): cidrsubnet(vpc_cidr, 4, (az_count*3)..(az_count*4-1))

  # IAM role names
  ec2_role_name = "${local.name_prefix}-ec2-role"
  backup_role_name = "${local.name_prefix}-backup-role"

  # Backup vault name
  backup_vault_name = "${local.name_prefix}-backup-vault"

  # CloudWatch Log Group for VPC Flow Logs
  flow_logs_log_group_name = "/aws/vpc/${local.name_prefix}"
}
