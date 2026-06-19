variable "access_key" {
  description = "阿里云 AccessKey ID（建议 export TF_VAR_access_key）"
  type        = string
  sensitive   = true
  default     = null
}

variable "secret_key" {
  description = "阿里云 AccessKey Secret（建议 export TF_VAR_secret_key）"
  type        = string
  sensitive   = true
  default     = null
}

variable "region" {
  description = <<-EOT
    阿里云区域。改这里即可切换地域。常用：
      - 日本东京   ap-northeast-1
      - 中国北京   cn-beijing
      - 中国成都   cn-chengdu
      - 中国香港   cn-hongkong
      - 新加坡     ap-southeast-1
  EOT
  type        = string
  # default     = "ap-northeast-1"
  default = "cn-hongkong"
}

variable "zone_ids" {
  description = "可用区列表。留空则按 region 自动选择前 3 个可用区（ACS 至少 2 个）"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "集群名称"
  type        = string
  default     = "acs-demo"
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "10.0.0.0/16"
}

variable "service_cidr" {
  description = "Service 网段，不可与 VPC 重叠"
  type        = string
  default     = "192.168.0.0/16"
}

variable "acs_pro" {
  description = "true=ack.pro.small（Pro 版），false=ack.standard"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "是否开启 API Server 公网访问"
  type        = bool
  default     = true
}

variable "time_zone" {
  description = "时区"
  type        = string
  default     = "Asia/Shanghai"
}

variable "deletion_protection" {
  description = "是否开启删除保护"
  type        = bool
  default     = false
}

variable "addons" {
  description = <<-EOT
    集群 addon 列表。每项 { name, config?, disabled? }，disabled=true 时跳过安装。
    默认仅启用 gateway-api，其余组件预置在列表中但 disabled=true，按需开启。
    完整组件清单：https://help.aliyun.com/zh/cs/user-guide/component-overview
    注意：ACS Serverless 的 CSI、CoreDNS、kube-proxy 由阿里云在控制面托管，
    不在 addons 中暴露；这里只列用户可显式开关的组件。
  EOT
  type = list(object({
    name     = string
    config   = optional(string, "")
    disabled = optional(bool, false)
  }))
  default = [
    # ---- 网络（Networking） ----
    { name = "gateway-api" },            # Gateway API CRD + ALB GatewayClass
    { name = "alb-ingress-controller" }, # ALB Ingress Controller（基于 ALB 的 K8s Ingress 实现）

    # ---- 监控（Observability - Metrics） ----
    { name = "metrics-server" },                             # HPA / kubectl top 必备
    { name = "arms-prometheus" },                            # 阿里云 Prometheus（ARMS）
    { name = "ack-node-problem-detector", disabled = true }, # 节点/Pod 异常事件上报

    # ---- 告警 / 事件（Alerting） ----
    { name = "alicloud-monitor-controller", disabled = true }, # 云监控告警 + 事件中心

    # ---- 日志（Logging） ----
    { name = "logtail-ds" }, # SLS 日志采集（ACS 上需配合 Pod 注解，DaemonSet 形态受限）

    { name = "ack-workflow" }, # SLS 日志采集（ACS 上需配合 Pod 注解，DaemonSet 形态受限）

    # ---- 存储（Storage） ----
    # ACS Serverless 的 CSI 由控制面托管，无需也不能装 csi-plugin / csi-provisioner。
    # 如需 OSS/NAS 静态卷，直接建 StorageClass + PVC 即可。

    # ---- 安全（Security） ----
    { name = "security-inspector", disabled = true }, # 集群安全巡检
    { name = "gatekeeper", disabled = true },         # OPA 策略准入

    # ---- 调度 / 弹性（Scheduling） ----
    { name = "ack-virtual-node", disabled = true },                # 虚拟节点（ECI 弹性，ACS 默认已是 ECI，通常不需要）
    { name = "ack-kubernetes-elastic-workload", disabled = true }, # 弹性工作负载
  ]
}
