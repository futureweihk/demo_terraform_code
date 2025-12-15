# IAM Roles and Policies for EC2 Instances

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = var.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.ec2_role_name}-profile"
  role = aws_iam_role.ec2.name

  tags = var.tags
}

# Attach SSM Managed Policy (for Systems Manager access)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_manager" {
  name = "${var.environment}-ec2-secrets-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arn != null ? [var.secret_arn] : ["*"]
      }
    ]
  })
}

# Custom policy for S3 access (if needed)
resource "aws_iam_role_policy" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  name = "${var.environment}-ec2-s3-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns
      }
    ]
  })
}

# Custom policy for KMS (decrypt secrets)
resource "aws_iam_role_policy" "kms_decrypt" {
  count = var.enable_encryption ? 1 : 0

  name = "${var.environment}-ec2-kms-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn != null ? [var.kms_key_arn] : ["*"]
      }
    ]
  })
}
