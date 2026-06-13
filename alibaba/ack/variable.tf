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
  default     = "ap-northeast-1"
}

variable "zone_ids" {
  description = "可用区列表。留空则按 region 自动选择前 3 个可用区"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "集群名称"
  type        = string
  default     = "ack-demo"
}

variable "k8s_version" {
  description = "Kubernetes 版本"
  type        = string
  default     = "1.30.1-aliyun.1"
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "Pod 网段"
  type        = string
  default     = "172.16.0.0/16"
}

variable "service_cidr" {
  description = "Service 网段"
  type        = string
  default     = "192.168.0.0/16"
}

variable "key_name" {
  description = "节点 SSH 密钥对名（空则不绑）"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# 节点池
# ----------------------------------------------------------------------------
variable "enable_default_node_pool" {
  description = "是否创建默认节点池"
  type        = bool
  default     = true
}

variable "default_pool" {
  description = "默认节点池配置"
  type = object({
    instance_types = list(string)
    desired_size   = number
    disk_size      = number
  })
  default = {
    instance_types = ["ecs.g6.large"]
    desired_size   = 2
    disk_size      = 60
  }
}

variable "enable_gpu_node_pool" {
  description = "是否创建 GPU 节点池"
  type        = bool
  default     = false
}

variable "gpu_pool" {
  description = "GPU 节点池配置"
  type = object({
    instance_types = list(string)
    desired_size   = number
    disk_size      = number
  })
  default = {
    instance_types = ["ecs.gn6i-c4g1.xlarge"]
    desired_size   = 1
    disk_size      = 100
  }
}

# ----------------------------------------------------------------------------
# Addons
# ----------------------------------------------------------------------------
variable "addons" {
  description = <<-EOT
    集群 addon 列表。每项 { name, config?, disabled? }，disabled=true 时跳过安装。
    默认启用 ALB Ingress + Gateway API；监控/告警/日志/安全等组件预置但 disabled=true，按需开启。
    完整组件清单：https://help.aliyun.com/zh/ack/product-overview/component-overview
    注意：网络插件（terway/flannel）/ CSI / CoreDNS / kube-proxy 由 ACK 控制台默认安装，不在此列表。
  EOT
  type = list(object({
    name     = string
    config   = optional(string, "")
    disabled = optional(bool, false)
  }))
  default = [
    # ---- 网络（Networking） ----
    { name = "gateway-api" },            # Gateway API CRD + ALB GatewayClass
    { name = "alb-ingress-controller" }, # ALB Ingress Controller

    # ---- 监控（Observability - Metrics） ----
    { name = "metrics-server", disabled = true },            # HPA / kubectl top
    { name = "arms-prometheus", disabled = true },           # 阿里云 Prometheus（ARMS）
    { name = "ack-node-problem-detector", disabled = true }, # 节点/Pod 异常事件上报

    # ---- 告警 / 事件（Alerting） ----
    { name = "alicloud-monitor-controller", disabled = true }, # 云监控告警 + 事件中心

    # ---- 日志（Logging） ----
    { name = "logtail-ds", disabled = true }, # SLS 日志采集（DaemonSet）

    # ---- 安全（Security） ----
    { name = "security-inspector", disabled = true }, # 集群安全巡检
    { name = "gatekeeper", disabled = true },         # OPA 策略准入

    # ---- 调度 / 弹性（Scheduling） ----
    { name = "ack-virtual-node", disabled = true },                # 虚拟节点（ECI 弹性）
    { name = "ack-kubernetes-elastic-workload", disabled = true }, # 弹性工作负载
  ]
}
