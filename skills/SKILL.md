---
name: tencent-spot-deploy
description: "Deploy Tencent Cloud spot instances with Docker pre-installed. Use when user wants to quickly create a cloud server on Tencent Cloud, needs a development machine, wants to deploy Docker containers, or asks to set up cloud infrastructure with Terraform. This skill handles the entire Terraform workflow from config generation to deployment."
---

# Deploy Tencent Cloud Spot Instance

## 安装补充 (Installation)

### 通过 npx skills 从 GitHub 安装

使用 Vercel 的 `skills` CLI 工具，可以从 GitHub 仓库安装 skill 到各种 AI 编码代理。

#### 支持的代理 (Supported Agents)

| 代理 | Agent Flag | 安装目录 |
|------|------------|----------|
| Claude Code | `--agent claude-code` | `~/.claude/skills/` |
| Codex | `--agent codex` | `~/.codex/skills/` |
| OpenCode | `--agent opencode` | `~/.opencode/skills/` |
| Cursor | `--agent cursor` | `.cursor/skills/` |

#### 安装命令 (Commands)

```bash
# 安装整个 skill 仓库
npx skills add vercel-labs/agent-skills

# 安装到指定代理 (支持多个)
npx skills add owner/repo --agent claude-code --agent opencode

# 全局安装 (所有项目可用)
npx skills add owner/repo -g

# 安装特定 skill
npx skills add owner/repo --skill skill-name

# 非交互式安装 (CI/CD)
npx skills add owner/repo --skill frontend-design -g -a claude-code -y

# 列出可用 skills
npx skills add owner/repo --list
```

#### Source Formats

```bash
# GitHub 简写 (owner/repo)
npx skills add vercel-labs/agent-skills

# 完整 GitHub URL
npx skills add https://github.com/vercel-labs/agent-skills

# 安装特定 skill 使用 @ 语法
npx skills add vercel-labs/agent-skills@frontend-design

# 从仓库中的子目录安装
npx skills add https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines

# 本地路径
npx skills add ./my-local-skills

# GitLab 或其他 git URL
npx skills add https://gitlab.com/org/repo
npx skills add git@github.com:owner/repo.git
```

### 安装本 Skill

```bash
# 安装到 OpenCode
npx skills add apple/iac-cloud --agent opencode

# 安装到 Claude Code
npx skills add apple/iac-cloud --agent claude-code

# 安装到 Codex
npx skills add apple/iac-cloud --agent codex

# 同时安装到多个代理
npx skills add apple/iac-cloud --agent opencode --agent claude-code
```

## Overview

Deploy a Tencent Cloud preemptible (spot) instance with Docker pre-installed. This skill generates Terraform configuration and handles the full deployment workflow.

## Prerequisites

- Terraform installed (`brew install terraform` or `terraform -v`)
- Tencent Cloud account (secret_id, secret_key)
- GitHub account (for tfstate.dev remote state)

## User Inputs

Ask user for these parameters. Mark required fields:

**Required:**
- `secret_id` - Tencent Cloud SecretId
- `secret_key` - Tencent Cloud SecretKey

**Optional (with defaults):**
- `region` - Region, default: `ap-singapore`
- `availability_zone` - AZ, default: `ap-singapore-1`
- `instance_type` - Instance type, default: `S5.MEDIUM2` (2CPU 4GB)
- `instance_name` - Instance name, default: `docker-spot-instance`
- `key_pair_name` - SSH key pair name, default: `my_singapore_key`

## Deployment Options

**Option A: Use existing module (recommended)**
If user already has the tecent module available, reference it:

```hcl
module "tecent" {
  source = "/path/to/iac-cloud/tecent"
  
  secret_id  = "your-secret-id"
  secret_key = "your-secret-key"
  
  # optional overrides
  instance_name = "my-server"
  region        = "ap-singapore"
}

output "ssh_connection" {
  value = module.tecent.ssh_connection
}
```

**Option B: Generate config in current project**
If no existing module, create Terraform files in current directory:

1. Create `main.tf` with all resources
2. Create `variable.tf` with inputs
3. Create `output.tf` with outputs
4. Create `scripts/user-data.sh`

## Configuration Templates

### main.tf

