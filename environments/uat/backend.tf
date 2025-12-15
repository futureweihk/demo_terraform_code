# Backend Configuration for UAT Environment
# 
# IMPORTANT: Before using this backend configuration:
# 1. Create an S3 bucket: terraform-state-uat-<your-account-id>
# 2. Enable versioning on the S3 bucket
# 3. Enable encryption on the S3 bucket
# 4. Create a DynamoDB table: terraform-state-lock-uat
#    - Partition key: LockID (String)
#    - Billing mode: PAY_PER_REQUEST or PROVISIONED (1 RCU, 1 WCU)
#
# To initialize with this backend:
# terraform init -backend-config=environments/uat/backend.tf

terraform {
  backend "s3" {
    bucket         = "terraform-state-uat-REPLACE_WITH_ACCOUNT_ID"
    key            = "infrastructure/uat/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-uat"
  }
}
