# Root Main Configuration - Orchestrates All Modules

# KMS Module (if encryption enabled)
module "kms" {
  count  = var.enable_kms_encryption ? 1 : 0
  source = "./modules/kms"

  environment          = var.environment
  account_id           = data.aws_caller_identity.current.account_id
  key_deletion_window  = var.kms_key_deletion_window
  ec2_key_alias        = local.kms_ec2_key_alias
  rds_key_alias        = local.kms_rds_key_alias
  tags                 = local.common_tags
}

# Network Module
module "network" {
  source = "./modules/network"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  availability_zones   = local.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = local.common_tags
}

# VPC Endpoints Module
module "endpoints" {
  source = "./modules/endpoints"

  environment                      = var.environment
  vpc_id                           = module.network.vpc_id
  endpoint_subnet_ids              = module.network.endpoint_subnet_ids
  route_table_ids                  = concat([module.network.public_route_table_id], module.network.private_route_table_ids)
  enable_s3_endpoint               = var.enable_s3_endpoint
  enable_secrets_manager_endpoint  = var.enable_secrets_manager_endpoint
  enable_ecr_api_endpoint          = var.enable_ecr_api_endpoint
  enable_ecr_dkr_endpoint          = var.enable_ecr_dkr_endpoint
  enable_rds_endpoint              = var.enable_rds_endpoint
  allowed_cidr_blocks              = []
  tags                             = local.common_tags

  depends_on = [module.network]
}

# Secrets Module
module "secrets" {
  source = "./modules/secrets"

  environment          = var.environment
  rds_master_username  = var.rds_master_username
  secret_name_prefix   = "rds"
  recovery_window_days = 7
  tags                 = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"

  environment                     = var.environment
  vpc_id                          = module.network.vpc_id
  db_subnet_group_name            = module.network.db_subnet_group_name
  db_identifier                   = local.rds_identifier
  instance_class                  = var.rds_instance_class
  engine_version                  = var.rds_engine_version
  allocated_storage               = var.rds_allocated_storage
  max_allocated_storage           = var.rds_allocated_storage * 5
  database_name                   = var.rds_database_name
  master_username                 = var.rds_master_username
  master_password                 = module.secrets.rds_password
  database_port                   = local.rds_port
  multi_az                        = var.rds_multi_az
  availability_zone               = var.rds_multi_az ? null : local.availability_zones[0]
  backup_retention_period         = var.rds_backup_retention_period
  skip_final_snapshot             = local.is_dev
  monitoring_interval             = local.is_production ? 60 : 0
  performance_insights_enabled    = local.is_production
  deletion_protection             = local.is_production
  enable_encryption               = var.enable_kms_encryption
  kms_key_arn                     = var.enable_kms_encryption ? module.kms[0].rds_kms_key_arn : null
  allowed_security_group_ids      = []
  allowed_cidr_blocks             = []
  tags                            = local.common_tags

  depends_on = [
    module.network,
    module.secrets,
    module.kms
  ]
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  environment                = var.environment
  vpc_id                     = module.network.vpc_id
  public_subnet_ids          = module.network.public_subnet_ids
  private_subnet_ids         = module.network.private_subnet_ids
  instance_count             = var.ec2_instance_count
  instance_type              = var.instance_type
  ami_id                     = var.os_type == "linux" ? data.aws_ami.amazon_linux_2.id : data.aws_ami.windows.id
  key_name                   = var.key_name
  root_volume_size           = var.os_type == "linux" ? 30 : 50
  detailed_monitoring        = local.is_production
  os_type                    = var.os_type
  ec2_name_prefix            = local.ec2_name_prefix
  ec2_role_name              = local.ec2_role_name
  user_data_script           = null  # User data is handled internally by the compute module
  db_endpoint                = module.database.db_endpoint
  db_name                    = var.rds_database_name
  secret_arn                 = module.secrets.secret_arn
  alb_name                   = local.alb_name
  target_group_name          = local.target_group_name
  target_group_port          = 80
  enable_deletion_protection = local.is_production
  enable_https               = false
  certificate_arn            = null
  allowed_ssh_cidr_blocks    = var.allowed_ssh_cidr_blocks
  enable_encryption          = var.enable_kms_encryption
  kms_key_id                 = var.enable_kms_encryption ? module.kms[0].ec2_kms_key_id : null
  kms_key_arn                = var.enable_kms_encryption ? module.kms[0].ec2_kms_key_arn : null
  enable_s3_access           = false
  tags                       = local.common_tags

  depends_on = [
    module.network,
    module.database,
    module.kms
  ]
}

# Security Group Rules for EC2 <-> RDS connectivity
# These are created here to avoid count dependency issues in modules

# Allow RDS to receive traffic from EC2
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = local.rds_port
  to_port                  = local.rds_port
  protocol                 = "tcp"
  security_group_id        = module.database.security_group_id
  source_security_group_id = module.compute.ec2_security_group_id
  description              = "Allow MySQL from EC2 instances"

  depends_on = [
    module.database,
    module.compute
  ]
}

# Allow EC2 to send traffic to RDS
resource "aws_security_group_rule" "ec2_to_rds" {
  type                     = "egress"
  from_port                = local.rds_port
  to_port                  = local.rds_port
  protocol                 = "tcp"
  security_group_id        = module.compute.ec2_security_group_id
  source_security_group_id = module.database.security_group_id
  description              = "Allow traffic to RDS MySQL"

  depends_on = [
    module.database,
    module.compute
  ]
}

# AWS Backup Module (conditional)
module "backup" {
  count  = var.enable_aws_backup ? 1 : 0
  source = "./modules/backup"

  environment            = var.environment
  backup_vault_name      = local.backup_vault_name
  backup_role_name       = local.backup_role_name
  kms_key_arn            = var.enable_kms_encryption ? module.kms[0].rds_kms_key_arn : null
  enable_daily_backup    = local.enable_daily_backup
  enable_monthly_backup  = local.enable_monthly_backup
  daily_retention_days   = var.backup_daily_retention
  monthly_retention_days = var.backup_monthly_retention
  backup_resource_arns   = [module.database.db_instance_arn]
  tags                   = local.common_tags

  depends_on = [
    module.database,
    module.kms
  ]
}

# VPC Flow Logs (Optional)
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = local.flow_logs_log_group_name
  retention_in_days = local.flow_logs_retention_days

  tags = local.common_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name               = "${local.name_prefix}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name   = "${local.name_prefix}-flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_policy[0].json
}

resource "aws_flow_log" "main" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = module.network.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-flow-logs"
    }
  )

  depends_on = [module.network]
}
