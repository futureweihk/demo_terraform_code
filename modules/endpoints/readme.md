# VPC Endpoints Module

## Overview
This module creates AWS VPC Endpoints to enable private connectivity to AWS services without traversing the public internet.

## Supported Endpoints

### Gateway Endpoints (No hourly charge)
- **S3**: Access S3 buckets privately

### Interface Endpoints (Hourly charge + data processing)
- **Secrets Manager**: Access secrets privately
- **ECR API**: Pull container images metadata
- **ECR DKR**: Pull container images
- **RDS**: Private RDS API access

## Architecture Benefits
┌────────────────────────────────────────┐
│ VPC │
│ │
│ ┌──────────────┐ ┌──────────────┐ │
│ │ EC2 Instance │───▶│ VPC Endpoint │─┼──▶ AWS Service
│ │ (Private) │ │ (Interface) │ │ (Secrets Manager)
│ └──────────────┘ └──────────────┘ │
│ │
│ ✓ No Internet Gateway needed │
│ ✓ Traffic stays within AWS network │
│ ✓ Lower latency │
│ ✓ Enhanced security │
└────────────────────────────────────────┘


## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| environment | string | Yes | - | Environment name |
| vpc_id | string | Yes | - | VPC ID |
| private_subnet_ids | list(string) | Yes | - | Private subnet IDs |
| route_table_ids | list(string) | No | [] | Route table IDs for gateway endpoints |
| enable_s3_endpoint | bool | No | true | Enable S3 endpoint |
| enable_secrets_manager_endpoint | bool | No | true | Enable Secrets Manager endpoint |
| enable_ecr_api_endpoint | bool | No | false | Enable ECR API endpoint |
| enable_ecr_dkr_endpoint | bool | No | false | Enable ECR DKR endpoint |
| enable_rds_endpoint | bool | No | false | Enable RDS endpoint |
| allowed_cidr_blocks | list(string) | No | [] | Allowed CIDR blocks |
| tags | map(string) | No | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | Security group ID for endpoints |
| s3_endpoint_id | S3 endpoint ID |
| secrets_manager_endpoint_id | Secrets Manager endpoint ID |
| endpoint_dns_entries | DNS entries for interface endpoints |

## Usage Example

```hcl
module "endpoints" {
  source = "./modules/endpoints"

  environment        = "prod"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  route_table_ids    = module.network.private_route_table_ids

  enable_s3_endpoint              = true
  enable_secrets_manager_endpoint = true
  enable_ecr_api_endpoint         = true
  enable_ecr_dkr_endpoint         = true

  allowed_cidr_blocks = [module.network.vpc_cidr]

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