```hcl
terraform {
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81.0"
    }
  }
  backend "http" {
    address        = "https://api.tfstate.dev/github/v1"
    lock_address   = "https://api.tfstate.dev/github/v1/lock"
    unlock_address = "https://api.tfstate.dev/github/v1/lock"
    lock_method    = "PUT"
    unlock_method  = "DELETE"
    username       = "your-github-username/your-repo"
  }
}

provider "tencentcloud" {
  region     = var.region
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

data "tencentcloud_images" "ubuntu" {
  image_type       = ["PUBLIC_IMAGE"]
  image_name_regex = "Ubuntu Server 22.04 LTS 64bit"
}

resource "tencentcloud_vpc" "main_vpc" {
  name       = "${var.instance_name}-vpc"
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "${var.instance_name}-vpc"
    Environment = "development"
  }
}

resource "tencentcloud_subnet" "main_subnet" {
  name              = "${var.instance_name}-subnet"
  vpc_id            = tencentcloud_vpc.main_vpc.id
  availability_zone = var.availability_zone
  cidr_block        = "10.0.1.0/24"
  is_multicast      = false
  tags = {
    Name        = "${var.instance_name}-subnet"
    Environment = "development"
  }
}

resource "tencentcloud_security_group" "docker_sg" {
  name        = "${var.instance_name}-sg"
  description = "Allow SSH, HTTP, HTTPS and custom port"
}

resource "tencentcloud_security_group_rule" "allow_ssh_http" {
  security_group_id = tencentcloud_security_group.docker_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "TCP"
  port_range        = "22,80,443,7290"
  policy            = "ACCEPT"
}

resource "tencentcloud_security_group_rule" "allow_all_outbound" {
  security_group_id = tencentcloud_security_group.docker_sg.id
  type              = "egress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "ALL"
  policy            = "ACCEPT"
}

resource "tencentcloud_key_pair" "ssh_key" {
  key_name   = var.key_pair_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "tencentcloud_instance" "docker_spot_instance" {
  instance_name     = var.instance_name
  availability_zone = var.availability_zone
  image_id          = data.tencentcloud_images.ubuntu.images[0].image_id
  instance_type     = var.instance_type
  key_ids           = [tencentcloud_key_pair.ssh_key.id]
  orderly_security_groups = [tencentcloud_security_group.docker_sg.id]
  subnet_id         = tencentcloud_subnet.main_subnet.id
  internet_max_bandwidth_out = 100

  instance_charge_type = "SPOTPAID"
  spot_instance_type   = "ONE-TIME"
  spot_max_price       = "0.3"

  system_disk_type = "CLOUD_PREMIUM"
  system_disk_size = 20

  user_data = local.user_data

  internet_charge_type = "TRAFFIC_POSTPAID_BY_HOUR"
  allocate_public_ip   = true

  tags = {
    Name         = var.instance_name
    Environment  = "development"
    InstanceType = "spot"
  }
}
```

### variable.tf

```hcl
variable "secret_id" {}

variable "secret_key" {}

variable "region" {
  description = "Tencent Cloud region"
  type        = string
  default     = "ap-singapore"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "ap-singapore-1"
}

variable "instance_name" {
  description = "Instance name"
  type        = string
  default     = "docker-spot-instance"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "S5.MEDIUM2"
}

variable "key_pair_name" {
  description = "SSH key pair name"
  type        = string
  default     = "my_singapore_key"
}

locals {
  private_key_base64 = base64encode(file("~/.ssh/id_rsa"))
  
  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh", {
    container_port      = 7290,
    private_key_base64  = local.private_key_base64
  }))
}
```

### output.tf

```hcl
output "instance_id" {
  description = "Instance ID"
  value       = tencentcloud_instance.docker_spot_instance.id
}

output "public_ip" {
  description = "Public IP address"
  value       = tencentcloud_instance.docker_spot_instance.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = tencentcloud_instance.docker_spot_instance.private_ip
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${tencentcloud_instance.docker_spot_instance.public_ip}"
}

output "docker_service_url" {
  description = "Docker service URL"
  value       = "http://${tencentcloud_instance.docker_spot_instance.public_ip}:7290"
}
```

### scripts/user-data.sh

```bash
#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR

sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
sudo docker --version
sudo chmod 777 /var/run/docker.sock

# Configure SSH private key
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh

echo "${private_key_base64}" | base64 -d > /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
```

## Deployment Workflow

Follow these steps in order:

### Step 1: Gather credentials
Ask user for:
- `TF_VAR_secret_id`
- `TF_VAR_secret_key`
- `TF_HTTP_PASSWORD` (GitHub token for tfstate.dev)

### Step 2: Initialize Terraform
```bash
export TF_VAR_secret_id="xxx"
export TF_VAR_secret_key="xxx"
export TF_HTTP_PASSWORD="your-github-token"

terraform init
```

### Step 3: Plan deployment
```bash
terraform plan
```
Review the plan with user before proceeding.

### Step 4: Apply
```bash
terraform apply
```

### Step 5: Show outputs
After successful deployment, show:
- Public IP
- SSH connection command
- Docker service URL

## Cleanup

When user wants to destroy:
```bash
terraform destroy
```

## Important Notes

1. **Spot instances can be reclaimed** - Data may be lost if instance is reclaimed. Use for development/temp workloads only.
2. **SSH key required** - User must have `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` locally
3. **GitHub token** - Required for tfstate.dev remote state. Create at: https://github.com/settings/tokens
4. **Cost** - Even spot instances incur costs. Monitor usage.
