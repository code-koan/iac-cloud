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
    address        = "https://api.tfstate.dev/github/v1/alibaba-ack"
    lock_address   = "https://api.tfstate.dev/github/v1/alibaba-ack/lock"
    unlock_address = "https://api.tfstate.dev/github/v1/alibaba-ack/lock"
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

locals {
  addon_names = [for a in var.addons : a.name if !a.disabled]

  # zone_ids 留空时，按 region 自动取前 3 个可用区
  effective_zone_ids = length(var.zone_ids) > 0 ? var.zone_ids : slice(
    data.alicloud_zones.default.zones[*].id,
    0,
    min(3, length(data.alicloud_zones.default.zones))
  )
}

data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
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
# 托管版 K8s 集群（不在创建时建池，节点池单独资源）
# ----------------------------------------------------------------------------
resource "alicloud_cs_managed_kubernetes" "this" {
  name                = var.cluster_name
  version             = var.k8s_version
  cluster_spec        = "ack.pro.small"
  vswitch_ids         = alicloud_vswitch.cluster_vswitch[*].id
  pod_cidr            = var.pod_cidr
  service_cidr        = var.service_cidr
  new_nat_gateway     = true
  deletion_protection = false

  dynamic "addons" {
    for_each = { for a in var.addons : a.name => a if !a.disabled }
    content {
      name   = addons.value.name
      config = addons.value.config
    }
  }
}

# ----------------------------------------------------------------------------
# 节点池：默认 / GPU，独立可开关
# ----------------------------------------------------------------------------
resource "alicloud_cs_kubernetes_node_pool" "default" {
  count = var.enable_default_node_pool ? 1 : 0

  cluster_id            = alicloud_cs_managed_kubernetes.this.id
  node_pool_name        = "${var.cluster_name}-default"
  vswitch_ids           = alicloud_vswitch.cluster_vswitch[*].id
  instance_types        = var.default_pool.instance_types
  desired_size          = var.default_pool.desired_size
  system_disk_category  = "cloud_essd"
  system_disk_size      = var.default_pool.disk_size
  key_name              = var.key_name != "" ? var.key_name : null
  install_cloud_monitor = true
}

resource "alicloud_cs_kubernetes_node_pool" "gpu" {
  count = var.enable_gpu_node_pool ? 1 : 0

  cluster_id            = alicloud_cs_managed_kubernetes.this.id
  node_pool_name        = "${var.cluster_name}-gpu"
  vswitch_ids           = alicloud_vswitch.cluster_vswitch[*].id
  instance_types        = var.gpu_pool.instance_types
  desired_size          = var.gpu_pool.desired_size
  system_disk_category  = "cloud_essd"
  system_disk_size      = var.gpu_pool.disk_size
  key_name              = var.key_name != "" ? var.key_name : null
  install_cloud_monitor = true

  labels {
    key   = "nvidia.com/gpu"
    value = "true"
  }

  taints {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NoSchedule"
  }
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
