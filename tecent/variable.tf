variable "secret_id" {}

variable "secret_key" {}

variable "region" {
  description = "腾讯云地域"
  type        = string
  default     = "ap-singapore"
}

variable "availability_zone" {
  description = "可用区"
  type        = string
  default     = "ap-singapore-1"
}

variable "instance_name" {
  description = "实例名称"
  type        = string
  default     = "docker-spot-instance"
}

variable "instance_type" {
  description = "实例类型"
  type        = string
  default     = "S5.MEDIUM2"
}

variable "key_pair_name" {
  description = "SSH 密钥对名称"
  type        = string
  default     = "my_singapore_key"
}

# 自动 ssh 私钥配置
locals {
  private_key_base64 = base64encode(file("~/.ssh/id_rsa"))
#   private_key_base64 = "123"

  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh", {
    container_port      = 7290,
    private_key_base64  = local.private_key_base64
  }))
}
