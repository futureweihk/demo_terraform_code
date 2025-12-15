# Terraform AWS Infrastructure - Deployment Guide

## 📋 Prerequisites

### Required Tools
- **Terraform**: >= 1.5.0
- **AWS CLI**: >= 2.0
- **Git**: For version control

### AWS Account Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- IAM permissions to create:
  - VPC, Subnets, NAT Gateways
  - EC2 instances, ALB
  - RDS MySQL instances
  - KMS keys
  - Secrets Manager
  - VPC Endpoints
  - AWS Backup (for PROD)

---

## 🚀 Quick Start - Deployment Steps

### Step 1: Prepare Backend Storage

Before deploying, create S3 bucket and DynamoDB table for Terraform state:

```bash
# Set your AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# For DEV environment
aws s3 mb s3://terraform-state-dev-${AWS_ACCOUNT_ID} --region ap-southeast-1
aws s3api put-bucket-versioning \
  --bucket terraform-state-dev-${AWS_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-state-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1

# Repeat for UAT and PROD (replace 'dev' with 'uat' or 'prod')
```

### Step 2: Update Backend Configuration

Edit the backend configuration file for your environment:

```bash
# For DEV
vim environments/dev/backend.tf
# Replace REPLACE_WITH_ACCOUNT_ID with your actual AWS account ID
```

### Step 3: Customize Variables

Edit the terraform.tfvars file for your environment:

```bash
# For DEV
vim environments/dev/terraform.tfvars

# Important variables to customize:
# - key_name: Your EC2 key pair name (optional)
# - allowed_ssh_cidr_blocks: Your IP addresses for SSH/RDP access
# - rds_master_username: Database admin username
```

### Step 4: Initialize Terraform

```bash
# Navigate to project root
cd terraform-aws-infrastructure

# Initialize with backend configuration
terraform init -backend-config=environments/dev/backend.tf

# Validate configuration
terraform validate
```

### Step 5: Plan Deployment

```bash
# Review the execution plan
terraform plan -var-file=environments/dev/terraform.tfvars
```

### Step 6: Deploy Infrastructure

```bash
# Apply the configuration
terraform apply -var-file=environments/dev/terraform.tfvars

# Confirm with 'yes' when prompted
```

### Step 7: Retrieve Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output alb_dns_name
terraform output rds_endpoint
```

---

## 🌍 Environment-Specific Deployments

### DEV Environment
```bash
# Initialize
terraform init -backend-config=environments/dev/backend.tf

# Deploy
terraform apply -var-file=environments/dev/terraform.tfvars

# Characteristics:
# - Single AZ (cost optimized)
# - Single NAT Gateway
# - db.t3.small RDS
# - No AWS Backup
# - 1 EC2 instance
```

### UAT Environment
```bash
# Initialize
terraform init -backend-config=environments/uat/backend.tf

# Deploy
terraform apply -var-file=environments/uat/terraform.tfvars

# Characteristics:
# - 2 AZs (high availability)
# - NAT Gateway per AZ
# - db.t3.medium RDS with Multi-AZ
# - No AWS Backup (per requirements)
# - 2 EC2 instances
```

### PROD Environment
```bash
# Initialize
terraform init -backend-config=environments/prod/backend.tf

# Deploy
terraform apply -var-file=environments/prod/terraform.tfvars

# Characteristics:
# - 2 AZs (high availability)
# - NAT Gateway per AZ
# - db.t3.large RDS with Multi-AZ
# - AWS Backup enabled (daily + monthly)
# - VPC Flow Logs enabled
# - 2 EC2 instances
# - Enhanced monitoring
```

---

## 🔐 Security Configuration

### 1. KMS Keys
The infrastructure creates two KMS keys:
- **EC2 KMS Key**: Encrypts EBS volumes
- **RDS KMS Key**: Encrypts RDS data

Both keys have automatic rotation enabled.

### 2. Secrets Manager
Database credentials are automatically generated and stored in AWS Secrets Manager.

To retrieve credentials:
```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw rds_secret_arn) \
  --query SecretString \
  --output text | jq
```

### 3. Security Groups
- **ALB**: Allows HTTP (80) and HTTPS (443) from internet
- **EC2**: Allows traffic from ALB only (plus SSH/RDP from allowed IPs)
- **RDS**: Allows MySQL (3306) from EC2 only

### 4. IAM Roles
EC2 instances have IAM roles with least-privilege access:
- AWS Systems Manager (SSM) for remote management
- Secrets Manager read access for database credentials
- CloudWatch for logging and monitoring

---

## 📊 Accessing Resources

### Application Load Balancer
```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Application URL: http://${ALB_DNS}"

