# Backend Configuration for DEV Environment
# 
# IMPORTANT: Before using this backend configuration:
# 1. Create an S3 bucket: terraform-state-dev-<your-account-id>
# 2. Enable versioning on the S3 bucket
# 3. Enable encryption on the S3 bucket
# 4. Create a DynamoDB table: terraform-state-lock-dev
#    - Partition key: LockID (String)
#    - Billing mode: PAY_PER_REQUEST or PROVISIONED (1 RCU, 1 WCU)
#
# To initialize with this backend:
# terraform init -backend-config=environments/dev/backend.tf

terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-170365176936"
    key            = "infrastructure/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dev"
    
    # Optional: Enable state locking
    # dynamodb_table = "terraform-state-lock-dev"
  }
}
