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
| `addons` | list(object) | 见下表 | 默认启用 ALB Ingress + Gateway API；其余预置但 `disabled=true` |

### 预置 addon 速查

| 组件 | 类别 | 默认 | 用途 |
|------|------|------|------|
| `gateway-api` | 网络 | ✅ enabled | Gateway API CRD + ALB GatewayClass |
| `alb-ingress-controller` | 网络 | ✅ enabled | 基于阿里云 ALB 的 K8s Ingress 实现 |
| `metrics-server` | 监控 | ❌ disabled | HPA / `kubectl top` |
| `arms-prometheus` | 监控 | ❌ disabled | 阿里云 Prometheus（ARMS） |
| `ack-node-problem-detector` | 监控 | ❌ disabled | 节点/Pod 异常事件上报 |
| `alicloud-monitor-controller` | 告警 | ❌ disabled | 云监控告警 + 事件中心 |
| `logtail-ds` | 日志 | ❌ disabled | SLS 日志采集 DaemonSet |
| `security-inspector` | 安全 | ❌ disabled | 集群安全巡检 |
| `gatekeeper` | 安全 | ❌ disabled | OPA 策略准入 |
| `ack-virtual-node` | 调度 | ❌ disabled | 虚拟节点（ECI 弹性） |
| `ack-kubernetes-elastic-workload` | 调度 | ❌ disabled | 弹性工作负载 |

> **不在 addons 列表**：网络插件（terway/flannel）、CSI、CoreDNS、kube-proxy 由 ACK 创建集群时按 provider 后端默认安装，不显式声明。
>
> 完整清单：<https://help.aliyun.com/zh/ack/product-overview/component-overview>

## destroy 行为

集群资源里写了 `delete_options`（provider v1.223.2+）：
- `SLB` → `delete`（Nginx Ingress 创建的 SLB 一并清理）
- `ALB` → `delete`（ALB Ingress / Gateway API 创建的 ALB，**官方默认 retain**，本模板显式改成 delete）

> 必须先 `terraform apply` 写入集群配置后，再 `destroy` 才生效。残留 Pod ENI、NAT 网关 不在管辖内，destroy 卡 vSwitch 时仍需手动到控制台清。

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
