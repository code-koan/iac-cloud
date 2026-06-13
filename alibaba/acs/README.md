# ACS Serverless K8s

阿里云 [容器计算服务 ACS](https://help.aliyun.com/zh/cs/acs/) 模板。Serverless，无节点，按 Pod 算力计费。

## 使用

```bash
export TF_VAR_access_key=xxx
export TF_VAR_secret_key=xxx
export TF_HTTP_PASSWORD=<GitHub PAT>   # tfstate.dev 远程 state 鉴权

terraform init
terraform apply

eval "$(terraform output -raw kubectl_cmd)"
kubectl get ns
```

## State

- 远程 backend: `tfstate.dev` (path: `alibaba-acs`)
- GitHub PAT 通过 `TF_HTTP_PASSWORD` 注入
- 不允许 `terraform.tfstate` 落本地仓库

## 关键变量

详见 [../../.config/alibaba/acs.md](../../.config/alibaba/acs.md)。

- `acs_pro` — Pro 版开关（`true=ack.pro.small` / `false=ack.standard`）
- `addons` — 默认仅启用 `gateway-api`；其余组件（metrics-server / arms-prometheus / alicloud-monitor-controller / logtail-ds 等）预置但 `disabled=true`，按需开启。完整列表见 [阿里云组件总览](https://help.aliyun.com/zh/cs/user-guide/component-overview)
- `zone_ids` — 至少 2 个可用区

## 开启可选 addon 示例

```bash
# 临时打开监控全家桶
terraform apply \
  -var='addons=[
    {"name":"gateway-api"},
    {"name":"metrics-server"},
    {"name":"arms-prometheus"},
    {"name":"alicloud-monitor-controller"}
  ]'
```

> ACS Serverless 的 **CoreDNS / kube-proxy / CSI** 由控制面托管，不在 addons 暴露，PVC / Service DNS 直接可用。

## 销毁

```bash
terraform destroy
```
