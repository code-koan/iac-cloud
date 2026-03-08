# 阿里云 GPU Terraform 配置

使用 Terraform 创建阿里云 GPU 实例。

## 前置要求

1. 安装 Terraform: `brew install terraform`
2. 获取阿里云 AccessKey

## 获取 AccessKey

1. 登录 [阿里云控制台](https://console.console.aliyun.com/)
2. 点击右上角头像 → AccessKey 管理
3. 创建 AccessKey（建议使用子用户密钥）

## 配置凭据

```bash
export ALICLOUD_ACCESS_KEY="你的AccessKeyId"
export ALICLOUD_SECRET_KEY="你的AccessKeySecret"
```

## 使用方法

```bash
# 进入目录
cd gpu-study/alibaba

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
terraform plan -var region=cn-shanghai

# 指定实例类型
terraform plan -var instance_type=ecs.gn6i-c4g1.2xlarge

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
| ecs.gn6i-c4g1.2xlarge | T4 | 16GB | ~1.7元/小时 |
| ecs.gn6v-c8g1.2xlarge | V100 | 16GB | ~3.8元/小时 |
| ecs.gn7i-c8g1.2xlarge | A10 | 24GB | ~2元/小时 |

## 注意事项

1. 按量付费实例，释放后停止计费
2. 确保 SSH 公钥文件存在 (`~/.ssh/id_rsa.pub`)
3. 使用完成后运行 `terraform destroy` 释放资源
