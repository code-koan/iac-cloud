# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-02
**Commit:** 363b82c
**Branch:** main

## OVERVIEW

Terraform IaC 项目，快速创建腾讯云抢占式实例 (Spot Instance)，预装 Docker。

## STRUCTURE

```
iac-cloud/
├── tecent/                     # 腾讯云模块
│   ├── main.tf                # 资源定义
│   ├── variable.tf            # 变量
│   ├── output.tf              # 输出
│   ├── README.md              
│   ├── scripts/               
│   │   └── user-data.sh       # 实例初始化
│   └── .terraform.lock.hcl   
└── README.md
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| 资源定义 | `tecent/main.tf` | VPC、子网、安全组、实例 |
| 变量配置 | `tecent/variable.tf` | 区域、实例类型、凭据 |
| 启动脚本 | `tecent/scripts/user-data.sh` | Docker 安装、SSH 配置 |
| 模块文档 | `tecent/README.md` | 使用说明 |

## CONVENTIONS

- 资源命名: `资源类型_用途描述` (如 `main_vpc`, `app_subnet`)
- 变量命名: snake_case
- 标签: PascalCase (Name, Environment, InstanceType)
- 缩进: 2 空格

## ANTI-PATTERNS (THIS PROJECT)

- 禁止硬编码密钥 → 使用环境变量 `TF_VAR_*`
- 禁止提交 `.tfstate` 文件 → 使用 tfstate.dev 远程状态
- 禁止跳过 plan 直接 apply

## UNIQUE STYLES

- 使用 `tfstate.dev` 管理远程 state
- 抢占式实例 (SPOTPAID) + 按量计费网络
- user-data.sh 使用 `set -euo pipefail`

## COMMANDS

```bash
# 凭据配置
export TF_VAR_secret_id="xxx"
export TF_VAR_secret_key="xxx"
export TF_HTTP_PASSWORD="your_github_token"

# Terraform 工作流
terraform init
terraform plan
terraform apply
terraform destroy

# 验证
terraform fmt -check -recursive && terraform validate
```

## NOTES

- 抢占式实例有被回收风险，生产环境建议用包年包月
- SSH 密钥使用环境变量或 tfstate.dev 加密存储
- 锁定 `.terraform.lock.hcl` 确保 provider 版本一致

---

## 代码风格

### 文件组织

- `main.tf`: resource + data
- `variable.tf`: variable + locals
- `output.tf`: output
- 逻辑块之间留空行

### 命名

- 资源: `类型_用途` (main_vpc, app_subnet)
- 变量: snake_case
- Tag: PascalCase (Name, Environment, InstanceType)

### 格式化

- 缩进: 2 空格
- 等号对齐
- 尾部逗号

### user-data.sh

```bash
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR
```

### 安全

- 禁止硬编码密钥 → `export TF_VAR_*`
- 密钥用 `file()` 读取
- 禁止提交 .tfstate