# Access application
curl http://${ALB_DNS}
```

### EC2 Instances (via Systems Manager)
```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]" \
  --output table

# Connect via SSM (no SSH key needed)
aws ssm start-session --target <instance-id>
```

### RDS Database
```bash
# From EC2 instance (after SSM connection)
mysql -h $(terraform output -raw rds_address) \
  -u admin \
  -p \
  -D appdb

# Get password from Secrets Manager (on your local machine)
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw rds_secret_arn) \
  --query SecretString \
  --output text | jq -r .password
```

---

## 💾 AWS Backup (PROD Only)

### Backup Schedule
- **Daily Backups**: 2:00 AM UTC, retained for 7 days
- **Monthly Backups**: 1st of month at 3:00 AM UTC, retained for 30 days

### View Backups
```bash
# List backup vault
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name $(terraform output -raw backup_vault_name)
```

### Restore from Backup
```bash
# Via AWS Console: AWS Backup → Backup vaults → Select vault → Restore
# Via CLI: Use aws backup start-restore-job
```

---

## 🔧 Common Operations

### Update Infrastructure
```bash
# Modify terraform.tfvars or module code
vim environments/dev/terraform.tfvars

# Plan changes
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Scale EC2 Instances
```bash
# Edit terraform.tfvars
ec2_instance_count = 3

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Upgrade RDS Instance Class
```bash
# Edit terraform.tfvars
rds_instance_class = "db.t3.large"

# Plan (check for downtime)
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply (may cause brief downtime)
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Enable VPC Flow Logs
```bash
# Edit terraform.tfvars
enable_vpc_flow_logs = true

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

---

## 🗑️ Destroy Infrastructure

### Destroy DEV Environment
```bash
# WARNING: This will delete ALL resources!
terraform destroy -var-file=environments/dev/terraform.tfvars

# Confirm with 'yes'
```

### Destroy with Safeguards (PROD)
```bash
# For PROD, first disable deletion protection
# Edit terraform.tfvars:
# Set: rds_multi_az = false (optional, to speed up)

# Then destroy
terraform destroy -var-file=environments/prod/terraform.tfvars
```

---

## 📈 Monitoring & Logging

### CloudWatch Logs
- **VPC Flow Logs**: `/aws/vpc/{environment}-vpc` (if enabled)
- **RDS Logs**: CloudWatch Logs Exports (error, general, slowquery)

### CloudWatch Metrics
- EC2: CPU, Network, Disk
- RDS: CPU, Connections, Storage, IOPS
- ALB: Request Count, Target Response Time, HTTP Errors

### Access Logs
```bash
# View VPC Flow Logs
aws logs tail /aws/vpc/infrastructure-dev --follow

# View RDS slow query log
aws logs tail /aws/rds/instance/infrastructure-dev-mysql/slowquery --follow
```

---

## 🐛 Troubleshooting

### Terraform Init Fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check S3 bucket exists
aws s3 ls s3://terraform-state-dev-${AWS_ACCOUNT_ID}

# Reconfigure backend
terraform init -reconfigure -backend-config=environments/dev/backend.tf
```

### EC2 Health Check Failing
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Check EC2 system logs
aws ec2 get-console-output --instance-id <instance-id>

# Connect via SSM to debug
aws ssm start-session --target <instance-id>
```

### RDS Connection Issues
```bash
# Verify RDS is running
aws rds describe-db-instances --db-instance-identifier <db-id>

# Check security group allows EC2
# Check from EC2 instance:
telnet <rds-endpoint> 3306

# Verify credentials in Secrets Manager
aws secretsmanager get-secret-value --secret-id <secret-arn>
```

### State Lock Issues
```bash
# If state is locked and you're sure no one else is running Terraform:
terraform force-unlock <lock-id>

# Check DynamoDB for locks
aws dynamodb scan --table-name terraform-state-lock-dev
```

---

## 💰 Cost Optimization Tips

### DEV Environment
- Use `t3.micro` or `t3.small` for EC2
- Use `db.t3.micro` for RDS
- Single AZ deployment
- Single NAT Gateway
- Disable unnecessary VPC Endpoints

### Shutdown Non-Production
```bash
# Stop EC2 instances during non-business hours
aws ec2 stop-instances --instance-ids $(terraform output -json ec2_instance_ids | jq -r '.[]')

# Stop RDS (note: Multi-AZ can't be stopped)
aws rds stop-db-instance --db-instance-identifier <db-id>
```

---

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## 🆘 Support

For issues or questions:
1. Check this documentation
2. Review Terraform plan output carefully
3. Check AWS CloudWatch logs
4. Review the module README files in `modules/` directory
