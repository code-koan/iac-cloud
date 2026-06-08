---
description: 腾讯云抢占式实例 Terraform 模块
---

# tecent

## 文件

| 文件 | 职责 | 设计文档 |
|------|------|----------|
| `main.tf` | VPC、子网、安全组、实例资源定义 | [.config/tecent/_index.md](../.config/tecent/_index.md) |
| `variable.tf` | 区域、实例类型、凭据变量 | — |
| `output.tf` | 实例 IP、SSH 连接信息输出 | — |
| `scripts/user-data.sh` | 实例初始化脚本（Docker 安装、SSH 配置） | — |

## 设计文档

→ [腾讯云模块设计](../.config/tecent/_index.md)
