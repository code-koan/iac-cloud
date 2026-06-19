# iac cloud
> 基于 iac 模版，快速新建云服务商基础设施。

## 资源清单
1. tecent: 腾讯云抢占式实例
2. alibaba/ack: 阿里云 ACK 托管 K8s
3. alibaba/acs: 阿里云 ACS Serverless K8s
4. alibaba/ecs-gpu: 阿里云 GPU ECS 单机


## 秘钥管理
基于 [TFstate.dev](https://tfstate.dev/) 管理 terraform state 秘钥
通过 `terraform state pull` 拉取远端 state

## 贡献者上手

```bash
# 安装本仓库的 git hooks（仅 fmt-check on commit）
make lint-install

# 平时开发
make fmt           # 自动格式化
make lint          # fmt-check + validate 全仓
```

> git hook 只跑 fmt（轻量、纯本地）。`terraform validate` 依赖 provider 下载，不进 hook，由 CI 跑。

## TODO

- [ ] **CI**：加 GitHub Actions，PR 触发 `terraform fmt -check` + `terraform validate` + `terraform plan`（dummy 凭证或只读 AK），覆盖所有 `.tf` 模块。Hook 删除后这是回归保护的唯一手段。
