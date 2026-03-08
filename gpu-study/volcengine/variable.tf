variable "region" {
  description = "火山引擎区域"
  type        = string
  default     = "cn-beijing"
}

variable "instance_type" {
  description = "GPU实例规格 (gpu.g3.large = T4, gpu.g2.large = A10)"
  type        = string
  default     = "gpu.g3.large"
}

variable "instance_name" {
  description = "实例名称"
  type        = string
  default     = "gpu-llm-training"
}
