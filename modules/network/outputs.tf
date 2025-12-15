output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs for ALB"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of private subnet IDs for EC2 instances"
}

output "database_subnet_ids" {
  value       = aws_subnet.database[*].id
  description = "List of database subnet IDs for RDS"
}

output "endpoint_subnet_ids" {
  value       = aws_subnet.endpoint[*].id
  description = "List of endpoint subnet IDs for VPC endpoints"
}

output "public_subnet_cidrs" {
  value       = aws_subnet.public[*].cidr_block
  description = "List of public subnet CIDR blocks"
}

output "private_subnet_cidrs" {
  value       = aws_subnet.private[*].cidr_block
  description = "List of private subnet CIDR blocks"
}

output "database_subnet_cidrs" {
  value       = aws_subnet.database[*].cidr_block
  description = "List of database subnet CIDR blocks"
}

output "endpoint_subnet_cidrs" {
  value       = aws_subnet.endpoint[*].cidr_block
  description = "List of endpoint subnet CIDR blocks"
}

output "db_subnet_group_name" {
  value       = aws_db_subnet_group.database.name
  description = "Database subnet group name for RDS"
}

output "db_subnet_group_id" {
  value       = aws_db_subnet_group.database.id
  description = "Database subnet group ID for RDS"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.main[*].id
  description = "List of NAT Gateway IDs"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "Internet Gateway ID"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_ids" {
  value       = aws_route_table.private[*].id
  description = "List of private route table IDs"
}

output "availability_zones" {
  value       = var.availability_zones
  description = "List of availability zones used"
}
