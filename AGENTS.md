# Project Knowledge Base

**Generated:** 2026-06-08
**Branch:** main

## Overview

Terraform IaC 模板集，覆盖多个云服务商的基础设施快速搭建。

- **tecent/** — 腾讯云抢占式实例 (Spot Instance)，预装 Docker
- **gpu-study/** — GPU 学习环境模板（阿里云、火山引擎、AutoDL）
- **alibaba/** — 阿里云基础 Provider 配置
- **autodl/** — AutoDL 连接辅助脚本
- **skills/** — AI 可安装 skill（npx skills 格式）

## Directory Structure

```
iac-cloud/
├── tecent/
│   ├── main.tf              # VPC、子网、安全组、实例
│   ├── variable.tf          # 区域、实例类型、凭据
│   ├── output.tf            # 实例 IP、SSH 连接
│   ├── README.md
│   └── scripts/
│       └── user-data.sh     # Docker 安装、SSH 配置
├── gpu-study/
│   ├── README.md
│   ├── alibaba/
│   │   ├── main.tf          # GPU 实例配置 (gn6i)
│   │   └── variable.tf
│   ├── autodl/
│   │   └── README.md        # AutoDL 操作指南
│   └── volcengine/
│       ├── main.tf           # GPU 实例配置 (g3)
│       └── variable.tf
├── alibaba/
│   ├── main.tf
│   └── variable.tf
├── autodl/
│   ├── connect.sh
│   └── scripts/init.sh
├── skills/
│   ├── SKILL.md             # tencent-spot-deploy skill
│   └── evals/evals.json     # 评估用例
├── .config/                 # AI 编程设计文档
│   ├── _index.md
│   ├── tecent/
│   ├── gpu-study/
│   └── skills/
├── CLAUDE.md                # AI 编程入口
├── AGENTS.md                # 本文件
├── README.md
└── _index.md                # 代码目录索引
```

## Conventions

- **资源命名**: `类型_用途` (main_vpc, app_subnet)
- **变量命名**: snake_case
- **标签**: PascalCase (Name, Environment, InstanceType)
- **缩进**: 2 空格
- **实例类型**: 抢占式/按量付费，不绑定包年包月
- **SSH 密钥**: 复用本地 `~/.ssh/id_rsa.pub`
- **状态管理**: tfstate.dev 远程状态，禁止提交 `.tfstate`

## Commands

```bash
# Tencent Cloud
export TF_VAR_secret_id="xxx"
export TF_VAR_secret_key="xxx"
export TF_HTTP_PASSWORD="your_github_token"

cd tecent
terraform init
terraform plan
terraform apply
terraform destroy

# GPU Study (Alibaba)
cd gpu-study/alibaba
export ALICLOUD_ACCESS_KEY="xxx"
export ALICLOUD_SECRET_KEY="xxx"
terraform init && terraform plan && terraform apply

# GPU Study (Volcengine)
cd gpu-study/volcengine
export VOLC_ACCESS_KEY="xxx"
export VOLC_SECRET_KEY="xxx"
terraform init && terraform plan && terraform apply
```

## Notes

- 腾讯云抢占式实例有被回收风险，生产环境建议用包年包月
- GPU 实例成本较高，使用后及时销毁
- 锁定 `.terraform.lock.hcl` 确保 provider 版本一致
