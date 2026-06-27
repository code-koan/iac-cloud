terraform {
  required_version = ">= 1.5"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230"
    }
  }

  # 远程 state — 阿里云 OSS（凭据走 ALICLOUD_ACCESS_KEY / ALICLOUD_SECRET_KEY 环境变量）
  backend "oss" {
    bucket  = "makeit-agi"
    prefix  = "iac/state/rds-pg-serverless"
    key     = "terraform.tfstate"
    region  = "cn-hongkong"
    encrypt = true
  }
}

provider "alicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# ----------------------------------------------------------------------------
# 可用区解析
# ----------------------------------------------------------------------------
data "alicloud_zones" "default" {
  available_resource_creation = "Rds"
}

# 复用 existing VPC 时查它真实 cidr，作为白名单 fallback
data "alicloud_vpcs" "existing" {
  count = var.existing_vpc_id != null ? 1 : 0
  ids   = [var.existing_vpc_id]
}

# 复用 existing VPC 时枚举其内所有 vsw，用于自动挑选
data "alicloud_vswitches" "in_vpc" {
  count  = var.existing_vpc_id != null ? 1 : 0
  vpc_id = var.existing_vpc_id
}

locals {
  # 用户给了 existing_vpc_id 即进入复用分支
  use_existing_vpc = var.existing_vpc_id != null

  # RDS 支持的 zone 集合
  rds_zone_ids = toset([for z in data.alicloud_zones.default.zones : z.id])

  # 复用分支：VPC 内候选 vsw
  vpc_vswitches = local.use_existing_vpc ? data.alicloud_vswitches.in_vpc[0].vswitches : []

  # 用户显式给了 vsw_id → 用之；否则按 (RDS 支持 zone ∩ 用户 zone_ids 过滤) 取首个
  picked_vswitch = !local.use_existing_vpc ? null : (
    var.existing_vswitch_id != null
    ? one([for v in local.vpc_vswitches : v if v.id == var.existing_vswitch_id])
    : try([
      for v in local.vpc_vswitches : v
      if contains(local.rds_zone_ids, v.zone_id)
      && (length(var.zone_ids) == 0 || contains(var.zone_ids, v.zone_id))
    ][0], null)
  )

  vpc_id     = local.use_existing_vpc ? var.existing_vpc_id : alicloud_vpc.main[0].id
  vswitch_id = local.use_existing_vpc ? local.picked_vswitch.id : alicloud_vswitch.main[0].id

  # 复用 vsw 时 zone 必须以 vsw 为准，否则 RDS create 报 ZoneId mismatch
  effective_zone_id = (
    local.picked_vswitch != null ? local.picked_vswitch.zone_id :
    length(var.zone_ids) > 0 ? var.zone_ids[0] :
    data.alicloud_zones.default.zones[0].id
  )

  # 当前 VPC 的网段：复用时从 data source 拿，新建时用 vpc_cidr
  current_vpc_cidr = local.use_existing_vpc ? data.alicloud_vpcs.existing[0].vpcs[0].cidr_block : var.vpc_cidr

  # security_ips 默认只放当前 VPC 网段；用户显式传入则覆盖
  effective_security_ips = var.security_ips != null ? var.security_ips : [local.current_vpc_cidr]

  # for_each key 用 name
  databases_map = { for d in var.databases : d.name => d }
}

# ----------------------------------------------------------------------------
# 网络（仅在不复用时新建）
# ----------------------------------------------------------------------------
resource "alicloud_vpc" "main" {
  count      = local.use_existing_vpc ? 0 : 1
  vpc_name   = "${var.instance_name}-vpc"
  cidr_block = var.vpc_cidr
}

resource "alicloud_vswitch" "main" {
  count        = local.use_existing_vpc ? 0 : 1
  vpc_id       = alicloud_vpc.main[0].id
  cidr_block   = cidrsubnet(var.vpc_cidr, 8, 0)
  zone_id      = local.effective_zone_id
  vswitch_name = "${var.instance_name}-vsw"
}

# ----------------------------------------------------------------------------
# RDS PostgreSQL Serverless 实例
#
# 关键字段（来源：aliyun/terraform-provider-alicloud db_instance 官方文档）：
#   - category       = "serverless_basic"      Serverless 单节点（双 AZ HA = serverless_standard，~2x 价）
#   - instance_type  = "pg.n2.serverless.1c"   官方文档明确给出的 PG Serverless basic 唯一值
#   - charge_type    = "Serverless"            走 RCU 计费
#   - storage_type   = "cloud_essd"            Serverless 强制 essd
#   - engine_version Serverless 仅支持 14/15/16/17（PG 18 暂未纳入 Serverless）
#   - auto_pause     闲时 0 RCU（最关键省钱开关）
#   - min/max_capacity  0.5 / 8 起步
#
# 后续按需加（暂不做）：双 AZ 高可用 / 备份策略 / 公网连接 / 只读副本
# ----------------------------------------------------------------------------
resource "alicloud_db_instance" "this" {
  instance_name            = var.instance_name
  engine                   = "PostgreSQL"
  engine_version           = var.engine_version
  instance_type            = "pg.n2.serverless.1c"
  instance_storage         = var.storage_gb
  db_instance_storage_type = "cloud_essd"
  category                 = "serverless_basic"
  instance_charge_type     = "Serverless"
  vswitch_id               = local.vswitch_id
  zone_id                  = local.effective_zone_id

  # 仅 VPC 内网：白名单默认只放当前 VPC 网段（var.security_ips 为 null 时）
  # security_ip_mode = "safety"
  security_ips = local.effective_security_ips

  serverless_config {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
    auto_pause   = var.auto_pause
    switch_force = var.switch_force
  }

  lifecycle {
    precondition {
      condition     = !local.use_existing_vpc || local.picked_vswitch != null
      error_message = "existing_vpc_id 已给定但 VPC 内无可用 vSwitch：zone_ids=${jsonencode(var.zone_ids)}，RDS 支持的 zone=${jsonencode(local.rds_zone_ids)}。请检查 VPC 内是否有匹配 zone 的 vsw，或显式指定 existing_vswitch_id / 调整 zone_ids。"
    }
  }
}

# ----------------------------------------------------------------------------
# 库 + 账号 + 授权（每个 database 一组，按 name 关联）
# ----------------------------------------------------------------------------
resource "alicloud_db_database" "this" {
  for_each       = local.databases_map
  instance_id    = alicloud_db_instance.this.id
  data_base_name = each.value.name
  character_set  = "UTF8"
}

resource "alicloud_rds_account" "this" {
  for_each         = local.databases_map
  db_instance_id   = alicloud_db_instance.this.id
  account_name     = each.value.account
  account_password = var.database_passwords[each.key]
  account_type     = "Normal"
}

# 把账号授予对应库（PG 上 OwnerPrivilege = 该库 owner，可建表 / 装扩展）
resource "alicloud_db_account_privilege" "this" {
  for_each     = local.databases_map
  instance_id  = alicloud_db_instance.this.id
  account_name = alicloud_rds_account.this[each.key].account_name
  privilege    = "DBOwner"
  db_names     = [alicloud_db_database.this[each.key].data_base_name]
}
