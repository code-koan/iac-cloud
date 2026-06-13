# ACS Serverless K8s

模板路径: `alibaba/acs/`

## 资源拓扑

```
VPC (10.0.0.0/16)
 └── vSwitch × N (每个 zone 一个, 10.0.<i>.0/24)
      └── alicloud_cs_serverless_kubernetes  (标准 / Pro 可切)
            └── 全部 Pod 走 ECI，无节点
```

## 变量速查

| 变量 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `region` | string | `ap-northeast-1` | 默认日本东京；改这里即切换地域 |
| `zone_ids` | list(string) | `[]` | 留空时按 region 自动取前 3 个；ACS 至少 2 个 |
| `cluster_name` | string | `acs-demo` | |
| `vpc_cidr` | string | `10.0.0.0/16` | |
| `service_cidr` | string | `192.168.0.0/16` | |
| `acs_pro` | bool | `false` | true=`ack.pro.small`，false=`ack.standard` |
| `endpoint_public_access` | bool | `true` | API Server 公网访问 |
| `time_zone` | string | `Asia/Shanghai` | |
| `deletion_protection` | bool | `false` | |
| `addons` | list(object) | `[{name="gateway-api"}]` | gateway-api 需要 `acs_pro=true` |

## 输出

- `cluster_id`, `cluster_endpoint`
- `kubeconfig_path`, `kubectl_cmd`
- `vpc_id`, `vswitch_ids`
- `installed_addons`

## 校验规则

- `gateway-api` ∈ `addons` && `acs_pro == false` → 报错（precondition）
- `zone_ids` 长度 < 2 → 报错

## Provider 注意

`alicloud_cs_serverless_kubernetes` 在 provider v1.276.0 后被标记 deprecated，未来会迁移到 `alicloud_cs_managed_kubernetes`（统一资源）。当前模板仍使用旧资源，验证通过；待 provider 完成切换后再升级。

## 使用

```bash
export TF_VAR_access_key=xxx TF_VAR_secret_key=xxx
cd alibaba/acs
terraform init && terraform apply
eval "$(terraform output -raw kubectl_cmd)"
kubectl get pods -A
```
