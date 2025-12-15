# EC2 Compute Module

# EC2 Instances
resource "aws_instance" "main" {
  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = var.key_name

  # EBS encryption with KMS
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = var.enable_encryption
    kms_key_id            = var.enable_encryption ? var.kms_key_id : null
    delete_on_termination = true

    tags = merge(
      var.tags,
      {
        Name = "${var.ec2_name_prefix}-${count.index + 1}-root"
      }
    )
  }

  user_data = var.user_data_script

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring = var.detailed_monitoring

  tags = merge(
    var.tags,
    {
      Name  = "${var.ec2_name_prefix}-${count.index + 1}"
      Index = count.index + 1
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }

  depends_on = [
    aws_iam_instance_profile.ec2
  ]
}
