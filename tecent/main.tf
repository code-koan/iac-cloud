terraform {
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81.0"
    }
  }
}

provider "tencentcloud" {
  region     = var.region
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

# 查询 Ubuntu 22.04 LTS 镜像（仅使用 image_name_regex）
data "tencentcloud_images" "ubuntu" {
  image_type       = ["PUBLIC_IMAGE"]
  image_name_regex = "Ubuntu Server 22.04 LTS 64bit"
}

resource "tencentcloud_vpc" "main_vpc" {
  name       = "docker-vpc"
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "docker-vpc"
    Environment = "development"
  }
}

resource "tencentcloud_subnet" "main_subnet" {
  name              = "docker-subnet"
  vpc_id            = tencentcloud_vpc.main_vpc.id
  availability_zone = var.availability_zone
  cidr_block        = "10.0.1.0/24"
  is_multicast      = false

  tags = {
    Name        = "docker-subnet"
    Environment = "development"
  }
}

# 正确的安全组资源
resource "tencentcloud_security_group" "docker_sg" {
  name        = "docker-security-group"
  description = "允许 SSH、HTTP、HTTPS 和自定义端口"
}

# 安全组规则 - ingress
resource "tencentcloud_security_group_rule" "allow_ssh_http" {
  security_group_id = tencentcloud_security_group.docker_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "TCP"
  port_range        = "22,80,443,7290"
  policy            = "ACCEPT"
}

# 安全组规则 - egress
resource "tencentcloud_security_group_rule" "allow_all_outbound" {
  security_group_id = tencentcloud_security_group.docker_sg.id
  type              = "egress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "ALL"
  policy            = "ACCEPT"
}

resource "tencentcloud_key_pair" "ssh_key" {
  key_name   = var.key_pair_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "tencentcloud_instance" "docker_spot_instance" {
  instance_name     = var.instance_name
  availability_zone = var.availability_zone
  image_id          = data.tencentcloud_images.ubuntu.images[0].image_id
  instance_type     = var.instance_type
  key_ids           = [tencentcloud_key_pair.ssh_key.id]
  orderly_security_groups = [tencentcloud_security_group.docker_sg.id]
  subnet_id         = tencentcloud_subnet.main_subnet.id
  internet_max_bandwidth_out = 100

  instance_charge_type = "SPOTPAID"
  spot_instance_type   = "ONE-TIME"
  spot_max_price       = "0.3"

  system_disk_type = "CLOUD_PREMIUM"
  system_disk_size = 20

  user_data = local.user_data

  internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"  # 按小时流量计费
  allocate_public_ip         = true                        # 自动分配公网 IP

  tags = {
    Name         = var.instance_name
    Environment  = "development"
    InstanceType = "spot"
  }
}
