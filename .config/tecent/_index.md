# tecent

腾讯云抢占式实例 (Spot Instance) Terraform 模块。

## 文件

| 文件 | 说明 |
|------|------|
| 无 | 设计直接体现在 `tecent/main.tf` 中 |

## 设计要点

- **抢占式实例** (SPOTPAID) — 成本低但可能被回收，适用于开发/临时负载
- **按量计费网络** (TRAFFIC_POSTPAID_BY_HOUR) — 流量按量付费
- **用户数据脚本** — 自动安装 Docker、配置 SSH 密钥
- **远程 State** — 通过 tfstate.dev 管理 state，避免本地 .tfstate 文件

## 引用

→ [tecent/ 目录代码](../../tecent/)
