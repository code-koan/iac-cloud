# alibaba

阿里云 IaC 模板设计文档。

## 模板

| 文件 | 说明 |
|------|------|
| [ack.md](ack.md) | ACK 托管版 K8s 集群（带可选默认 / GPU 节点池） |
| [acs.md](acs.md) | ACS Serverless K8s 集群（标准 / Pro 可选） |
| [rds-pg-serverless.md](rds-pg-serverless.md) | RDS PostgreSQL Serverless（按 RCU 计费，仅 VPC 内网） |
| `alibaba/ecs-gpu/` | GPU ECS 单机模板（VPC + 安全组 + Docker user_data，无单独设计文档） |

## 共性约定

- Provider: `aliyun/alicloud ~> 1.230`
- 密钥: `TF_VAR_access_key` / `TF_VAR_secret_key`，禁止 tfvars 硬编码
- State: tfstate.dev HTTP backend（path 分别为 `alibaba-ack` / `alibaba-acs`），鉴权 `TF_HTTP_PASSWORD=<GitHub PAT>`
- kubeconfig: 落盘到模板目录 `./kubeconfig`（权限 0600，已 gitignore）
- 默认 region: `ap-northeast-1`（日本东京）；改 `region` 即切换地域，`zone_ids` 默认为空时按 region 自动取前 3 个可用区
- Addons: 列表式声明，默认含 `gateway-api`
