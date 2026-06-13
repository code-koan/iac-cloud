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

- `acs_pro` — Pro 版开关，`gateway-api` addon 必须 Pro
- `addons` — 默认 `[{name="gateway-api"}]`
- `zone_ids` — 至少 2 个可用区

## 销毁

```bash
terraform destroy
```
