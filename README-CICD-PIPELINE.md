# Terraform AWS Infrastructure - CI/CD Pipeline Guide

## 📋 Overview

This document provides a comprehensive guide for **Pipeline Engineers** to integrate Terraform infrastructure deployment with Jenkins (CI) and Ansible Automation Platform (AAP) as CD orchestrator.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CI/CD WORKFLOW                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   GitHub    │─────▶│   Jenkins    │─────▶│  Ansible AAP    │
│  (Source)   │      │     (CI)     │      │     (CD)        │
└─────────────┘      └──────────────┘      └─────────────────┘
                            │                       │
                            ▼                       ▼
                     ┌─────────────┐        ┌──────────────┐
                     │ Terraform   │        │   AWS        │
                     │ Plan/Lint   │        │ Resources    │
                     └─────────────┘        └──────────────┘
```

### Workflow Summary

1. **Developer** pushes code to GitHub
2. **Jenkins** (CI) automatically:
   - Validates Terraform syntax
   - Runs security scans (tfsec, checkov)
   - Creates Terraform plan
   - Archives plan as artifact
3. **Ansible AAP** (CD) orchestrates:
   - Deploys infrastructure via Terraform
   - Configures deployed resources
   - Runs post-deployment validation
   - Updates inventory systems

---

## 🏗️ Infrastructure Components

### Terraform Modules

| Module | Purpose | Resources Created |
|--------|---------|-------------------|
| **network** | VPC Infrastructure | VPC, Subnets, NAT Gateway, IGW, Route Tables |
| **endpoints** | VPC Endpoints | S3, Secrets Manager, ECR, RDS Endpoints |
| **kms** | Encryption Keys | KMS keys for EC2 and RDS encryption |
| **secrets** | Secret Management | Secrets Manager for DB credentials |
| **database** | RDS MySQL | RDS instance, subnet groups, security groups |
| **compute** | EC2 & ALB | EC2 instances, Application Load Balancer |
| **backup** | AWS Backup | Backup vault, plans, and policies (PROD only) |

### Supported Environments

| Environment | AZs | NAT Gateways | Multi-AZ RDS | AWS Backup | Purpose |
|-------------|-----|--------------|--------------|------------|---------|
| **DEV** | 1 | 1 | ❌ | ❌ | Development/Testing |
| **UAT** | 2 | 2 | ✅ | ❌ | User Acceptance Testing |
| **PROD** | 2 | 2 | ✅ | ✅ | Production |

---

## 🔧 Jenkins CI Pipeline

### Prerequisites

#### Jenkins Server Requirements
- Jenkins 2.400+
- Installed Plugins:
  - Pipeline
  - Git
  - Credentials Binding
  - AWS Steps
  - Ansible
  - Email Extension
  - Slack Notification (optional)

#### Required Tools on Jenkins Agent
```bash
# Terraform
terraform --version  # >= 1.5.0

# AWS CLI
aws --version  # >= 2.0

# Security scanning tools
tfsec --version
checkov --version

