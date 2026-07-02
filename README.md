# Terraform — AWS VPC & EC2 Infrastructure

This project provisions a production-ready **VPC** with public/private subnets and deploys an **EC2 instance** using Terraform.

---

## Architecture

```
                     ┌──────────────────────────────────────────────────┐
                     │                 VPC (10.0.0.0/16)               │
                     │                                                  │
                     │  ┌──────────────┐      ┌──────────────┐         │
   Internet ◄──IGW──►│  │ Public Sub-1 │      │ Public Sub-2 │         │
                     │  │ 10.0.1.0/24  │      │ 10.0.2.0/24  │         │
                     │  │  (us-east-1a)│      │  (us-east-1b)│         │
                     │  │              │      │              │         │
                     │  │  ┌────────┐  │      └──────────────┘         │
                     │  │  │  EC2   │  │                                │
                     │  │  └────────┘  │                                │
                     │  └──────┬───────┘                                │
                     │         │ NAT GW                                 │
                     │  ┌──────▼───────┐      ┌──────────────┐         │
                     │  │ Private Sub-1│      │ Private Sub-2│         │
                     │  │ 10.0.11.0/24 │      │ 10.0.12.0/24 │         │
                     │  │  (us-east-1a)│      │  (us-east-1b)│         │
                     │  └──────────────┘      └──────────────┘         │
                     └──────────────────────────────────────────────────┘
```

---

## Resources Created

| Resource | Name | Description |
|----------|------|-------------|
| VPC | `production-vpc` | CIDR `10.0.0.0/16` with DNS support enabled |
| Internet Gateway | `IGW` | Provides internet access to public subnets |
| NAT Gateway | `NAT-Gateway` | Allows private subnets to reach the internet |
| Elastic IP | — | Attached to NAT Gateway |
| Public Subnet 1 | `Public-Subnet-1` | `10.0.1.0/24` in `us-east-1a` |
| Public Subnet 2 | `Public-Subnet-2` | `10.0.2.0/24` in `us-east-1b` |
| Private Subnet 1 | `Private-Subnet-1` | `10.0.11.0/24` in `us-east-1a` |
| Private Subnet 2 | `Private-Subnet-2` | `10.0.12.0/24` in `us-east-1b` |
| Route Table | `Public-RT` | Routes `0.0.0.0/0` → Internet Gateway |
| Route Table | `Private-RT` | Routes `0.0.0.0/0` → NAT Gateway |
| Security Group | `EC2-SG` | Allows SSH (22) and HTTP (80) inbound |
| EC2 Instance | `Terraform-EC2` | `t3.micro` in Public Subnet 1 |

---

## File Structure

```
terraform-vpc/
├── provider.tf        # AWS provider configuration
├── versions.tf        # Terraform and provider version constraints
├── variables.tf       # Input variable definitions
├── terraform.tfvars   # Variable values
├── vpc.tf             # VPC, subnets, IGW, NAT, route tables
├── ec2.tf             # Security group and EC2 instance
└── outputs.tf         # Output values (IDs, public IP)
```

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region to deploy resources |
| `vpc_name` | `terraform-vpc` | Name tag for the VPC |
| `vpc_cidr` | `10.0.0.0/16` | CIDR block for the VPC |
| `public_subnet1` | `10.0.1.0/24` | CIDR for Public Subnet 1 |
| `public_subnet2` | `10.0.2.0/24` | CIDR for Public Subnet 2 |
| `private_subnet1` | `10.0.11.0/24` | CIDR for Private Subnet 1 |
| `private_subnet2` | `10.0.12.0/24` | CIDR for Private Subnet 2 |
| `instance_type` | `t3.micro` | EC2 instance type |
| `key_name` | `terraform-key` | AWS Key Pair name for SSH access |

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `public_subnet1` | ID of Public Subnet 1 |
| `private_subnet1` | ID of Private Subnet 1 |
| `ec2_instance_id` | ID of the EC2 instance |
| `ec2_public_ip` | Public IP of the EC2 instance |

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- AWS CLI configured with valid credentials
- An existing AWS Key Pair named `terraform-key` (or update `terraform.tfvars`)

---

## Usage

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# SSH into the EC2 instance
ssh -i <your-key.pem> ec2-user@<ec2_public_ip>

# Destroy all resources
terraform destroy
```

---

## Author

**Gowsik** — [GitHub](https://github.com/450gowsik)
