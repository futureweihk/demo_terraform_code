# KMS Keys for EC2 and RDS Encryption

# KMS Key for EC2 EBS Volumes
resource "aws_kms_key" "ec2" {
  description             = "KMS key for EC2 EBS volume encryption in ${var.environment}"
  deletion_window_in_days = var.key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.environment}-ec2-kms-key"
      Purpose = "EC2 EBS Encryption"
    }
  )
}

resource "aws_kms_alias" "ec2" {
  name          = var.ec2_key_alias
  target_key_id = aws_kms_key.ec2.key_id
}

# KMS Key Policy for EC2
resource "aws_kms_key_policy" "ec2" {
  key_id = aws_kms_key.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })
}

# KMS Key for RDS
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption in ${var.environment}"
  deletion_window_in_days = var.key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.environment}-rds-kms-key"
      Purpose = "RDS Encryption"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = var.rds_key_alias
  target_key_id = aws_kms_key.rds.key_id
}

# KMS Key Policy for RDS
resource "aws_kms_key_policy" "rds" {
  key_id = aws_kms_key.rds.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })
}
