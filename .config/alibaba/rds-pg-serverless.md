# RDS PostgreSQL Serverless

模板路径: `alibaba/rds-pg-serverless/`

## 资源拓扑

```
VPC (10.1.0.0/16, 或复用 existing_vpc_id)
 └── vSwitch (单 zone, 10.1.0.0/24, 或复用 existing_vswitch_id)
      └── alicloud_db_instance  (PostgreSQL, instance_charge_type=Serverless, Basic 单节点)
            ├── serverless_config { min_capacity, max_capacity, auto_pause }
            ├── alicloud_db_database × N      (CREATE DATABASE)
            ├── alicloud_rds_account × N      (CREATE USER)
            └── alicloud_db_account_privilege × N  (GRANT DBOwner)
```

## 变量速查

| 变量 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `access_key` | string (sensitive) | `null` | 阿里云 AK，建议 `TF_VAR_access_key` |
| `secret_key` | string (sensitive) | `null` | 阿里云 SK，建议 `TF_VAR_secret_key` |
| `region` | string | `cn-hongkong` | 改这里即切换地域 |
| `zone_ids` | list(string) | `[]` | 留空时按 region 自动取首个支持 RDS 的 zone |
| `instance_name` | string | `makeit-pg` | RDS 实例名 |
| `engine_version` | string | `17.0` | PG 大版本，Serverless 支持 14/15/16/17 |
| `storage_gb` | number | `20` | 存储空间（cloud_essd） |
| `min_capacity` | number | `0.5` | Serverless RCU 下限 |
| `max_capacity` | number | `8` | Serverless RCU 上限 |
| `auto_pause` | bool | `true` | 闲时自动暂停（0 RCU 计费） |
| `switch_force` | bool | `false` | 强制切换（serverless 主备切换） |
| `vpc_cidr` | string | `10.1.0.0/16` | 新建 VPC 网段（existing_vpc_id 给定时忽略） |
| `security_ips` | list(string) | `null` | RDS 白名单。`null`（默认）= 自动收紧到当前 VPC 网段；显式给则覆盖 |
| `existing_vpc_id` | string | `null` | 复用已有 VPC，与 `existing_vswitch_id` 同时给 |
| `existing_vswitch_id` | string | `null` | 复用已有 vSwitch |
| `databases` | list(object) | `[]` | `[{name, account}]` 非敏感，可入库 |
| `database_passwords` | map(string) (sensitive) | `{}` | `{name -> password}`，建议 `TF_VAR_database_passwords` 注入 |

## 输出

- `instance_id` — RDS 实例 ID
- `connection_string` — 内网连接域名
- `port` — PG 端口（默认 5432）
- `vpc_id` — VPC ID（新建或复用）
- `vswitch_id` — vSwitch ID
- `databases` — 已创建的 `{ name, account }` 列表（不含密码，sensitive 因依赖 var.databases）
- `psql_dsn` (sensitive) — `{ db_name -> "postgresql://user:pwd@host:port/db?sslmode=require" }`，可直接复制使用
- `psql_dsn_no_password` — 占位版本，密码替换为 `<password>`，方便贴 wiki / 文档

## 计费模型

Serverless 按 **RCU + 存储** 计费：

- RCU = RDS Capacity Unit，按 `min_capacity` ~ `max_capacity` 区间弹性伸缩，秒级粒度计费
- `auto_pause = true` 时，无连接闲置一段时间自动暂停，期间 0 RCU 计费，仅存储费用
- 存储按 `cloud_essd` 容量按小时计费

区别于：
- **包年包月**: `instance_charge_type = "Prepaid"` + 固定规格，用不用都收钱
- **按量付费**: `instance_charge_type = "Postpaid"` + 固定规格，按小时收钱无伸缩
- **Serverless（本模板）**: `instance_charge_type = "Serverless"`，按真实负载收钱，闲时可 0

## 网络与安全

- 仅 VPC 内网：模板**不开** public connection，外部直接连不上
- `security_ips` 默认 `null` → 自动收紧到当前 VPC 网段（新建时用 `vpc_cidr`，复用时用 data source 查 existing VPC 的真实 cidr），即"仅本 VPC 内网可达"
- 需要跨 VPC（CEN / 对等） / 多网段访问时，显式 `var.security_ips = [...]` 覆盖
- `security_ip_mode = "safety"` — 高安全白名单模式

如确需公网访问，需手动跑 `alicloud_db_connection` + `alicloud_db_readwrite_splitting_connection`，本模板有意不暴露。

## 库 / 账号 / 授权

通过三件套等价于 SQL：

| Terraform 资源 | SQL 等价 |
|----------------|---------|
| `alicloud_db_database` | `CREATE DATABASE <name> WITH ENCODING 'UTF8'` |
| `alicloud_rds_account` (account_type=Normal) | `CREATE USER <name> WITH PASSWORD '<pwd>'` |
| `alicloud_db_account_privilege` (privilege=DBOwner) | `ALTER DATABASE <db> OWNER TO <user>` + 全权限 |

`DBOwner` = PG 库 owner，可在该库内建表、装扩展（如 `pg_trgm`、`vector`）、改 schema。

> 阿里云 RDS PG 的 `privilege` 枚举：`ReadOnly` / `ReadWrite` / `DDLOnly` / `DMLOnly` / `DBOwner`。本模板默认给 `DBOwner` 是为了让账号能完整管控自己的库；如需读写分离 / 只读账号，可在调用层另开账号资源指定不同 privilege。

## 与 ACS 配套

`existing_vpc_id` + `existing_vswitch_id` 复用 `alibaba/acs/` 模板输出的 `vpc_id` / `vswitch_ids[0]`，PG 与 ACS Pod 同 VPC，Pod 内 `psql` 直连内网域名。

## 跨 VPC 互通

RDS 仅 VPC 内网形态下，**默认只有同 VPC 可达**。跨 VPC 需要两层都打通：

1. **网络层**：阿里云 VPC 对等连接（同地域，简单）或云企业网 CEN（跨地域 / 跨账号 / 跨 VPC 多对多）；PrivateLink 适合跨账号精细授权
2. **白名单层**：本模块 `var.security_ips` 必须把对端 VPC 网段加进去；CEN 打通后白名单还拒绝就连不上

经典坑：网络对等已通、`telnet 5432` 也通，但应用报 timeout —— 99% 是白名单没加。

公网访问刻意不开（不创建 `alicloud_db_connection`），需要时手动加资源或控制台开启，并把可信公网 IP 加白。

## 销毁

`terraform destroy` 顺序：删 `account_privilege` → 删 `account` → 删 `database` → 删 RDS 实例 → 删 vSwitch / VPC（若新建）。

> 数据无回收站，destroy 前先 `pg_dump` 备份；存储 + RCU 计费随实例消失立即停止。
