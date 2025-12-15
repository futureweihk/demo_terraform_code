# Compute Module Outputs

# EC2 Outputs
output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.main[*].id
}

output "instance_arns" {
  description = "List of EC2 instance ARNs"
  value       = aws_instance.main[*].arn
}

output "private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.main[*].private_ip
}

output "instance_names" {
  description = "List of EC2 instance names"
  value       = aws_instance.main[*].tags["Name"]
}

# ALB Outputs
output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Target group name"
  value       = aws_lb_target_group.main.name
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

# IAM Outputs
output "ec2_role_name" {
  description = "EC2 IAM role name"
  value       = aws_iam_role.ec2.name
}

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN"
  value       = aws_iam_instance_profile.ec2.arn
}
