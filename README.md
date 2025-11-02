# AWS Reverse Proxy Infrastructure with Terraform

A production-grade AWS infrastructure featuring Nginx reverse proxies, internal load balancing, and Flask backend servers. All components are deployed using modular Terraform with provisioners.

## 🏗️ Architecture Overview

```
Internet → Public ALB → Nginx Proxies (Public Subnets)
                            ↓
                    Internal ALB → Flask Backends (Private Subnets)
```

### Components:
- **VPC**: Custom VPC (10.0.0.0/16) with 2 AZs
- **Public Subnets**: 2 subnets for Nginx proxies
- **Private Subnets**: 2 subnets for backend applications
- **NAT Gateway**: Enables private instances to reach internet
- **Public ALB**: Distributes traffic to Nginx proxies
- **Internal ALB**: Distributes traffic from proxies to backends
- **EC2 Instances**: 2 proxies + 2 backends with provisioners

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured (`aws configure`)
4. **SSH Key Pair** created in AWS EC2
5. **S3 Bucket** for remote state (see backend.tf)
6. **DynamoDB Table** for state locking

## 🚀 Quick Start

### 1. Create Backend Infrastructure

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket reverse-proxy-terraform-state-mohamed \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket reverse-proxy-terraform-state-mohamed \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

### 2. Configure Variables

# Edit with your values
nano terraform.tfvars
```

**Required Changes:**
- `key_name`: Your AWS EC2 key pair name
- `private_key_path`: Path to your `.pem` file
- Update bucket name in `backend.tf`

### 3. Create Terraform Workspace

```bash
# Initialize and create dev workspace
terraform init
terraform workspace new dev
terraform workspace select dev
```

### 4. Deploy Infrastructure

```bash
# Plan deployment
terraform plan

# Apply
terraform apply
```

## 📂 Project Structure

```
terraform-aws-reverse-proxy/
├── main.tf                    # Root orchestration
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── providers.tf               # AWS provider config
├── backend.tf                 # S3 backend config
├── terraform.tfvars          # Your variable values
│
├── modules/
│   ├── network/              # VPC, Subnets, IGW, NAT
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── security/             # Security Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/              # EC2 with Provisioners
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── loadbalancing/        # ALBs & Target Groups
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── provisioners/
│   └── app/
│       ├── app.py            # Flask backend
│       └── requirements.txt
│
└── all-ips.txt               # Generated IP list
```

## 🔧 Provisioners Implemented

### ✅ Remote-Exec (Proxy Instances)
- Installs and configures Nginx
- Sets up reverse proxy to internal ALB
- Runs on public instances via SSH

### ✅ Remote-Exec (Backend Instances)
- Installs Python3 and Flask
- Starts Flask application on port 80
- Runs via bastion (proxy) host

### ✅ File Provisioner
- Copies `provisioners/app/` to backend instances
- Includes `app.py` and `requirements.txt`

### ✅ Local-Exec
- Generates `all-ips.txt` with format:
  ```
  proxy-ip1 54.123.45.67
  proxy-ip2 54.123.45.68
  backend-ip1 10.0.1.10
  backend-ip2 10.0.3.20
  ```

## 🧪 Testing

### 1. Check Outputs
```bash
terraform output public_alb_url
# Output: http://reverse-proxy-public-alb-123456.us-east-1.elb.amazonaws.com
```

### 2. Test Public ALB
```bash
curl $(terraform output -raw public_alb_url)
```

Expected response:
```json
{
  "status": "healthy",
  "message": "Backend server is running!",
  "hostname": "ip-10-0-1-10",
  "ip": "10.0.1.10",
  "environment": "dev"
}
```

### 3. Verify IPs File
```bash
cat all-ips.txt
```

### 4. SSH to Proxy (Public)
```bash
ssh -i ~/your-key.pem ec2-user@<proxy-public-ip>
```

### 5. SSH to Backend (via Proxy)
```bash
ssh -i ~/your-key.pem -J ec2-user@<proxy-public-ip> ec2-user@<backend-private-ip>
```

## 🔐 Security Best Practices

1. **Restrict SSH access** in production (limit to your IP)
2. **Use IAM roles** instead of hardcoded credentials
3. **Enable MFA** on AWS account
4. **Rotate SSH keys** regularly
5. **Enable VPC Flow Logs** for audit
6. **Use HTTPS** for production (requires certificates)

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy -auto-approve

# Delete workspace (optional)
terraform workspace select default
terraform workspace delete dev
```

## 📊 Cost Estimation

Approximate monthly costs (us-east-1):
- **EC2 (4x t3.micro)**: ~$30
- **NAT Gateway**: ~$32
- **ALB (2x)**: ~$32
- **Data Transfer**: Variable
- **Total**: ~$95/month

## 🐛 Troubleshooting

### Issue: Provisioners timeout
**Solution**: Check security groups allow SSH (port 22)

### Issue: Backend unreachable
**Solution**: Verify internal ALB security group allows proxy SG

### Issue: `all-ips.txt` not created
**Solution**: Ensure file path exists and has write permissions

### Issue: Nginx config fails
**Solution**: Check internal ALB DNS is resolved correctly

## 📚 Technical Notes

1. **Data Source**: Uses `aws_ami` to fetch latest Amazon Linux 2 AMI
2. **Workspace**: Resources deployed in `dev` workspace
3. **Remote State**: Stored in S3 with DynamoDB locking
4. **Bastion Access**: Proxies act as bastion hosts for backend SSH
5. **Health Checks**: ALBs perform HTTP health checks on `/`

## 📝 Module Details

### Network Module
Creates VPC, subnets (public/private), IGW, NAT, route tables

### Security Module
Creates 4 security groups with proper ingress/egress rules

### Compute Module
- Fetches AMI via data source
- Creates EC2 instances
- Runs provisioners (remote-exec, file, local-exec)

### Load Balancing Module
- Creates public & internal ALBs
- Configures target groups
- Sets up listeners
- Attaches EC2 instances to target groups

---

**Author**: Mohamed Hesham Elfateh  
**Project**: AWS Reverse Proxy Infrastructure  
**Version**: 1.0.0