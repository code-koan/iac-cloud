# RDS PostgreSQL Serverless（阿里云）

按 RCU 计费的 PostgreSQL 实例，仅 VPC 内网可达，闲时可自动暂停（0 RCU 计费）。

## 使用

```bash
export TF_VAR_access_key=xxx
export TF_VAR_secret_key=xxx
export ALICLOUD_ACCESS_KEY=xxx       # OSS backend 鉴权
export ALICLOUD_SECRET_KEY=xxx

# 库 / 账号清单（不含密码，可放进 git）
export TF_VAR_databases='[
  {"name":"app","account":"app_user"},
  {"name":"analytics","account":"ro_user"}
]'

# 密码单独，sensitive，绝不入库（key = database name）
export TF_VAR_database_passwords='{
  "app":"Strong-Pwd-1!",
  "analytics":"Strong-Pwd-2!"
}'

terraform init
terraform apply
```

连接方式（在 VPC 内的 ECS / ACS Pod 里）：

```bash
PGPASSWORD='Strong-Pwd-1!' psql \
  -h "$(terraform output -raw connection_string)" \
  -p "$(terraform output -raw port)" \
  -U app_user -d app
```

### 拿连接串

```bash
# 完整 DSN（含密码，输出 sensitive 需 -json 解开）
terraform output -json psql_dsn
# 例：
#   {
#     "appdb": "postgresql://app:xxx@pgm-xxx.pg.rds.aliyuncs.com:5432/appdb?sslmode=require",
#     "logdb": "postgresql://log:yyy@pgm-xxx.pg.rds.aliyuncs.com:5432/logdb?sslmode=require"
#   }

# 不含密码的模板，方便贴到文档 / wiki
terraform output -json psql_dsn_no_password
```

> 仅 VPC 内网可达；本机若不在该 VPC 内（无 VPN / 跳板）连不通。

## State

- 远程 backend: 阿里云 OSS
- bucket: `makeit-agi`，prefix: `iac/state/rds-pg-serverless`，region: `cn-hongkong`
- 凭据: `ALICLOUD_ACCESS_KEY` / `ALICLOUD_SECRET_KEY` 环境变量
- 不允许 `terraform.tfstate` 落本地仓库

## 关键变量

详见 [../../.config/alibaba/rds-pg-serverless.md](../../.config/alibaba/rds-pg-serverless.md)。

- `engine_version` — PG 大版本（默认 `17.0`，支持 14/15/16/17）
- `min_capacity` / `max_capacity` — Serverless RCU 上下限（默认 `0.5` ~ `8`）
- `auto_pause` — 闲时自动暂停（默认 `true`，开启后闲时 0 RCU 计费）
- `databases` — `[{name, account}]`，非敏感，可入库
- `database_passwords` — `{name -> password}` map，sensitive，**不入库**

## 与 ACS 配套使用

把 ACS 模板的 VPC / vSwitch 直接喂给本模块，让 PG 实例落在同一 VPC，Pod 可内网直连：

```bash
cd ../acs
ACS_VPC_ID=$(terraform output -raw vpc_id)
ACS_VSW_ID=$(terraform output -json vswitch_ids | jq -r '.[0]')

cd ../rds-pg-serverless
export TF_VAR_existing_vpc_id="$ACS_VPC_ID"
export TF_VAR_existing_vswitch_id="$ACS_VSW_ID"
terraform init
terraform apply
```

`existing_vpc_id` + `existing_vswitch_id` 同时给定时，本模块跳过新建 VPC / vSwitch，直接挂到指定子网。

## 跨 VPC 互通

**默认不通**。RDS 实例落在某个 VPC + vSwitch 上，仅该 VPC 的 ECS / ACS Pod 内网可达；同地域 / 跨地域的另一个 VPC 直连会被网络隔离阻断。

要让另一个 VPC 也能连到本实例，三选一：

| 方案 | 适用 | 关键操作 |
|------|------|---------|
| 推荐 — **同 VPC**（让 RDS 与客户端落同一 VPC） | 客户端就在阿里云上 | 用本模块的 `existing_vpc_id` + `existing_vswitch_id` 复用客户端所在 VPC 的网络 |
| **VPC 对等连接 / 云企业网 CEN** | 必须跨 VPC（不同业务、跨地域） | 在阿里云控制台建 CEN 把两个 VPC 加入同一带宽包；然后把对端 VPC 网段加入本模块的 `var.security_ips` 白名单 |
| **PrivateLink / 内网域名解析** | 跨账号、需精细授权 | RDS 控制台开 PrivateLink；对端建 VPC Endpoint，通过它访问 |

> **关键点**：CEN / 对等打通了网络层之后，**还要把对端 VPC 网段写进 `var.security_ips`**，否则 RDS 白名单仍会拒。本模块默认 `security_ips = null` → 自动收紧到当前 VPC 网段（即"仅本 VPC 内网可达"）；要让其它网段进来必须显式覆盖。

例：把对端 VPC `10.50.0.0/16` 加入白名单（同时保留本 VPC）——
```bash
export TF_VAR_security_ips='["10.1.0.0/16","10.50.0.0/16"]'
terraform apply
```

## 销毁

```bash
terraform destroy
```

> destroy 前建议：1) 把 `security_ips` 收紧到真正在用的网段，避免误删期间裸奔；2) 用 `pg_dump` 备份关键库；destroy 删的是实例，数据无回收站。

## 注意

Serverless RDS PG 仅支持 **Basic 单节点**形态，没有主备 / 高可用。需要主备请切到常规付费形态（`instance_charge_type = "Postpaid"` + `category = "HighAvailability"`），并相应调整 `instance_type`。
