# User Data Templates for EC2 Instances

# Linux User Data Script
locals {
  linux_user_data = <<-EOT
    #!/bin/bash
    set -e
    
    # Update system
    yum update -y
    
    # Install CloudWatch Agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    
    # Install MySQL client
    yum install -y mysql
    
    # Install Docker (optional)
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    
    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    
    # Create application directory
    mkdir -p /opt/app
    chown ec2-user:ec2-user /opt/app
    
    # Retrieve RDS credentials from Secrets Manager
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    SECRET_ARN="${var.secret_arn}"
    
    if [ -n "$SECRET_ARN" ]; then
      aws secretsmanager get-secret-value \
        --secret-id $SECRET_ARN \
        --region $REGION \
        --query SecretString \
        --output text > /opt/app/db-credentials.json
      
      chmod 600 /opt/app/db-credentials.json
      chown ec2-user:ec2-user /opt/app/db-credentials.json
    fi
    
    # Set DB endpoint as environment variable
    echo "export DB_ENDPOINT=${var.db_endpoint}" >> /etc/environment
    echo "export DB_NAME=${var.db_name}" >> /etc/environment
    
    # Signal completion
    echo "User data script completed successfully" > /var/log/user-data-completion.log
  EOT

  windows_user_data = <<-EOT
    <powershell>
    # Set error action preference
    $ErrorActionPreference = "Stop"
    
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Install tools
    choco install -y awscli
    choco install -y mysql.workbench
    
    # Install CloudWatch Agent
    $CloudWatchAgentUrl = "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi"
    $CloudWatchAgentPath = "C:\Temp\amazon-cloudwatch-agent.msi"
    New-Item -ItemType Directory -Force -Path C:\Temp
    Invoke-WebRequest -Uri $CloudWatchAgentUrl -OutFile $CloudWatchAgentPath
    Start-Process msiexec.exe -Wait -ArgumentList "/i $CloudWatchAgentPath /quiet"
    
    # Create application directory
    New-Item -ItemType Directory -Force -Path C:\App
    
    # Retrieve RDS credentials from Secrets Manager
    $Region = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/placement/region -UseBasicParsing).Content
    $SecretArn = "${var.secret_arn}"
    
    if ($SecretArn) {
      $SecretValue = aws secretsmanager get-secret-value --secret-id $SecretArn --region $Region --query SecretString --output text
      $SecretValue | Out-File -FilePath C:\App\db-credentials.json -Encoding UTF8
    }
    
    # Set environment variables
    [System.Environment]::SetEnvironmentVariable("DB_ENDPOINT", "${var.db_endpoint}", "Machine")
    [System.Environment]::SetEnvironmentVariable("DB_NAME", "${var.db_name}", "Machine")
    
    # Signal completion
    "User data script completed successfully" | Out-File -FilePath C:\user-data-completion.log
    </powershell>
  EOT
}
