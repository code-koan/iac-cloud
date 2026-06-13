# ACS Serverless K8s

模板路径: `alibaba/acs/`

## 资源拓扑

```
VPC (10.0.0.0/16)
 └── vSwitch × N (每个 zone 一个, 10.0.<i>.0/24)
      └── alicloud_cs_managed_kubernetes  (profile=Acs, 标准/Pro 可切)
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
| `addons` | list(object) | 见下表 | 默认仅启用 `gateway-api`，其余预置但 `disabled=true`，按需开启 |

### 预置 addon 速查

| 组件 | 类别 | 默认 | 用途 |
|------|------|------|------|
| `gateway-api` | 网络 | ✅ enabled | Gateway API CRD + ALB GatewayClass |
| `alb-ingress-controller` | 网络 | ✅ enabled | 基于阿里云 ALB 的 K8s Ingress 实现 |
| `metrics-server` | 监控 | ❌ disabled | HPA / `kubectl top` 必备 |
| `arms-prometheus` | 监控 | ❌ disabled | 阿里云 Prometheus（ARMS） |
| `ack-node-problem-detector` | 监控 | ❌ disabled | 节点/Pod 异常事件上报 |
| `alicloud-monitor-controller` | 告警 | ❌ disabled | 云监控告警 + 事件中心 |
| `logtail-ds` | 日志 | ❌ disabled | SLS 日志采集（ACS 上 DaemonSet 形态受限） |
| `security-inspector` | 安全 | ❌ disabled | 集群安全巡检 |
| `gatekeeper` | 安全 | ❌ disabled | OPA 策略准入 |
| `ack-virtual-node` | 调度 | ❌ disabled | 虚拟节点（ACS 默认已是 ECI，通常无需） |
| `ack-kubernetes-elastic-workload` | 调度 | ❌ disabled | 弹性工作负载 |

> **托管不暴露**：`CoreDNS` / `kube-proxy` / CSI（云盘/NAS/OSS provisioner）由 ACS 控制面托管，不在 addons 中。
>
> 完整清单：<https://help.aliyun.com/zh/cs/user-guide/component-overview>

## 输出

- `cluster_id`, `cluster_endpoint`
- `kubeconfig_path`, `kubectl_cmd`
- `vpc_id`, `vswitch_ids`
- `installed_addons`

## 校验规则

- `zone_ids` 长度 < 2 → 报错

## destroy 行为

集群资源里写了 `delete_options`（provider v1.223.2+）：
- `SLB` → `delete`（Nginx Ingress 创建的 SLB 一并清理，默认行为，显式声明）
- `ALB` → `delete`（ALB Ingress / Gateway API 创建的 ALB 一并清理，**官方默认是 retain**，本模板显式改成 delete）

> 该选项**必须先 `terraform apply` 写入集群配置**，再 `destroy` 才生效。如果集群是更早版本创建的（state 里没有 delete_options），需要先 apply 一次。

> 残留 ENI / Pod ENI / NAT 网关 不在 delete_options 管辖范围，destroy 卡 vSwitch 时仍需要手动到控制台清。

## Provider 注意

使用 `alicloud_cs_managed_kubernetes` 统一资源 + `profile = "Acs"` 创建 ACS 集群（旧的 `alicloud_cs_serverless_kubernetes` 自 provider v1.276.0 起被标记 deprecated）。字段映射：
- `endpoint_public_access_enabled` → `slb_internet_enabled`
- `time_zone` → `timezone`
- `vpc_id` 不再需要（由 `vswitch_ids` 推导）
- `addons` / `cluster_spec` / `service_cidr` / `deletion_protection` 同名

> ⚠️ 已存在的 ACS 集群（旧 `alicloud_cs_serverless_kubernetes` 资源 state）切换到此模板时，因 `profile` 是 `ForceNew`，会触发重建。请先 `terraform state mv` 或在 backend 中清空 state 后重新 import。

## 使用

```bash
export TF_VAR_access_key=xxx TF_VAR_secret_key=xxx
cd alibaba/acs
terraform init && terraform apply
eval "$(terraform output -raw kubectl_cmd)"
kubectl get pods -A
```
