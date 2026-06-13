# ACK 托管版 K8s

模板路径: `alibaba/ack/`

## 资源拓扑

```
VPC (10.0.0.0/16)
 └── vSwitch × N (每个 zone 一个, 10.0.<i>.0/24)
      └── alicloud_cs_managed_kubernetes
            ├── default node pool (可选, 普通 ECS)
            └── gpu node pool      (可选, GPU ECS)
```

## 变量速查

| 变量 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `region` | string | `ap-northeast-1` | 默认日本东京；改这里即切换地域 |
| `zone_ids` | list(string) | `[]` | 留空时按 region 自动取前 3 个可用区 |
| `cluster_name` | string | `ack-demo` | |
| `k8s_version` | string | `1.30.1-aliyun.1` | |
| `vpc_cidr` | string | `10.0.0.0/16` | |
| `pod_cidr` | string | `172.16.0.0/16` | |
| `service_cidr` | string | `192.168.0.0/16` | |
| `key_name` | string | `""` | 节点 SSH 密钥对名（空则不绑） |
| `enable_default_node_pool` | bool | `true` | |
| `default_pool` | object | `ecs.g6.large × 2, 60GB` | |
| `enable_gpu_node_pool` | bool | `false` | |
| `gpu_pool` | object | `ecs.gn6i-c4g1.xlarge × 1, 100GB` | |
| `addons` | list(object) | `[{name="gateway-api"}]` | |

## 输出

- `cluster_id`, `cluster_endpoint`
- `kubeconfig_path`, `kubectl_cmd`
- `vpc_id`, `vswitch_ids`
- `worker_ram_role_name`
- `default_node_pool_id`（条件）
- `gpu_node_pool_id`（条件）
- `installed_addons`

## 使用

```bash
export TF_VAR_access_key=xxx TF_VAR_secret_key=xxx
cd alibaba/ack
terraform init && terraform apply
eval "$(terraform output -raw kubectl_cmd)"
kubectl get nodes
```
