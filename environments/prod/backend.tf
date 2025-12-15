# Backend Configuration for PROD Environment
# 
# IMPORTANT: Before using this backend configuration:
# 1. Create an S3 bucket: terraform-state-prod-<your-account-id>
# 2. Enable versioning on the S3 bucket
# 3. Enable encryption on the S3 bucket
# 4. Enable MFA delete for additional security
# 5. Create a DynamoDB table: terraform-state-lock-prod
#    - Partition key: LockID (String)
#    - Billing mode: PAY_PER_REQUEST or PROVISIONED (1 RCU, 1 WCU)
# 6. Enable Point-in-Time Recovery on DynamoDB table
#
# To initialize with this backend:
# terraform init -backend-config=environments/prod/backend.tf

terraform {
  backend "s3" {
    bucket         = "terraform-state-prod-REPLACE_WITH_ACCOUNT_ID"
    key            = "infrastructure/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
  }
}
