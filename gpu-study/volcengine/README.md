# 火山引擎 GPU Terraform 配置

使用 Terraform 创建火山引擎 GPU 实例。

## 前置要求

1. 安装 Terraform: `brew install terraform`
2. 获取火山引擎 AccessKey

## 获取 AccessKey

1. 登录 [火山引擎控制台](https://console.volcengine.com/)
2. 点击右上角头像 → 密钥管理
3. 创建 AccessKey

## 配置凭据

```bash
export VOLCENGINE_ACCESS_KEY="你的AccessKey"
export VOLCENGINE_SECRET_KEY="你的SecretKey"
```

## 使用方法

```bash
# 进入目录
cd gpu-study/volcengine

# 初始化
terraform init

# 预览
terraform plan

# 部署
terraform apply

# 查看输出
terraform output

# 销毁资源
terraform destroy
```

## 配置选项

运行 `terraform plan` 时可以指定变量:

```bash
# 指定区域
terraform plan -var region=cn-beijing

# 指定实例类型
terraform plan -var instance_type=gpu.g3.large

# 指定实例名称
terraform plan -var instance_name=my-gpu-server
```

## SSH 登录

部署完成后，使用 output 输出的命令登录:

```bash
ssh root@<公网IP>
# 或指定密钥
ssh -i ~/.ssh/id_rsa root@<公网IP>
```

## 实例规格

| 规格 | GPU | 显存 | 价格参考 |
|------|-----|------|----------|
| gpu.g3.large | T4 | 16GB | ~1.75元/小时 |
| gpu.g2.large | A10 | 24GB | ~2元/小时 |
| gpu.g1.large | V100 | 32GB | ~3元/小时 |

## 注意事项

1. 按量付费实例，释放后停止计费
2. 确保 SSH 公钥文件存在 (`~/.ssh/id_rsa.pub`)
3. 使用完成后运行 `terraform destroy` 释放资源
