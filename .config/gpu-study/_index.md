# gpu-study

GPU 学习环境的 IaC 模板，支持三个平台。

## 子领域

| 子领域 | 路径 | 说明 |
|--------|------|------|
| alibaba | `gpu-study/alibaba/` | 阿里云 GPU 实例 Terraform 配置 |
| autodl | `gpu-study/autodl/` | AutoDL 操作指南与连接脚本 |
| volcengine | `gpu-study/volcengine/` | 火山引擎 GPU 实例 Terraform 配置 |

## 设计原则

- 按量付费，不绑定包年包月
- SSH 密钥复用本地 `~/.ssh/id_rsa.pub`
- 最小化配置，原则上每个子目录只有 main.tf + variable.tf

## 引用

→ [gpu-study/ 目录代码](../../gpu-study/)