# Git
git --version
```

#### Jenkins Credentials Setup
Configure the following credentials in Jenkins:

| Credential ID | Type | Description |
|--------------|------|-------------|
| `aws-credentials` | AWS Credentials | AWS Access Key & Secret for Terraform |
| `github-token` | Secret Text | GitHub personal access token |
| `ansible-tower-token` | Secret Text | Ansible AAP API token |
| `slack-webhook` | Secret Text | Slack webhook URL (optional) |

### Jenkinsfile Configuration

Create `Jenkinsfile` in repository root:

```groovy
pipeline {
    agent {
        label 'terraform-agent'
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'uat', 'prod'],
            description: 'Target environment'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action'
        )
        booleanParam(
            name: 'SKIP_SECURITY_SCAN',
            defaultValue: false,
            description: 'Skip security scanning (tfsec/checkov)'
        )
        booleanParam(
            name: 'TRIGGER_ANSIBLE',
            defaultValue: true,
            description: 'Trigger Ansible AAP after successful apply'
        )
    }
    
    environment {
        AWS_REGION = 'ap-southeast-1'
        TF_VERSION = '1.5.0'
        ANSIBLE_AAP_URL = 'https://ansible-tower.company.com'
        PROJECT_NAME = 'terraform-aws-infrastructure'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Validate') {
            steps {
                script {
                    sh '''
                        cd terraform-aws-infrastructure
                        terraform fmt -check -recursive
                        terraform init -backend=false
                        terraform validate
                    '''
                }
            }
        }
        
        stage('Security Scan') {
            when {
                expression { params.SKIP_SECURITY_SCAN == false }
            }
            parallel {
                stage('tfsec') {
                    steps {
                        sh '''
                            cd terraform-aws-infrastructure
                            tfsec . --format json --out tfsec-report.json || true
                        '''
                        archiveArtifacts artifacts: 'terraform-aws-infrastructure/tfsec-report.json'
                    }
                }
                stage('checkov') {
                    steps {
                        sh '''
                            cd terraform-aws-infrastructure
                            checkov -d . --output json --output-file checkov-report.json || true
                        '''
                        archiveArtifacts artifacts: 'terraform-aws-infrastructure/checkov-report.json'
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    sh '''
                        cd terraform-aws-infrastructure
                        terraform init \
                            -backend-config=environments/${ENVIRONMENT}/backend.tf \
                            -upgrade
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    sh '''
                        cd terraform-aws-infrastructure
                        terraform plan \
                            -var-file=environments/${ENVIRONMENT}/terraform.tfvars \
                            -out=tfplan-${ENVIRONMENT}-${GIT_COMMIT_SHORT}.tfplan
                    '''
                }
                
                // Archive the plan
                archiveArtifacts artifacts: "terraform-aws-infrastructure/tfplan-${params.ENVIRONMENT}-*.tfplan"
            }
        }
        
        stage('Approval') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                script {
                    def approvalMessage = """
                    Environment: ${params.ENVIRONMENT}
                    Action: ${params.ACTION}
                    Git Commit: ${env.GIT_COMMIT_SHORT}
                    
                    Review the plan above and approve to proceed.
                    """
                    
                    timeout(time: 30, unit: 'MINUTES') {
                        input message: approvalMessage, ok: 'Proceed'
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    sh '''
                        cd terraform-aws-infrastructure
                        terraform apply \
                            -auto-approve \
                            tfplan-${ENVIRONMENT}-${GIT_COMMIT_SHORT}.tfplan
                    '''
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    sh '''
                        cd terraform-aws-infrastructure
                        terraform destroy \
                            -var-file=environments/${ENVIRONMENT}/terraform.tfvars \
                            -auto-approve
                    '''
                }
            }
        }
        
        stage('Export Outputs') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    sh '''
                        cd terraform-aws-infrastructure
                        terraform output -json > terraform-outputs-${ENVIRONMENT}.json
                    '''
                }
                archiveArtifacts artifacts: "terraform-aws-infrastructure/terraform-outputs-*.json"
            }
        }
        
        stage('Trigger Ansible AAP') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.TRIGGER_ANSIBLE == true }
                }
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'ansible-tower-token', variable: 'TOWER_TOKEN')]) {
                        sh """
                            curl -X POST \
                                -H "Authorization: Bearer \${TOWER_TOKEN}" \
                                -H "Content-Type: application/json" \
                                -d '{"extra_vars": {"environment": "${params.ENVIRONMENT}", "git_commit": "${env.GIT_COMMIT_SHORT}"}}' \
                                ${ANSIBLE_AAP_URL}/api/v2/job_templates/\${JOB_TEMPLATE_ID}/launch/
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                def message = """
                ✅ Terraform ${params.ACTION} completed successfully
                Environment: ${params.ENVIRONMENT}
                Git Commit: ${env.GIT_COMMIT_SHORT}
                """
                
                // Send notification (email, Slack, etc.)
                echo message
            }
        }
        failure {
            script {
                def message = """
                ❌ Terraform ${params.ACTION} failed
                Environment: ${params.ENVIRONMENT}
                Git Commit: ${env.GIT_COMMIT_SHORT}
                """
                
                // Send notification
                echo message
            }
        }
        always {
            cleanWs()
        }
    }
}
```

### Jenkins Pipeline Setup Steps

1. **Create New Pipeline Job**
   ```
   Jenkins Dashboard → New Item → Pipeline → OK
   ```

2. **Configure Pipeline**
   - **Name**: `terraform-aws-infrastructure-pipeline`
   - **Pipeline Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your GitHub repository URL
   - **Credentials**: Select `github-token`
   - **Branch**: `*/main`
   - **Script Path**: `Jenkinsfile`

3. **Configure Build Triggers**
   - ✅ GitHub hook trigger for GITScm polling
   - ✅ Poll SCM: `H/5 * * * *` (every 5 minutes as backup)

4. **Save and Test**
   ```
   Build with Parameters → Select DEV → plan → Build
   ```

---

## 🤖 Ansible AAP (Automation Platform) Integration

### Ansible AAP Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Ansible Automation Platform                │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐        ┌──────────────────┐           │
│  │   Job Template  │───────▶│   Playbook       │           │
│  │   (Workflow)    │        │   (terraform.yml)│           │
│  └─────────────────┘        └──────────────────┘           │
│          │                           │                       │
│          ▼                           ▼                       │
│  ┌─────────────────┐        ┌──────────────────┐           │
│  │   Inventory     │        │   AWS Resources  │           │
│  │   (Dynamic)     │        │   Configuration  │           │
│  └─────────────────┘        └──────────────────┘           │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Ansible AAP Prerequisites

#### Required Collections
```yaml
# requirements.yml
collections:
  - name: amazon.aws
    version: ">=6.0.0"
  - name: community.general
    version: ">=7.0.0"
  - name: ansible.posix
    version: ">=1.5.0"
```

Install collections:
```bash
ansible-galaxy collection install -r requirements.yml
```

#### Credentials in AAP
Configure these credentials in Ansible AAP:

| Credential Name | Type | Purpose |
|----------------|------|---------|
| `aws-terraform-creds` | Amazon Web Services | AWS access for Terraform |
| `github-repo-creds` | Source Control | Access to Terraform repository |
| `vault-password` | Vault | Ansible Vault password |

### Ansible Playbook Structure

Create the following directory structure:

```
ansible/
├── ansible.cfg
├── requirements.yml
├── inventory/
│   ├── dev.yml
│   ├── uat.yml
│   └── prod.yml
├── group_vars/
│   ├── all.yml
│   ├── dev.yml
│   ├── uat.yml
│   └── prod.yml
├── roles/
│   ├── terraform-deploy/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   ├── templates/
│   │   └── defaults/
│   │       └── main.yml
│   └── post-deployment/
│       ├── tasks/
│       │   └── main.yml
│       └── handlers/
│           └── main.yml
└── playbooks/
    ├── deploy-infrastructure.yml
    ├── configure-resources.yml
    └── rollback-infrastructure.yml
```

### Main Ansible Playbook

**`playbooks/deploy-infrastructure.yml`**:

```yaml
---
- name: Deploy AWS Infrastructure with Terraform
  hosts: localhost
  gather_facts: yes
  
  vars:
    terraform_repo: "https://github.com/your-org/terraform-aws-infrastructure.git"
    terraform_branch: "main"
    terraform_workspace: "{{ environment }}"
    terraform_dir: "/tmp/terraform-{{ environment }}-{{ ansible_date_time.epoch }}"
    
  tasks:
    - name: Display deployment information
      debug:
        msg: |
          Starting Terraform deployment
          Environment: {{ environment }}
          Terraform Workspace: {{ terraform_workspace }}
          Git Commit: {{ git_commit | default('latest') }}
    
    - name: Clone Terraform repository
      git:
        repo: "{{ terraform_repo }}"
        dest: "{{ terraform_dir }}"
        version: "{{ git_commit | default('HEAD') }}"
        force: yes
    
    - name: Set AWS credentials
      set_fact:
        aws_access_key: "{{ lookup('env', 'AWS_ACCESS_KEY_ID') }}"
        aws_secret_key: "{{ lookup('env', 'AWS_SECRET_ACCESS_KEY') }}"
    
    - name: Initialize Terraform
      command: terraform init -backend-config=environments/{{ environment }}/backend.tf
      args:
        chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
      environment:
        AWS_ACCESS_KEY_ID: "{{ aws_access_key }}"
        AWS_SECRET_ACCESS_KEY: "{{ aws_secret_key }}"
        AWS_DEFAULT_REGION: "{{ aws_region }}"
    
    - name: Select Terraform workspace
      command: terraform workspace select {{ terraform_workspace }}
      args:
        chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
      environment:
        AWS_ACCESS_KEY_ID: "{{ aws_access_key }}"
        AWS_SECRET_ACCESS_KEY: "{{ aws_secret_key }}"
        AWS_DEFAULT_REGION: "{{ aws_region }}"
      ignore_errors: yes
    
    - name: Create Terraform workspace if it doesn't exist
      command: terraform workspace new {{ terraform_workspace }}
      args:
        chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
      environment:
        AWS_ACCESS_KEY_ID: "{{ aws_access_key }}"
        AWS_SECRET_ACCESS_KEY: "{{ aws_secret_key }}"
        AWS_DEFAULT_REGION: "{{ aws_region }}"
      when: terraform_workspace_result is failed
    
    - name: Terraform plan
      command: >
        terraform plan
        -var-file=environments/{{ environment }}/terraform.tfvars
        -out=tfplan
      args:
        chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
      environment:
        AWS_ACCESS_KEY_ID: "{{ aws_access_key }}"
        AWS_SECRET_ACCESS_KEY: "{{ aws_secret_key }}"
        AWS_DEFAULT_REGION: "{{ aws_region }}"
      register: terraform_plan_output
    
    - name: Display Terraform plan
      debug:
        var: terraform_plan_output.stdout_lines
    
    - name: Terraform apply
      command: terraform apply -auto-approve tfplan
      args:
        chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
      environment:
        AWS_ACCESS_KEY_ID: "{{ aws_access_key }}"
        AWS_SECRET_ACCESS_KEY: "{{ aws_secret_key }}"
        AWS_DEFAULT_REGION: "{{ aws_region }}"
      register: terraform_apply_output
    
    - name: Get Terraform outputs
      command: terraform output -json
      args:
        chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
      environment:
        AWS_ACCESS_KEY_ID: "{{ aws_access_key }}"
        AWS_SECRET_ACCESS_KEY: "{{ aws_secret_key }}"
        AWS_DEFAULT_REGION: "{{ aws_region }}"
      register: terraform_outputs
    
    - name: Save Terraform outputs to file
      copy:
        content: "{{ terraform_outputs.stdout }}"
        dest: "/tmp/terraform-outputs-{{ environment }}.json"
    
    - name: Parse Terraform outputs
      set_fact:
        tf_outputs: "{{ terraform_outputs.stdout | from_json }}"
    
    - name: Display deployment summary
      debug:
        msg: |
          ✅ Infrastructure deployment completed successfully!
          
          Environment: {{ environment }}
          Region: {{ aws_region }}
          VPC ID: {{ tf_outputs.vpc_id.value }}
          ALB DNS: {{ tf_outputs.alb_dns_name.value }}
          RDS Endpoint: {{ tf_outputs.rds_endpoint.value }}
    
    - name: Update dynamic inventory
      uri:
        url: "{{ ansible_tower_url }}/api/v2/inventories/{{ inventory_id }}/update_inventory_sources/"
        method: POST
        headers:
          Authorization: "Bearer {{ ansible_tower_token }}"
        status_code: 202
      when: update_inventory | default(true)
    
    - name: Cleanup temporary directory
      file:
        path: "{{ terraform_dir }}"
        state: absent
      when: cleanup_temp_dir | default(true)

- name: Configure deployed resources
  hosts: aws_ec2
  gather_facts: yes
  become: yes
  
  roles:
    - post-deployment
```

### Post-Deployment Configuration Role

**`roles/post-deployment/tasks/main.yml`**:

```yaml
---
- name: Wait for EC2 instances to be ready
  wait_for_connection:
    timeout: 300
    delay: 10

- name: Update system packages
  package:
    name: '*'
    state: latest
  when: ansible_os_family == "RedHat"

- name: Install required packages
  package:
    name:
      - git
      - curl
      - wget
      - vim
    state: present

- name: Configure CloudWatch agent
  include_tasks: configure-cloudwatch.yml
  when: enable_cloudwatch | default(true)

- name: Deploy application
  include_tasks: deploy-application.yml
  when: deploy_app | default(false)

- name: Run health checks
  include_tasks: health-check.yml
```

### Ansible AAP Job Template Configuration

1. **Create Project**
   - **Name**: `Terraform AWS Infrastructure`
   - **Organization**: Your organization
   - **SCM Type**: Git
   - **SCM URL**: Your Ansible repository
   - **SCM Branch**: `main`
   - **SCM Update Options**: ✅ Update on Launch

2. **Create Inventory**
   - **Name**: `AWS Dynamic Inventory - {{ environment }}`
   - **Organization**: Your organization
   - **Add Inventory Source**:
     - **Source**: Amazon EC2
     - **Credential**: `aws-terraform-creds`
     - **Regions**: `ap-southeast-1`
     - **Instance Filters**: `tag:Environment={{ environment }}`
     - **Update Options**: ✅ Update on Launch

3. **Create Job Template**
   - **Name**: `Deploy Infrastructure - {{ environment }}`
   - **Job Type**: Run
   - **Inventory**: `AWS Dynamic Inventory - {{ environment }}`
   - **Project**: `Terraform AWS Infrastructure`
   - **Playbook**: `playbooks/deploy-infrastructure.yml`
   - **Credentials**: 
     - `aws-terraform-creds`
     - `github-repo-creds`
   - **Extra Variables**:
     ```yaml
     environment: dev
     aws_region: ap-southeast-1
     terraform_repo: https://github.com/your-org/terraform-aws-infrastructure.git
     ```
   - **Options**:
     - ✅ Enable Privilege Escalation
     - ✅ Enable Fact Cache

4. **Create Workflow Template** (Recommended)
   - **Name**: `Full Infrastructure Deployment - {{ environment }}`
   - **Workflow Steps**:
     1. Deploy Infrastructure (Job Template)
     2. Wait for Resources (Approval Node - 5 min)
     3. Configure Resources (Job Template)
     4. Run Health Checks (Job Template)
     5. Send Notification (Job Template)

---

## 🔄 Complete CI/CD Workflow

### End-to-End Process

```
┌────────────────────────────────────────────────────────────────────┐
│                    COMPLETE CI/CD WORKFLOW                          │
└────────────────────────────────────────────────────────────────────┘

1. Developer commits code to GitHub
   └─▶ Push to main/feature branch
   
2. GitHub webhook triggers Jenkins
   └─▶ Jenkins starts CI pipeline
   
3. Jenkins CI Pipeline
   ├─▶ Checkout code
   ├─▶ Validate Terraform syntax
   ├─▶ Run security scans (tfsec, checkov)
   ├─▶ Terraform init
   ├─▶ Terraform plan
   ├─▶ Archive plan artifact
   └─▶ Wait for approval (manual gate)
   
4. Approved → Jenkins triggers Ansible AAP
   └─▶ Pass environment & commit info
   
5. Ansible AAP CD Pipeline
   ├─▶ Clone Terraform repository
   ├─▶ Initialize Terraform
   ├─▶ Apply Terraform plan
   ├─▶ Retrieve Terraform outputs
   ├─▶ Update dynamic inventory
   └─▶ Configure deployed resources
   
6. Post-Deployment
   ├─▶ Install applications
   ├─▶ Configure monitoring
   ├─▶ Run health checks
   └─▶ Send notifications
```

### Deployment Commands

#### Via Jenkins UI
1. Navigate to Jenkins job
2. Click "Build with Parameters"
3. Select:
   - Environment: `dev`/`uat`/`prod`
   - Action: `plan`/`apply`/`destroy`
4. Click "Build"

#### Via Jenkins CLI
```bash
java -jar jenkins-cli.jar \
  -s http://jenkins.company.com:8080/ \
  -auth admin:token \
  build terraform-aws-infrastructure-pipeline \
  -p ENVIRONMENT=dev \
  -p ACTION=apply \
  -p TRIGGER_ANSIBLE=true
```

#### Via Ansible AAP UI
1. Navigate to Templates
2. Select "Deploy Infrastructure - dev"
3. Click "Launch"
4. Review extra variables
5. Click "Launch" to confirm

#### Via Ansible AAP CLI (tower-cli/awx)
```bash
awx job_templates launch \
  --name="Deploy Infrastructure - dev" \
  --extra-vars='{"environment": "dev", "git_commit": "abc123"}' \
  --monitor
```

#### Via API (cURL)
```bash
# Trigger Jenkins job
curl -X POST "http://jenkins.company.com:8080/job/terraform-aws-infrastructure-pipeline/buildWithParameters" \
  --user admin:token \
  --data "ENVIRONMENT=dev&ACTION=apply&TRIGGER_ANSIBLE=true"

# Trigger Ansible AAP job
curl -X POST "https://ansible-tower.company.com/api/v2/job_templates/5/launch/" \
  -H "Authorization: Bearer ${TOWER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"environment": "dev"}}'
```

---

## 📊 Monitoring & Observability

### Jenkins Pipeline Monitoring

**Key Metrics to Track:**
- Pipeline success/failure rate
- Average pipeline duration
- Security scan findings
- Plan vs Apply comparison

**Jenkins Plugins for Monitoring:**
```groovy
// Add to Jenkinsfile
post {
    always {
        // Publish JUnit test results
        junit '**/test-results/**/*.xml'
        
        // Publish HTML reports
        publishHTML([
            reportDir: 'terraform-aws-infrastructure',
            reportFiles: 'tfsec-report.html',
            reportName: 'TFsec Security Report'
        ])
        
        // Archive artifacts
        archiveArtifacts artifacts: '**/*.tfplan,**/*.json'
    }
}
```

### Ansible AAP Monitoring

**Dashboard Metrics:**
- Job success rate by environment
- Average deployment duration
- Resource utilization
- Failed task analysis

**Custom Callbacks:**
```yaml
# ansible.cfg
[defaults]
callback_whitelist = profile_tasks, timer, yaml
stdout_callback = yaml
```

### Integration with Monitoring Tools

**Prometheus Metrics Export:**
```yaml
# Add to playbook
- name: Send metrics to Prometheus
  uri:
    url: "{{ prometheus_pushgateway_url }}/metrics/job/terraform_deploy/instance/{{ environment }}"
    method: POST
    body: |
      terraform_deployment_success{environment="{{ environment }}"} 1
      terraform_deployment_duration_seconds{environment="{{ environment }}"} {{ deployment_duration }}
```

**Slack Notifications:**
```groovy
// In Jenkinsfile
post {
    success {
        slackSend(
            color: 'good',
            message: "✅ Terraform ${params.ACTION} succeeded in ${params.ENVIRONMENT}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "❌ Terraform ${params.ACTION} failed in ${params.ENVIRONMENT}"
        )
    }
}
```

---

## 🔒 Security Best Practices

### Credentials Management

1. **Never commit credentials** to Git
2. **Use Jenkins Credentials Store** for AWS keys
3. **Use Ansible Vault** for sensitive variables
4. **Rotate credentials regularly** (90 days)
5. **Use IAM roles** where possible

### Terraform State Security

```hcl
# backend.tf - Always enable encryption
terraform {
  backend "s3" {
    bucket         = "terraform-state-${environment}"
    key            = "infrastructure/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:region:account:key/id"
    dynamodb_table = "terraform-state-lock-${environment}"
  }
}
```

### Pipeline Security

```groovy
// Jenkinsfile - Security checks
stage('Security Gate') {
    steps {
        script {
            // Check for high severity findings
            def tfsecResults = readJSON file: 'tfsec-report.json'
            def highSeverity = tfsecResults.results.findAll { 
                it.severity == 'HIGH' || it.severity == 'CRITICAL' 
            }
            
            if (highSeverity.size() > 0) {
                error("Found ${highSeverity.size()} high/critical security issues")
            }
        }
    }
}
```

---

## 🚨 Troubleshooting Guide

### Common Issues

#### 1. Jenkins Pipeline Fails at Terraform Init

**Symptoms:**
```
Error: Error loading state: AccessDenied: Access Denied
```

**Solution:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check S3 bucket exists
aws s3 ls s3://terraform-state-dev-${AWS_ACCOUNT_ID}

# Verify DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock-dev

# Reconfigure backend
cd terraform-aws-infrastructure
terraform init -reconfigure -backend-config=environments/dev/backend.tf
```

#### 2. Ansible AAP Cannot Connect to AWS

**Symptoms:**
```
fatal: [localhost]: FAILED! => {"msg": "Failed to describe instances: An error occurred (AuthFailure)"}
```

**Solution:**
```bash
# Verify credentials in Ansible AAP
# Navigate to: Resources → Credentials → aws-terraform-creds → Test

# Check AWS CLI access from AAP control node
ssh ansible-aap-server
aws sts get-caller-identity
```

#### 3. Terraform Plan Shows Unexpected Changes

**Symptoms:**
```
Plan: 10 to add, 5 to change, 3 to destroy
```

**Solution:**
```bash
# Check for state drift
terraform refresh -var-file=environments/dev/terraform.tfvars

# Review state file
terraform show

# If state is corrupted, restore from S3 versioning
aws s3api list-object-versions \
  --bucket terraform-state-dev-${AWS_ACCOUNT_ID} \
  --prefix infrastructure/terraform.tfstate
```

#### 4. Security Scan Fails Pipeline

**Symptoms:**
```
Error: tfsec found 15 critical issues
```

**Solution:**
```bash
# Review tfsec report
cat terraform-aws-infrastructure/tfsec-report.json | jq '.results[] | select(.severity=="CRITICAL")'

# Fix common issues:
# - Add encryption to resources
# - Update security group rules
# - Enable logging

# Temporarily skip scan (emergency only)
# Set SKIP_SECURITY_SCAN=true in Jenkins parameters
```

#### 5. Ansible Playbook Timeout

**Symptoms:**
```
TASK [Terraform apply] **************
fatal: [localhost]: FAILED! => {"msg": "Timeout (300s) waiting for task"}
```

**Solution:**
```yaml
# Increase timeout in playbook
- name: Terraform apply
  command: terraform apply -auto-approve tfplan
  args:
    chdir: "{{ terraform_dir }}/terraform-aws-infrastructure"
  async: 3600  # 1 hour
  poll: 30     # Check every 30 seconds
```

---

## 📚 Quick Reference

### Jenkins Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Target environment | `dev`, `uat`, `prod` |
| `ACTION` | Terraform action | `plan`, `apply`, `destroy` |
| `AWS_REGION` | AWS region | `ap-southeast-1` |
| `GIT_COMMIT_SHORT` | Short commit hash | `abc123f` |

### Ansible Extra Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `environment` | Target environment | Yes | - |
| `aws_region` | AWS region | Yes | `ap-southeast-1` |
| `git_commit` | Git commit to deploy | No | `HEAD` |
| `cleanup_temp_dir` | Clean up after deployment | No | `true` |
| `update_inventory` | Update AAP inventory | No | `true` |

### Terraform Module Dependencies

```
kms (optional)
  ↓
network → endpoints
  ↓
secrets
  ↓
database
  ↓
compute
  ↓
backup (PROD only)
```

### Common CLI Commands

```bash
# Jenkins - View job status
curl -s http://jenkins.company.com:8080/job/terraform-aws-infrastructure-pipeline/lastBuild/api/json | jq '.result'

# Ansible AAP - List running jobs
awx jobs list --status running

# Terraform - Check state
cd terraform-aws-infrastructure
terraform state list

# AWS - Verify resources
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'
```

---

## 📖 Additional Resources

### Documentation Links

- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Ansible AAP Documentation**: https://docs.ansible.com/automation-controller/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Well-Architected**: https://aws.amazon.com/architecture/well-architected/

### Training Resources

1. **Jenkins Pipeline Development**
   - Jenkins Pipeline as Code
   - Groovy scripting for pipelines
   - Plugin development

2. **Ansible AAP Administration**
   - Job templates and workflows
   - Dynamic inventory management
   - Ansible Vault encryption

3. **Terraform Best Practices**
   - Module development
   - State management
   - Provider configuration

### Support Channels

- **Internal Documentation**: Confluence/Wiki
- **Team Chat**: Slack #infrastructure-team
- **Ticket System**: JIRA Infrastructure Project
- **On-Call**: PagerDuty rotation

---

## 🔄 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2024-01 | Initial CI/CD pipeline setup | DevOps Team |
| 1.1.0 | 2024-03 | Added Ansible AAP integration | DevOps Team |
| 1.2.0 | 2024-06 | Enhanced security scanning | Security Team |
| 2.0.0 | 2024-12 | Multi-environment support | DevOps Team |

---

## 📞 Getting Help

### Pipeline Issues

1. **Check Jenkins Console Output**
   ```
   Jenkins → Job → Build #XX → Console Output
   ```

2. **Review Ansible AAP Job Logs**
   ```
   AAP → Jobs → Select Job → Output
   ```

3. **Contact DevOps Team**
   - Slack: `#infrastructure-team`
   - Email: devops@company.com
   - Emergency: PagerDuty escalation

### Terraform Issues

1. **Review Terraform Logs**
   ```bash
   export TF_LOG=DEBUG
   terraform plan -var-file=environments/dev/terraform.tfvars
   ```

2. **Check AWS CloudTrail**
   ```
   AWS Console → CloudTrail → Event History
   ```

3. **State Issues**
   - Contact: terraform-admin@company.com
   - Always backup state before manual modifications

---

## ✅ Pre-Deployment Checklist

### Before Running Pipeline

- [ ] AWS credentials configured in Jenkins
- [ ] S3 backend bucket created
- [ ] DynamoDB lock table created
- [ ] Terraform variables reviewed
- [ ] Security groups rules validated
- [ ] Cost estimates reviewed
- [ ] Change request approved (PROD only)
- [ ] Rollback plan documented

### After Deployment

- [ ] Verify all resources created
- [ ] Check application health
- [ ] Review CloudWatch metrics
- [ ] Update documentation
- [ ] Notify stakeholders
- [ ] Close change request

---

## 🎯 Best Practices

### Pipeline Development

1. **Always use version control** for Jenkinsfile and Ansible playbooks
2. **Test in DEV first** before promoting to UAT/PROD
3. **Use meaningful commit messages** for audit trail
4. **Enable notifications** for pipeline failures
5. **Archive important artifacts** (plans, outputs, logs)

### Security

1. **Never hardcode credentials** in code
2. **Use least privilege IAM policies**
3. **Enable audit logging** for all pipelines
4. **Rotate credentials regularly**
5. **Scan for vulnerabilities** before deployment

### Cost Optimization

1. **Tag all resources** for cost allocation
2. **Use appropriate instance sizes** per environment
3. **Enable auto-shutdown** for non-PROD environments
4. **Review cost reports** monthly
5. **Clean up unused resources** regularly

---

## 📊 KPIs and Metrics

### Pipeline Performance

- **Deployment Frequency**: Target 10+ per week (DEV)
- **Lead Time**: < 30 minutes from commit to deployed
- **Success Rate**: > 95%
- **MTTR (Mean Time to Restore)**: < 1 hour

### Infrastructure Quality

- **Security Scan Pass Rate**: 100%
- **Infrastructure Drift**: < 5% deviation
- **Cost Variance**: ±10% from budget
- **Availability**: 99.9% uptime (PROD)

---

## 🚀 Future Enhancements

### Planned Features

1. **Blue-Green Deployments**
   - Zero-downtime deployments
   - Automated rollback on failure

2. **Automated Testing**
   - Infrastructure tests with Terratest
   - Compliance tests with InSpec

3. **GitOps Integration**
   - ArgoCD for Kubernetes workloads
   - Flux for continuous reconciliation

4. **Enhanced Monitoring**
   - Real-time pipeline dashboards
   - Predictive failure analysis

---

## 📝 Conclusion

This CI/CD pipeline provides a robust, automated way to deploy and manage AWS infrastructure using Terraform, Jenkins, and Ansible AAP. By following this guide, pipeline engineers can:

- ✅ Deploy infrastructure consistently across environments
- ✅ Maintain security and compliance standards
- ✅ Enable rapid iteration and deployment
- ✅ Reduce manual errors and deployment time
- ✅ Provide full audit trail and rollback capability

For questions or improvements to this documentation, please contact the DevOps team or submit a pull request to the documentation repository.

---

**Document Version**: 2.0.0  
**Last Updated**: December 2024  
**Maintained by**: DevOps & Infrastructure Team  
**Review Cycle**: Quarterly
