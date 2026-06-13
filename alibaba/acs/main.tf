terraform {
  required_version = ">= 1.5"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # 远程 state — tfstate.dev (GitHub 账号鉴权)
  # TF_HTTP_PASSWORD=<GitHub PAT> 传入
  backend "http" {
    address        = "https://api.tfstate.dev/github/v1/alibaba-acs"
    lock_address   = "https://api.tfstate.dev/github/v1/alibaba-acs/lock"
    unlock_address = "https://api.tfstate.dev/github/v1/alibaba-acs/lock"
    lock_method    = "PUT"
    unlock_method  = "DELETE"
    username       = "code-koan/iac-cloud"
  }
}

provider "alicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# ----------------------------------------------------------------------------
# 校验 + 可用区解析
# ----------------------------------------------------------------------------
data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

locals {
  addon_names  = [for a in var.addons : a.name if !a.disabled]
  cluster_spec = var.acs_pro ? "ack.pro.small" : "ack.standard"

  # zone_ids 留空时，按 region 自动取前 3 个可用区
  effective_zone_ids = length(var.zone_ids) > 0 ? var.zone_ids : slice(
    data.alicloud_zones.default.zones[*].id,
    0,
    min(3, length(data.alicloud_zones.default.zones))
  )
}

resource "terraform_data" "validate" {
  lifecycle {
    precondition {
      condition     = length(local.effective_zone_ids) >= 2
      error_message = "ACS 至少需要 2 个可用区，但当前 region 自动解析到的可用区不足 2 个，请显式传 zone_ids。"
    }
  }
}

# ----------------------------------------------------------------------------
# 网络
# ----------------------------------------------------------------------------
resource "alicloud_vpc" "main_vpc" {
  vpc_name   = "${var.cluster_name}-vpc"
  cidr_block = var.vpc_cidr
}

resource "alicloud_vswitch" "cluster_vswitch" {
  count        = length(local.effective_zone_ids)
  vpc_id       = alicloud_vpc.main_vpc.id
  cidr_block   = cidrsubnet(var.vpc_cidr, 8, count.index)
  zone_id      = local.effective_zone_ids[count.index]
  vswitch_name = "${var.cluster_name}-vsw-${count.index}"
}

# ----------------------------------------------------------------------------
# ACS 集群（基于统一资源 alicloud_cs_managed_kubernetes，profile=Acs）
# ----------------------------------------------------------------------------
resource "alicloud_cs_managed_kubernetes" "this" {
  name                 = var.cluster_name
  profile              = "Acs"
  cluster_spec         = local.cluster_spec
  vswitch_ids          = alicloud_vswitch.cluster_vswitch[*].id
  service_cidr         = var.service_cidr
  slb_internet_enabled = var.endpoint_public_access
  timezone             = var.time_zone
  deletion_protection  = var.deletion_protection

  dynamic "addons" {
    for_each = { for a in var.addons : a.name => a if !a.disabled }
    content {
      name   = addons.value.name
      config = addons.value.config
    }
  }

  # destroy 时连带清理集群拉起的 SLB / ALB，避免残留 ENI 把 vSwitch 锁住
  # （需先 apply 写入集群配置；ALB 默认 retain，必须显式改 delete）
  delete_options {
    delete_mode   = "delete"
    resource_type = "SLB"
  }
  delete_options {
    delete_mode   = "delete"
    resource_type = "ALB"
  }

  depends_on = [terraform_data.validate]
}

# ----------------------------------------------------------------------------
# kubeconfig 落盘
# ----------------------------------------------------------------------------
data "alicloud_cs_cluster_credential" "this" {
  cluster_id = alicloud_cs_managed_kubernetes.this.id
}

resource "local_sensitive_file" "kubeconfig" {
  content         = data.alicloud_cs_cluster_credential.this.kube_config
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}
