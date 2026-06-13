# ACK 托管版 K8s

阿里云 [容器服务 ACK Pro](https://help.aliyun.com/zh/ack/) 模板。带可选的默认 / GPU 节点池。

## 使用

```bash
export TF_VAR_access_key=xxx
export TF_VAR_secret_key=xxx
export TF_HTTP_PASSWORD=<GitHub PAT>   # tfstate.dev 远程 state 鉴权

terraform init
terraform apply

eval "$(terraform output -raw kubectl_cmd)"
kubectl get nodes
```

## State

- 远程 backend: `tfstate.dev` (path: `alibaba-ack`)
- GitHub PAT 通过 `TF_HTTP_PASSWORD` 注入
- 不允许 `terraform.tfstate` 落本地仓库

## 关键变量

详见 [../../.config/alibaba/ack.md](../../.config/alibaba/ack.md)。

- `enable_default_node_pool` / `default_pool`
- `enable_gpu_node_pool` / `gpu_pool`（GPU 节点带 `nvidia.com/gpu` taint）
- `addons` — 默认启用 `gateway-api` + `alb-ingress-controller`；监控/告警/日志/安全等组件预置但 `disabled=true`，按需开启。完整列表见 [ACK 组件总览](https://help.aliyun.com/zh/ack/product-overview/component-overview)
- `key_name` — 节点 SSH 密钥对（可选）

## 销毁

```bash
terraform destroy
```
