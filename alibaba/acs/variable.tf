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
