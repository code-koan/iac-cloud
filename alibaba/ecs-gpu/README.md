# ecs-gpu

阿里云 GPU ECS 单机模板（VPC + 安全组 + 一台 GPU 实例 + Docker user_data）。

> 注：与 `gpu-study/alibaba/` 是相近用途的不同模板（前者更通用，后者是 GPU 学习专用），保留两份是历史原因。如不再需要，可考虑后续合并。

## 使用

```bash
export TF_VAR_access_key=xxx   # 或在 provider 里手动传
export TF_VAR_secret_key=xxx

terraform init
terraform apply

terraform output ssh_command
```
