terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.213"
    }
  }
}

provider "alicloud" {
  region = var.region
}

resource "alicloud_vpc" "main_vpc" {
  name       = "gpu-vpc"
  cidr_block = "10.0.0.0/16"
}

resource "alicloud_vswitch" "main_vswitch" {
  vpc_id     = alicloud_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  zone_id    = "${var.region}-f"
}

resource "alicloud_security_group" "gpu_sg" {
  name        = "gpu-security-group"
  description = "允许 SSH、HTTP、HTTPS"
  vpc_id      = alicloud_vpc.main_vpc.id
}

resource "alicloud_security_group_rule" "allow_ssh" {
  security_group_id = alicloud_security_group.gpu_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  policy            = "Accept"
}

resource "alicloud_security_group_rule" "allow_http" {
  security_group_id = alicloud_security_group.gpu_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "80/443,8000/8000"
  policy            = "Accept"
}

resource "alicloud_instance" "gpu_instance" {
  instance_name   = var.instance_name
  instance_type   = var.instance_type
  vswitch_id      = alicloud_vswitch.main_vswitch.id
  security_groups = [alicloud_security_group.gpu_sg.id]

  image_id    = "aliyun_2_1903_x64_20G_alibase_20230109.bin"
  system_disk_category = "cloud_efficiency"
  system_disk_size     = 40

  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByTraffic"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              apt-get update
              apt-get install -y docker.io docker-compose
              systemctl start docker
              EOF
  )
}

output "ssh_command" {
  description = "SSH 连接命令"
  value       = "ssh root@${alicloud_instance.gpu_instance.public_ip}"
}

output "instance_id" {
  description = "实例 ID"
  value       = alicloud_instance.gpu_instance.id
}
