variable "region" {
  description = "阿里云区域"
  type        = string
  default     = "cn-shanghai"
}

variable "instance_type" {
  description = "GPU实例规格 (ecs.gn6i-c4g1.2xlarge = T4, ecs.gn6v-c8g1.2xlarge = V100)"
  type        = string
  default     = "ecs.gn6i-c4g1.2xlarge"
}

variable "instance_name" {
  description = "实例名称"
  type        = string
  default     = "gpu-llm-training"
}

variable "ssh_public_key_file" {
  description = "SSH 公钥文件路径"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
