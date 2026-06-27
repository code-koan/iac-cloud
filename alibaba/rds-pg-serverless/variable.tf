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
      - 中国香港   cn-hongkong
      - 中国北京   cn-beijing
      - 日本东京   ap-northeast-1
      - 新加坡     ap-southeast-1
  EOT
  type        = string
  default     = "cn-hongkong"
}

variable "zone_ids" {
  description = "可用区列表。留空则按 region 自动取首个支持 RDS 的可用区"
  type        = list(string)
  default     = []
}

variable "instance_name" {
  description = "RDS 实例名"
  type        = string
  default     = "makeit-pg"
}

variable "engine_version" {
  description = <<-EOT
    PostgreSQL 大版本。Serverless 当前官方支持 14.0 / 15.0 / 16.0 / 17.0
    （来源：阿里云 OpenAPI CreateDBInstance 文档）。
    PG 18 暂未纳入 Serverless 形态，需要 18 时只能用普通 Postpaid 付费档。
  EOT
  type        = string
  default     = "17.0"
}

variable "storage_gb" {
  description = "存储空间 GB（cloud_essd）"
  type        = number
  default     = 20
}

variable "min_capacity" {
  description = "Serverless RCU 下限（0.5 起步）"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Serverless RCU 上限"
  type        = number
  default     = 8
}

variable "auto_pause" {
  description = "闲时自动暂停（真正按量计费，闲时 0 RCU 计费）"
  type        = bool
  default     = true
}

variable "switch_force" {
  description = "强制切换（serverless 主备切换时使用）"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "新建 VPC 时使用的网段（existing_vpc_id 给定时忽略）"
  type        = string
  default     = "10.1.0.0/16"
}

variable "security_ips" {
  description = <<-EOT
    RDS 白名单 CIDR 列表。
    留 null（默认）时自动收紧到当前 VPC 网段（vpc_cidr 或 existing_vpc_id 对应 VPC 的网段），
    "默认仅 VPC 内网" 语义。需要跨 VPC / 多段访问时显式覆盖此变量。
  EOT
  type        = list(string)
  default     = null
}

variable "existing_vpc_id" {
  description = <<-EOT
    复用已有 VPC 时填；只填这一个即可，vSwitch 会自动从 VPC 内挑（按 RDS 支持的 zone
    与 var.zone_ids 过滤后取首个）。留 null 则新建 VPC。
  EOT
  type        = string
  default     = "vpc-j6celw0z6634bgmktjb71"
}

variable "existing_vswitch_id" {
  description = <<-EOT
    可选；不填时自动从 existing_vpc_id 对应 VPC 内挑符合 zone_ids 和 RDS 支持的 vSwitch。
    显式指定时必须在 existing_vpc_id 对应的 VPC 内（会从该 vsw 的 zone 推导 RDS 的 zone_id）。
  EOT
  type        = string
  default     = null
}

variable "databases" {
  description = <<-EOT
    要创建的 database + 对应账号列表。每项：
      { name = "<db>", account = "<user>" }
    密码独立放在 var.database_passwords 中，按 name 关联。
    为空时不创建任何库 / 账号。
  EOT
  type = list(object({
    name    = string
    account = string
  }))
  default = []
}

variable "database_passwords" {
  description = <<-EOT
    各 database 账号密码，map(string)，key = database name。
    sensitive，建议 export TF_VAR_database_passwords='{"db1":"...","db2":"..."}' 注入。
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}
