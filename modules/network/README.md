# Network Module

## Overview
This module creates a complete AWS VPC network infrastructure with a segmented subnet design for enhanced security and organization:
- VPC with configurable CIDR
- **Public subnets** for Application Load Balancers (ALB)
- **Private subnets** for EC2 instances
- **Database subnets** for RDS MySQL instances
- **Endpoint subnets** for VPC endpoints
- Internet Gateway for public internet access
- NAT Gateway(s) for private subnet internet access
- Route tables and associations
- RDS DB Subnet Group

## Architecture

### Subnet Design
The module implements a four-tier subnet architecture across multiple availability zones:

1. **Public Subnets (ALB Tier)**
   - Purpose: Host Application Load Balancers
   - Internet Access: Direct via Internet Gateway
   - CIDR: `cidrsubnet(var.vpc_cidr, 4, 0..az_count-1)`
   - Tags: `Tier = "alb"`

2. **Private Subnets (EC2 Tier)**
   - Purpose: Host EC2 application instances
   - Internet Access: Via NAT Gateway
   - CIDR: `cidrsubnet(var.vpc_cidr, 4, az_count..(az_count*2-1))`
   - Tags: `Tier = "ec2"`

3. **Database Subnets (RDS Tier)**
   - Purpose: Host RDS MySQL databases
   - Internet Access: Via NAT Gateway
   - CIDR: `cidrsubnet(var.vpc_cidr, 4, (az_count*2)..(az_count*3-1))`
   - Tags: `Tier = "database"`
   - DB Subnet Group: Automatically created

4. **Endpoint Subnets (VPC Endpoints Tier)**
   - Purpose: Host VPC endpoints for AWS services
   - Internet Access: Via NAT Gateway
   - CIDR: `cidrsubnet(var.vpc_cidr, 4, (az_count*3)..(az_count*4-1))`
   - Tags: `Tier = "endpoint"`

### CIDR Allocation Example
For VPC CIDR `10.0.0.0/16` with 2 AZs:
- Public Subnet AZ1: `10.0.0.0/20` (for ALB)
- Public Subnet AZ2: `10.0.16.0/20` (for ALB)
- Private Subnet AZ1: `10.0.32.0/20` (for EC2)
- Private Subnet AZ2: `10.0.48.0/20` (for EC2)
- Database Subnet AZ1: `10.0.64.0/20` (for RDS)
- Database Subnet AZ2: `10.0.80.0/20` (for RDS)
- Endpoint Subnet AZ1: `10.0.96.0/20` (for VPC Endpoints)
- Endpoint Subnet AZ2: `10.0.112.0/20` (for VPC Endpoints)

## Features
- Multi-AZ deployment for high availability
- Automatic CIDR calculation for subnets
- Optional NAT Gateway (can be disabled for cost savings in dev)
- Single or multi-NAT Gateway configuration
- DNS support for private hosted zones
- Automatic DB Subnet Group creation for RDS

## Usage

```hcl
module "network" {
  source = "./modules/network"

  environment          = "prod"
  vpc_cidr             = "10.0.0.0/16"
  az_count             = 2
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]
  enable_nat_gateway   = true
  single_nat_gateway   = false  # Set to true for dev environments to save costs
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Environment = "prod"
    Project     = "my-project"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (dev/uat/prod) | `string` | n/a | yes |
| vpc_cidr | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |
| az_count | Number of Availability Zones | `number` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| single_nat_gateway | Use single NAT Gateway for all AZs | `bool` | `false` | no |
| enable_dns_hostnames | Enable DNS hostnames in VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in VPC | `bool` | `true` | no |
| tags | Common tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs for ALB |
| private_subnet_ids | List of private subnet IDs for EC2 instances |
| database_subnet_ids | List of database subnet IDs for RDS |
| endpoint_subnet_ids | List of endpoint subnet IDs for VPC endpoints |
| public_subnet_cidrs | List of public subnet CIDR blocks |
| private_subnet_cidrs | List of private subnet CIDR blocks |
| database_subnet_cidrs | List of database subnet CIDR blocks |
| endpoint_subnet_cidrs | List of endpoint subnet CIDR blocks |
| db_subnet_group_name | Database subnet group name for RDS |
| db_subnet_group_id | Database subnet group ID for RDS |
| nat_gateway_ids | List of NAT Gateway IDs |
| internet_gateway_id | Internet Gateway ID |
| public_route_table_id | Public route table ID |
| private_route_table_ids | List of private route table IDs |
| availability_zones | List of availability zones used |

## Cost Optimization

### Development Environment
- Set `single_nat_gateway = true` to use one NAT Gateway instead of one per AZ
- Consider `enable_nat_gateway = false` if private subnets don't need internet access
- Use fewer availability zones (`az_count = 1`)

### Production Environment
- Set `single_nat_gateway = false` for high availability
- Deploy across multiple AZs (`az_count = 2` or `3`)
- Enable NAT Gateway for secure outbound internet access

## Security Considerations

1. **Network Segmentation**: Each tier is isolated in dedicated subnets
2. **No Direct Database Access**: Database subnets have no direct internet access
3. **Private Instance Isolation**: EC2 instances are isolated from direct internet access
4. **Endpoint Isolation**: VPC endpoints are in dedicated subnets for better security
5. **Route Table Separation**: Each subnet type can have different routing rules

## Best Practices

1. **Use appropriate CIDR blocks**: Ensure your VPC CIDR is large enough for all subnets
2. **Multi-AZ for production**: Always use at least 2 AZs for production environments
3. **Tag consistently**: Use consistent tagging for resource identification and cost allocation
4. **Plan subnet growth**: Leave room for additional subnets if needed in the future
5. **Monitor NAT Gateway costs**: Consider using VPC endpoints to reduce NAT Gateway usage

## Dependencies
- AWS Provider configured with appropriate credentials
- Sufficient IP addresses in the VPC CIDR for all subnet types

## Notes
- Each subnet type gets `/20` CIDR blocks by default (4091 usable IPs per subnet)
- All private, database, and endpoint subnets share the same route tables and use NAT Gateway for internet access
- The DB subnet group is automatically created and can be directly referenced by the RDS module
- Public subnets have `map_public_ip_on_launch` enabled for ALB deployment
