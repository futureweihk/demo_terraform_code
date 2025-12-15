# Security Groups for ALB and EC2

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Ingress: HTTP
resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from anywhere"
}

# ALB Ingress: HTTPS
resource "aws_security_group_rule" "alb_https_ingress" {
  count = var.enable_https ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from anywhere"
}

# ALB Egress: To EC2 target group
resource "aws_security_group_rule" "alb_egress_to_ec2" {
  type                     = "egress"
  from_port                = var.target_group_port
  to_port                  = var.target_group_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ec2.id
  description              = "Allow traffic to EC2 instances"
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name_prefix = "${var.environment}-ec2-"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ec2-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Ingress: From ALB
resource "aws_security_group_rule" "ec2_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.target_group_port
  to_port                  = var.target_group_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB"
}

# EC2 Ingress: SSH/RDP from allowed CIDR blocks
resource "aws_security_group_rule" "ec2_ssh_ingress" {
  count = length(var.allowed_ssh_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.os_type == "linux" ? 22 : 3389
  to_port           = var.os_type == "linux" ? 22 : 3389
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = var.allowed_ssh_cidr_blocks
  description       = var.os_type == "linux" ? "Allow SSH from allowed IPs" : "Allow RDP from allowed IPs"
}

# # EC2 Egress: To RDS
# Note: This rule is created in the root main.tf after both modules exist
# to avoid count dependency issues

# # EC2 Egress: To RDS
# resource "aws_security_group_rule" "ec2_egress_to_rds" {
#   for_each = var.rds_security_group_id != "" ? toset(["rds"]) : toset([])

#   type                     = "egress"
#   from_port                = 3306
#   to_port                  = 3306
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ec2.id
#   source_security_group_id = var.rds_security_group_id
#   description              = "Allow traffic to RDS"
# }


# EC2 Egress: HTTPS for package downloads and AWS services
resource "aws_security_group_rule" "ec2_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS outbound"
}

# EC2 Egress: HTTP for package downloads
resource "aws_security_group_rule" "ec2_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP outbound"
}

# EC2 Egress: DNS
resource "aws_security_group_rule" "ec2_egress_dns" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow DNS queries"
}
