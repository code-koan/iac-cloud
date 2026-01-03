# 腾讯云抢占式实例

## 风险
申请资源位抢占实例，存在回收风险

## 配置信息
- 地区：新加坡
- 配置：2c4g
- 系统：ubuntu
- 公网：ipv4 * 1
- 环境配置：docker, 及运行机 ssh 秘钥
- 开发端口：22,80,443,7290

## 使用方式

```shell
export TF_VAR_secret_id="xxx"
export TF_VAR_secret_key="xxx"

# state 管理，借助 github 管理；如果不需要 管理 state ，需注释掉 main.tf 中的 backend 模块
export TF_HTTP_PASSWORD="你的GitHub Token" 

terraform init
terraform plan
terraform apply -auto-approve
```

创建完成会输出 ssh 登录命令

资源清理：
```shell
terraform destory
```

## 最佳实践
将相关服务制作为 docker 镜像，然后存放到对应云服务商的镜像，以便使用内网流量，后在 user-data.sh 中添加相关服务建立脚本，直接做到自动服务创建。
