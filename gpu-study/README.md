# GPU 学习 IaC 模板

快速创建 GPU 云服务器实例的 Terraform 配置，支持三个平台。

## 平台选择

| 平台 | 价格 (参考) | 特点 |
|------|------------|------|
| [AutoDL](autodl/README.md) | ~1.88元/小时 (RTX 4090) | 最便宜，无需 Terraform |
| [阿里云](alibaba/README.md) | ~1.7元/小时 (T4) | 生态完善，Terraform 支持 |
| [火山引擎](volcengine/README.md) | ~1.75元/小时 (A10) | 字节跳动，Terraform 支持 |

## 快速开始

### 1. 选择平台

- **学习/实验**: 推荐 AutoDL，价格最低
- **生产/长期**: 推荐阿里云或火山引擎

### 2. 配置凭据

#### 阿里云

1. 登录 [阿里云控制台](https://console.console.aliyun.com/)
2. 点击右上角头像 → AccessKey 管理
3. 创建 AccessKey（建议使用子用户密钥，权限更小更安全）
4. 设置环境变量:

```bash
export ALICLOUD_ACCESS_KEY="你的AccessKeyId"
export ALICLOUD_SECRET_KEY="你的AccessKeySecret"
```

#### 火山引擎

1. 登录 [火山引擎控制台](https://console.volcengine.com/)
2. 点击右上角头像 → 密钥管理
3. 创建 AccessKey
4. 设置环境变量:

```bash
export VOLCENGINE_ACCESS_KEY="你的AccessKey"
export VOLCENGINE_SECRET_KEY="你的SecretKey"
```

### 3. 运行 Terraform

```bash
# 进入目录
cd alibaba  # 或 volcengine

# 初始化
terraform init

# 预览
terraform plan

# 部署
terraform apply

# 部署完成后获取 SSH 命令
terraform output
```

### 4. 连接实例

```bash
# 使用 output 输出的命令
ssh root@<公网IP>

# 或指定密钥
ssh -i ~/.ssh/id_rsa root@<公网IP>
```

## 项目结构

```
gpu-study/
├── autodl/
│   └── README.md          # AutoDL 操作指南
├── alibaba/
│   ├── main.tf            # Terraform 配置
│   ├── variable.tf        # 变量定义
│   └── README.md          # 阿里云使用指南
└── volcengine/
    ├── main.tf            # Terraform 配置
    ├── variable.tf        # 变量定义
    └── README.md          # 火山引擎使用指南
```

## 配置选项

### 阿里云 (variable.tf)

| 变量 | 默认值 | 说明 |
|------|--------|------|
| region | cn-shanghai | 区域 |
| instance_type | ecs.gn6i-c4g1.2xlarge | 实例规格 (T4) |
| instance_name | gpu-llm-training | 实例名称 |
| ssh_public_key_file | ~/.ssh/id_rsa.pub | SSH 公钥 |

### 火山引擎 (variable.tf)

| 变量 | 默认值 | 说明 |
|------|--------|------|
| region | cn-beijing | 区域 |
| instance_type | gpu.g3.large | 实例规格 (T4) |
| instance_name | gpu-llm-training | 实例名称 |
| ssh_public_key_file | ~/.ssh/id_rsa.pub | SSH 公钥 |

## 实例规格参考

### 阿里云

- `ecs.gn6i-c4g1.2xlarge` - T4 (16GB 显存)
- `ecs.gn6v-c8g1.2xlarge` - V100 (16GB 显存)
- `ecs.gn7i-c8g1.2xlarge` - A10 (24GB 显存)

### 火山引擎

- `gpu.g3.large` - T4 (16GB 显存)
- `gpu.g2.large` - A10 (24GB 显存)
- `gpu.g1.large` - V100 (32GB 显存)

## 注意事项

1. **按量付费**: 当前配置为按量付费，实例释放后停止计费
2. **SSH 密钥**: 默认使用 `~/.ssh/id_rsa.pub`，确保该文件存在
3. **费用**: 使用完成后记得运行 `terraform destroy` 释放资源
