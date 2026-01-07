# Terraform AWS Infrastructure - 開發指南

## 專案概覽
- **專案名稱**: terraform-aws-infrastructure
- **目的**: 提供可重用的 AWS 基礎設施 Terraform 模組
- **目標用戶**: 開源社群，支援 DEV/UAT/PROD 環境一鍵部署
- **支援平台**: Windows 和 Linux

---

## 架構設計

### 目錄結構


terraform-aws-infrastructure/├── README.md # 主要使用文檔├── CONTRIBUTING.md # 貢獻指南├── LICENSE # 開源協議├── .gitignore # Git 忽略檔案├── Jenkinsfile # Jenkins Pipeline 配置（可選）├── Makefile # Make 命令（可選）├── examples/ # 使用範例│ └── simple-deployment/│ ├── README.md│ └── example.tfvars├── environments/ # 環境特定配置│ ├── dev/│ │ ├── terraform.tfvars # DEV 環境變數│ │ ├── backend.tf # DEV State 後端配置│ │ └── README.md # DEV 環境說明│ ├── uat/│ │ ├── terraform.tfvars # UAT 環境變數│ │ ├── backend.tf # UAT State 後端配置│ │ └── README.md # UAT 環境說明│ └── prod/│ ├── terraform.tfvars # PROD 環境變數│ ├── backend.tf # PROD State 後端配置│ └── README.md # PROD 環境說明├── modules/ # Terraform 模組│ ├── network/ # VPC、Subnet、Routing│ │ ├── main.tf│ │ ├── variables.tf│ │ ├── outputs.tf│ │ ├── data.tf # Data sources│ │ └── README.md│ ├── endpoints/ # VPC Endpoints (私有端點)│ │ ├── main.tf│ │ ├── variables.tf│ │ ├── outputs.tf│ │ └── README.md│ ├── secrets/ # Secret Manager│ │ ├── main.tf│ │ ├── variables.tf│ │ ├── outputs.tf│ │ ├── random.tf # 隨機密碼生成│ │ └── README.md│ ├── database/ # RDS│ │ ├── main.tf│ │ ├── variables.tf│ │ ├── outputs.tf│ │ ├── security_groups.tf│ │ └── README.md│ ├── compute/ # EC2、ALB│ │ ├── main.tf│ │ ├── variables.tf│ │ ├── outputs.tf│ │ ├── user_data.tf # EC2 啟動腳本│ │ ├── security_groups.tf│ │ ├── alb.tf # ALB 配置│ │ └── README.md│ └── cdn/ # CloudFront│ ├── main.tf│ ├── variables.tf│ ├── outputs.tf│ └── README.md├── scripts/ # 部署腳本│ ├── 01-deploy-network.sh # Linux: 部署網路層│ ├── 01-deploy-network.ps1 # Windows: 部署網路層│ ├── 02-deploy-compute.sh # Linux: 部署計算層│ ├── 02-deploy-compute.ps1 # Windows: 部署計算層│ ├── helper-functions.sh # Linux: 輔助函數│ ├── helper-functions.ps1 # Windows: 輔助函數│ └── README.md # 腳本使用說明├── main.tf # 主要 Terraform 配置├── variables.tf # 全局變數定義├── outputs.tf # 全局輸出├── locals.tf # 本地變數計算├── data.tf # 全局 Data sources└── versions.tf # Terraform 和 Provider 版本
markdown
---

## 檔案清單與用途

### 根目錄檔案

#### 1. **README.md**
**用途**: 主要使用文檔，面向最終用戶
**必須包含內容**:
- 專案簡介
- 架構圖
- 快速開始指南
- 前置需求
- 部署步驟（3種方式）
  - 使用 Shell Scripts
  - 手動執行 Terraform
  - 使用 Jenkins Pipeline
- 環境說明 (DEV/UAT/PROD 差異)
- 變數配置說明
- 常見問題 (FAQ)
- 故障排除
- 授權資訊

#### 2. **CONTRIBUTING.md**
**用途**: 貢獻者指南
**必須包含內容**:
- 如何提交 Issue
- 如何提交 Pull Request
- 代碼風格指南
- 測試要求
- 文檔要求

