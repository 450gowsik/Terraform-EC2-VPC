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

## File Structure & Code

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

### `provider.tf` — AWS Provider Configuration

Configures the AWS provider with the region specified in variables.

```hcl
provider "aws" {
  region = var.aws_region
}
```

---

### `versions.tf` — Terraform & Provider Versions

Locks Terraform and AWS provider to compatible versions.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

### `variables.tf` — Input Variables

Defines all configurable parameters with sensible defaults.

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_name" {
  default = "terraform-vpc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet1" {
  default = "10.0.1.0/24"
}

variable "public_subnet2" {
  default = "10.0.2.0/24"
}

variable "private_subnet1" {
  default = "10.0.11.0/24"
}

variable "private_subnet2" {
  default = "10.0.12.0/24"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair Name"
  default     = "terraform-key"
}
```

---

### `terraform.tfvars` — Variable Values

Override default values for your environment.

```hcl
aws_region = "us-east-1"

vpc_name = "production-vpc"

key_name = "terraform-key"
```

---

### `vpc.tf` — VPC, Subnets, Gateways & Route Tables

Creates the complete networking layer: VPC, 4 subnets (2 public + 2 private), Internet Gateway, NAT Gateway, and route tables with associations.

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet1
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Private-Subnet-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet2
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "Private-Subnet-2"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "NAT-Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private-RT"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
```

---

### `ec2.tf` — Security Group & EC2 Instance

Creates a security group allowing SSH (port 22) and HTTP (port 80) inbound, then launches an EC2 instance in the public subnet.

```hcl
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public1.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "Terraform-EC2"
  }
}
```

---

### `outputs.tf` — Output Values

Displays key resource IDs and the EC2 public IP after deployment.

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet1" {
  value = aws_subnet.public1.id
}

output "private_subnet1" {
  value = aws_subnet.private1.id
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}
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
- AWS CLI configured with valid credentials (`aws configure`)
- An existing AWS Key Pair named `terraform-key` (or update `terraform.tfvars`)

---

## Usage

### Step 1 — Clone the Repository

```bash
git clone https://github.com/450gowsik/Terraform-EC2-VPC.git
cd Terraform-EC2-VPC
```

### Step 2 — Configure Variables

Edit `terraform.tfvars` to set your preferred values:

```hcl
aws_region = "us-east-1"
vpc_name   = "production-vpc"
key_name   = "your-key-pair-name"
```

### Step 3 — Initialize Terraform

Downloads the AWS provider plugin and initializes the working directory.

```bash
terraform init
```

### Step 4 — Preview the Infrastructure

Review what resources Terraform will create before applying.

```bash
terraform plan
```

### Step 5 — Deploy the Infrastructure

Creates all AWS resources (VPC, subnets, gateways, EC2 instance, etc.).

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### Step 6 — Get the EC2 Public IP

After deployment, Terraform will output the EC2 public IP:

```bash
terraform output ec2_public_ip
```

### Step 7 — SSH into the EC2 Instance

```bash
ssh -i <your-key.pem> ec2-user@<ec2_public_ip>
```

### Step 8 — Destroy All Resources

When done, clean up to avoid AWS charges:

```bash
terraform destroy
```

Type `yes` when prompted to confirm.

---

## Author

**Gowsik** — [GitHub](https://github.com/450gowsik)
