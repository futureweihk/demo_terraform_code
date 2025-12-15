# Data source for current region
data "aws_region" "current" {}

# Security Group for Interface Endpoints
resource "aws_security_group" "endpoints" {
  name_prefix = "${var.environment}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-vpc-endpoints-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count        = var.enable_s3_endpoint ? 1 : 0
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-s3-endpoint"
    }
  )
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secrets_manager" {
  count               = var.enable_secrets_manager_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-secretsmanager-endpoint"
    }
  )
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_ecr_api_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecr-api-endpoint"
    }
  )
}

# ECR DKR Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_ecr_dkr_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecr-dkr-endpoint"
    }
  )
}

# RDS Interface Endpoint
resource "aws_vpc_endpoint" "rds" {
  count               = var.enable_rds_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.rds"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-rds-endpoint"
    }
  )
}
