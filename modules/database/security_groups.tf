# Security Group for RDS MySQL Instance

resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-"
  description = "Security group for RDS MySQL instance"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-rds-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rule: Allow MySQL traffic from EC2 security group
resource "aws_security_group_rule" "rds_ingress_from_ec2" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
  description              = "Allow MySQL from EC2 security group ${count.index + 1}"
}

# Ingress rule: Allow MySQL traffic from VPC CIDR (optional)
resource "aws_security_group_rule" "rds_ingress_from_vpc" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.database_port
  to_port           = var.database_port
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "Allow MySQL from VPC CIDR"
}

# Egress rule: Allow all outbound traffic
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}