#### 3. **LICENSE**
**用途**: 開源協議
**建議**: MIT 或 Apache 2.0

#### 4. **.gitignore**
**用途**: Git 忽略檔案
**必須包含**:


Terraform
.terraform/*.tfstate.tfstate..tfvars!.tfvars.example.terraform.lock.hcl
IDE
.vscode/.idea/
OS
.DS_StoreThumbs.db
Secrets
*.pem*.keysecrets/
#### 5. **main.tf**
**用途**: 主要 Terraform 配置，調用所有模組
**必須包含**:
- Provider 配置
- 模組調用順序:
  1. module "network"
  2. module "endpoints" (depends_on network)
  3. module "secrets"
  4. module "database" (depends_on network, secrets)
  5. module "compute" (depends_on network, database)
  6. module "cdn" (depends_on compute)

#### 6. **variables.tf**
**用途**: 全局變數定義
**必須包含變數**:
- environment (string): dev/uat/prod
- aws_region (string)
- az_count (number): 1 for DEV, 2 for UAT/PROD
- os_type (string): windows/linux
- vpc_cidr (string)
- instance_type (string)
- rds_instance_class (string)
- tags (map(string))

#### 7. **outputs.tf**
**用途**: 全局輸出
**必須包含輸出**:
- vpc_id
- subnet_ids
- alb_dns_name
- cloudfront_domain_name
- rds_endpoint
- ec2_instance_ids

#### 8. **locals.tf**
**用途**: 本地變數計算邏輯
**必須包含**:
- availability_zones (根據 az_count 計算)
- common_tags (合併環境標籤)
- 環境特定配置計算

#### 9. **data.tf**
**用途**: 全局 Data sources
**必須包含**:
- aws_availability_zones
- aws_caller_identity
- aws_ami (Windows)
- aws_ami (Linux)

#### 10. **versions.tf**
**用途**: Terraform 和 Provider 版本約束
**必須包含**:
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}



Modules 詳細規格
Module: network/
main.tf
用途: VPC、Subnet、Routing Table、Internet Gateway、NAT Gateway必須建立資源:
	•	aws_vpc
	•	aws_subnet (public/private，根據 az_count)
	•	aws_internet_gateway
	•	aws_nat_gateway (根據 az_count，1 個或 2 個)
	•	aws_route_table (public/private)
	•	aws_route_table_association
	•	aws_eip (for NAT Gateway)
variables.tf
必須包含變數:
	•	vpc_cidr
	•	environment
	•	az_count
	•	availability_zones
	•	enable_nat_gateway (bool)
	•	single_nat_gateway (bool，DEV 用)
	•	tags
outputs.tf
必須包含輸出:
	•	vpc_id
	•	public_subnet_ids
	•	private_subnet_ids
	•	nat_gateway_ids
	•	route_table_ids
README.md
必須說明:
	•	模組用途
	•	輸入變數說明
	•	輸出說明
	•	使用範例
	•	網路架構圖

Module: endpoints/
main.tf
用途: VPC Endpoints (S3, ECR, Secrets Manager, RDS 等)必須建立資源:
	•	aws_vpc_endpoint (S3 - Gateway type)
	•	aws_vpc_endpoint (Secrets Manager - Interface type)
	•	aws_vpc_endpoint (ECR API - Interface type)
	•	aws_vpc_endpoint (ECR DKR - Interface type)
	•	aws_vpc_endpoint (RDS - 如需要)
	•	aws_security_group (for interface endpoints)
variables.tf
必須包含變數:
	•	vpc_id
	•	private_subnet_ids
	•	environment
	•	tags
outputs.tf
必須包含輸出:
	•	endpoint_ids
	•	security_group_id
README.md
必須說明:
	•	為什麼需要 VPC Endpoints
	•	各 Endpoint 用途
	•	成本考量

Module: secrets/
main.tf
用途: Secret Manager 和隨機密碼生成必須建立資源:
	•	random_password (for RDS)
	•	aws_secretsmanager_secret
	•	aws_secretsmanager_secret_version
random.tf
用途: 隨機密碼生成邏輯必須包含:
hcl
resource "random_password" "rds_master_password" {
  length  = 32
  special = true
}


variables.tf
必須包含變數:
	•	environment
	•	rds_master_username
	•	tags
outputs.tf
必須包含輸出:
	•	secret_arn
	•	secret_name
	•	rds_password (sensitive)

Module: database/
main.tf
用途: RDS 實例必須建立資源:
	•	aws_db_subnet_group
	•	aws_db_instance (Multi-AZ 根據環境)
	•	aws_db_parameter_group (可選)
security_groups.tf
用途: RDS Security Group必須建立資源:
	•	aws_security_group (允許從 EC2 連接)
variables.tf
必須包含變數:
	•	vpc_id
	•	private_subnet_ids
	•	environment
	•	instance_class
	•	allocated_storage
	•	engine (postgres/mysql)
	•	engine_version
	•	multi_az (bool，PROD=true, DEV=false)
	•	secret_arn
	•	allowed_security_group_ids (EC2 SG)
outputs.tf
必須包含輸出:
	•	db_instance_id
	•	db_endpoint
	•	db_name
	•	security_group_id

Module: compute/
main.tf
用途: EC2 實例必須建立資源:
	•	aws_instance (根據 az_count)
	•	aws_iam_role (for EC2)
	•	aws_iam_instance_profile
	•	aws_iam_role_policy_attachment (SSM, Secrets Manager)
alb.tf
用途: Application Load Balancer必須建立資源:
	•	aws_lb
	•	aws_lb_target_group
	•	aws_lb_listener
	•	aws_lb_target_group_attachment
security_groups.tf
用途: EC2 和 ALB Security Groups必須建立資源:
	•	aws_security_group (EC2)
	•	aws_security_group (ALB)
	•	必須規則:
	◦	ALB: 允許 443 from CloudFront
	◦	EC2: 允許 HTTP/HTTPS from ALB
	◦	EC2: 允許 RDP(3389) 或 SSH(22) from 管理 IP
user_data.tf
用途: EC2 啟動腳本必須包含:
	•	條件判斷 Windows/Linux
	•	Windows: PowerShell script
	•	Linux: Bash script
	•	安裝必要軟件（如 CloudWatch Agent）
variables.tf
必須包含變數:
	•	vpc_id
	•	public_subnet_ids (for ALB)
	•	private_subnet_ids (for EC2)
	•	instance_type
	•	os_type (windows/linux)
	•	ami_id
	•	key_name (可選)
	•	db_endpoint
	•	secret_arn
	•	environment
outputs.tf
必須包含輸出:
	•	instance_ids
	•	private_ips
	•	alb_dns_name
	•	alb_arn
	•	target_group_arn

Module: cdn/
main.tf
用途: CloudFront Distribution必須建立資源:
	•	aws_cloudfront_distribution
	•	aws_cloudfront_origin_access_identity (如需要)
variables.tf
必須包含變數:
	•	alb_dns_name
	•	environment
	•	ssl_certificate_arn (可選，用自訂域名)
	•	tags
outputs.tf
必須包含輸出:
	•	distribution_id
	•	domain_name
	•	distribution_arn

Environments 配置
environments/dev/terraform.tfvars
必須包含:
hcl
environment        = "dev"
aws_region         = "ap-east-1"
az_count           = 1
os_type            = "linux"
instance_type      = "t3.medium"
rds_instance_class = "db.t3.small"
vpc_cidr           = "10.0.0.0/16"

# RDS 配置
rds_multi_az          = false
rds_allocated_storage = 20

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "Infrastructure"
}


environments/dev/backend.tf
必須包含:
hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-<account-id>"
    key            = "infrastructure/terraform.tfstate"
    region         = "ap-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dev"
  }
}


environments/dev/README.md
必須說明:
	•	DEV 環境特性
	•	與其他環境的差異
	•	部署注意事項

Scripts 詳細規格
scripts/01-deploy-network.sh
用途: 部署網路層 (VPC, Subnet, Endpoints)
必須功能:
	1	接收環境參數 (DEV/UAT/PROD)
	2	驗證環境參數
	3	切換到對應環境目錄
	4	執行 terraform init
	5	執行 terraform plan -target=module.network -target=module.endpoints
	6	顯示關鍵 outputs
	7	詢問用戶確認
	8	執行 terraform apply -target=module.network -target=module.endpoints
	9	顯示部署結果
腳本範本:
bash
#!/bin/bash
set -e

# 引入輔助函數
source "$(dirname "$0")/helper-functions.sh"

# 主函數
main() {
    # 1. 解析參數
    # 2. 驗證環境
    # 3. 切換目錄
    # 4. Terraform init
    # 5. Terraform plan (targeted)
    # 6. 顯示 outputs
    # 7. 用戶確認
    # 8. Terraform apply (targeted)
}

main "$@"



scripts/01-deploy-network.ps1
用途: Windows 版本的網路層部署
必須功能: 與 .sh 版本相同
腳本範本:
powershell
#Requires -Version 5.1

# 引入輔助函數
. "$PSScriptRoot\helper-functions.ps1"

function Main {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("dev","uat","prod")]
        [string]$Environment
    )
    
    # 實現與 .sh 相同邏輯
}

Main @args



scripts/02-deploy-compute.sh
用途: 部署計算層 (EC2, RDS, ALB, CloudFront)
必須功能:
	1	檢查網路層是否已部署
	2	讀取網路層 outputs
	3	執行 terraform plan (完整)
	4	顯示資源清單
	5	用戶確認
	6	執行 terraform apply
	7	顯示最終 outputs (ALB DNS, CloudFront Domain 等)

scripts/helper-functions.sh
用途: 共用輔助函數
必須包含函數:
bash
# 顯示彩色訊息
print_info() { }
print_success() { }
print_error() { }
print_warning() { }

# 驗證環境
validate_environment() { }

# 檢查 Terraform 安裝
check_terraform() { }

# 檢查 AWS CLI
check_aws_cli() { }

# 用戶確認
confirm_action() { }

# 顯示 Terraform outputs
display_outputs() { }



scripts/README.md
必須說明:
	•	各腳本用途
	•	使用方法
	•	參數說明
	•	範例
	•	常見錯誤處理

Jenkins Pipeline 規格
Jenkinsfile
用途: Jenkins 自動化部署
必須包含 Stages:
	1	Checkout: 拉取代碼
	2	Validate: 檢查 Terraform 語法
	3	Plan Network: 計劃網路層
	4	Approve Network: 人工批准
	5	Apply Network: 部署網路層
	6	Plan Compute: 計劃計算層
	7	Approve Compute: 人工批准
	8	Apply Compute: 部署計算層
	9	Display Outputs: 顯示結果
必須包含 Parameters:
	•	Environment (Choice: dev/uat/prod)
	•	OS Type (Choice: windows/linux)
	•	Auto Approve (Boolean, 預設 false)
腳本範本:
groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'uat', 'prod'])
        choice(name: 'OS_TYPE', choices: ['linux', 'windows'])
        booleanParam(name: 'AUTO_APPROVE', defaultValue: false)
    }
    
    stages {
        // 實現各階段
    }
    
    post {
        success { }
        failure { }
    }
}



Makefile 規格 (可選)
用途: 簡化命令執行
必須包含 Targets:
makefile
.PHONY: help init plan-network apply-network plan-compute apply-compute destroy

help:
	@echo "Available targets:"
	@echo "  init ENV=<dev|uat|prod>          - Initialize Terraform"
	@echo "  plan-network ENV=<env>           - Plan network layer"
	@echo "  apply-network ENV=<env>          - Apply network layer"
	@echo "  plan-compute ENV=<env>           - Plan compute layer"
	@echo "  apply-compute ENV=<env>          - Apply compute layer"
	@echo "  destroy ENV=<env>                - Destroy all resources"

init:
	# 實現邏輯

plan-network:
	# 實現邏輯

apply-network:
	# 實現邏輯



變數設計規範
命名規則
	•	使用 snake_case
	•	環境相關變數加 env_ 前綴
	•	布林值用 enable_ 或 is_ 前綴
	•	複數用 _list 或 _ids 後綴
必須變數列表
全局變數 (variables.tf)
hcl
variable "environment" {
  type        = string
  description = "Environment name (dev/uat/prod)"
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, uat, or prod"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-east-1"
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones (1 for dev, 2 for uat/prod)"
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "AZ count must be between 1 and 3"
  }
}

variable "os_type" {
  type        = string
  description = "Operating system type (windows/linux)"
  validation {
    condition     = contains(["windows", "linux"], var.os_type)
    error_message = "OS type must be windows or linux"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.small"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}



Outputs 設計規範
命名規則
	•	使用描述性名稱
	•	包含資源類型
	•	敏感資訊標記 sensitive = true
必須輸出列表
全局輸出 (outputs.tf)
hcl
output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.network.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.network.private_subnet_ids
  description = "Private subnet IDs"
}

output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "Application Load Balancer DNS name"
}

output "cloudfront_domain_name" {
  value       = module.cdn.domain_name
  description = "CloudFront distribution domain name"
}

output "rds_endpoint" {
  value       = module.database.db_endpoint
  description = "RDS endpoint"
  sensitive   = true
}

output "ec2_instance_ids" {
  value       = module.compute.instance_ids
  description = "EC2 instance IDs"
}

output "deployment_summary" {
  value = {
    environment         = var.environment
    region              = var.aws_region
    az_count            = var.az_count
    os_type             = var.os_type
    vpc_id              = module.network.vpc_id
    alb_dns             = module.compute.alb_dns_name
    cloudfront_domain   = module.cdn.domain_name
  }
  description = "Deployment summary"
}



依賴關係規範
模組部署順序
less
1. network (獨立)
2. endpoints (depends_on: network)
3. secrets (獨立)
4. database (depends_on: network, secrets)
5. compute (depends_on: network, database)
6. cdn (depends_on: compute)


資源依賴關係
	•	RDS 必須等待 Secret Manager 建立完成
	•	EC2 必須等待 RDS 可用
	•	ALB 必須等待 EC2 註冊
	•	CloudFront 必須等待 ALB 建立

測試規範
必須測試場景
	1	DEV 環境 (1 AZ, Linux)
	2	DEV 環境 (1 AZ, Windows)
	3	UAT 環境 (2 AZ, Linux)
	4	PROD 環境 (2 AZ, Windows)
測試檢查點
	•	VPC 和 Subnet 正確建立
	•	NAT Gateway 數量符合預期
	•	VPC Endpoints 正常運作
	•	RDS 可從 EC2 連接
	•	ALB Health Check 通過
	•	CloudFront 可訪問
	•	Secret Manager 密碼正確輪換

文檔規範
每個模組必須包含 README.md
必須章節:
	1	概述: 模組用途
	2	架構圖: 視覺化展示
	3	輸入變數: 表格形式列出所有變數
	4	輸出: 表格形式列出所有輸出
	5	使用範例: 完整可執行的範例
	6	注意事項: 成本、安全性考量
	7	故障排除: 常見問題
變數表格格式:
markdown
| 名稱 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| vpc_id | string | 是 | - | VPC ID |



安全性規範
必須實現
	1	Secret Manager: 所有密碼存儲
	2	加密:
	◦	RDS: 啟用加密
	◦	S3 State: 啟用加密
	◦	EBS: 啟用加密
	3	IAM: 最小權限原則
	4	Security Groups: 明確定義規則，避免 0.0.0.0/0
	5	VPC Endpoints: 避免流量經過公網
禁止事項
	•	硬編碼密碼
	•	在代碼中暴露 Access Key
	•	過度開放的 Security Group 規則
	•	將 .tfstate 提交到 Git

成本優化規範
DEV 環境
	•	單 AZ
	•	單 NAT Gateway
	•	RDS: 非 Multi-AZ
	•	小型實例類型
UAT/PROD 環境
	•	雙 AZ (或更多)
	•	每個 AZ 一個 NAT Gateway
	•	RDS: Multi-AZ
	•	合適的實例類型
標籤策略
所有資源必須包含:
hcl
tags = {
  Environment = var.environment
  ManagedBy   = "Terraform"
  Project     = "Infrastructure"
  CostCenter  = "IT"
}



Git 工作流程規範
分支策略
	•	main: 穩定版本
	•	develop: 開發版本
	•	feature/*: 功能分支
	•	hotfix/*: 緊急修復
Commit 訊息格式

<type>(<scope>): <subject>

<body>

<footer>


Type:
	•	feat: 新功能
	•	fix: 修復
	•	docs: 文檔
	•	refactor: 重構
	•	test: 測試
範例:

feat(network): add VPC endpoints support

- Add S3 gateway endpoint
- Add Secrets Manager interface endpoint
- Update security groups

Closes #123



版本發布規範
語義化版本 (Semantic Versioning)
	•	MAJOR: 不相容的 API 變更
	•	MINOR: 新增向後相容功能
	•	PATCH: 向後相容的錯誤修復
發布檢查清單
	•	更新 CHANGELOG.md
	•	測試所有環境
	•	更新文檔
	•	建立 Git Tag
	•	發布 GitHub Release

AI 建立程式碼指令模板
建立模組指令
json
請根據以下規格建立 Terraform 模組:

模組名稱: [network/endpoints/compute/database/cdn/secrets]
模組路徑: modules/[module_name]/

必須包含檔案:
- main.tf: [具體資源列表]
- variables.tf: [變數列表]
- outputs.tf: [輸出列表]
- README.md: [文檔要求]

技術要求:
- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- [其他具體要求]

請參考本專案的變數命名規範、輸出規範、文檔規範。


建立腳本指令

請建立 [01-deploy-network.sh/02-deploy-compute.sh] 腳本:

功能要求:
1. [具體功能列表]
2. [錯誤處理要求]
3. [用戶互動要求]

技術要求:
- Bash >= 4.0
- 引用 helper-functions.sh
- 包含完整錯誤處理
- 彩色輸出支援

請包含詳細註釋。


建立文檔指令

請建立 [README.md/CONTRIBUTING.md/模組README] 文檔:

目標讀者: [開源用戶/貢獻者/開發者]

必須包含章節:
1. [章節列表]
2. [具體內容要求]

格式要求:
- Markdown 格式
- 包含程式碼範例
- 包含表格（變數、輸出）
- 包含故障排除章節



檢查清單
開發完成前檢查
	•	所有模組包含完整的 main.tf, variables.tf, outputs.tf, README.md
	•	所有環境配置檔案完整 (dev/uat/prod)
	•	Shell 和 PowerShell 腳本都已實現
	•	Jenkinsfile 測試通過
	•	所有文檔完整無誤
	•	通過 terraform fmt 和 terraform validate
	•	通過所有測試場景
	•	敏感資訊已移除
	•	.gitignore 配置正確
發布前檢查
	•	README.md 完整
	•	LICENSE 檔案存在
	•	CHANGELOG.md 更新
	•	範例程式碼可執行
	•	所有連結有效
	•	版本號正確
	•	Git tag 建立

附錄
推薦工具
	•	Terraform: >= 1.5.0
	•	AWS CLI: >= 2.0
	•	tfenv: Terraform 版本管理
	•	pre-commit: Git hook 自動化
	•	tflint: Terraform Linter
	•	checkov: 安全掃描工具
參考資源
	•	Terraform AWS Provider 文檔
	•	AWS Well-Architected Framework
	•	Terraform Best Practices
常見問題預設答案
Q: 為什麼要分兩階段部署？A: 第一階段部署網路層讓用戶確認基礎設施配置正確，避免後續資源建立在錯誤的網路環境中。
Q: DEV 環境可以用 2 個 AZ 嗎？A: 可以，修改 terraform.tfvars 中的 az_count = 2 即可。
Q: 如何更換 AWS Region？A: 修改 terraform.tfvars 中的 aws_region，並重新執行 terraform init。
Q: 如何銷毀環境？A: 執行 terraform destroy，建議先備份重要數據。

專案時間線 (參考)
Phase 1: 核心模組 (Week 1-2)
	•	network 模組
	•	endpoints 模組
	•	secrets 模組
Phase 2: 計算與數據庫 (Week 3-4)
	•	database 模組
	•	compute 模組
	•	cdn 模組
Phase 3: 自動化腳本 (Week 5)
	•	Shell 腳本
	•	PowerShell 腳本
	•	Jenkinsfile
Phase 4: 文檔與測試 (Week 6)
	•	所有 README
	•	測試所有場景
	•	優化和修復
Phase 5: 發布準備 (Week 7)
	•	最終檢查
	•	建立範例
	•	發布到 GitHub
