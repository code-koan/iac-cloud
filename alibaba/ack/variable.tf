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
  description = "阿里云区域。改这里即可切换地域，例如 cn-shanghai / cn-beijing / cn-shenzhen / ap-southeast-1"
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
  description = "集群 addon 列表"
  type = list(object({
    name     = string
    config   = optional(string, "")
    disabled = optional(bool, false)
  }))
  default = [
    { name = "gateway-api" },
  ]
}
