terraform {
  required_providers {
    volcengine = {
      source  = "volcengine/volcengine"
      version = "~> 0.0.47"
    }
  }
}

provider "volcengine" {
  region = var.region
}

resource "volcengine_vpc" "main_vpc" {
  name       = "gpu-vpc"
  cidr_block = "10.0.0.0/16"
}

resource "volcengine_subnet" "main_subnet" {
  name       = "gpu-subnet"
  cidr_block = "10.0.1.0/24"
  vpc_id     = volcengine_vpc.main_vpc.id
  zone_id    = "${var.region}-01"
}

resource "volcengine_security_group" "gpu_sg" {
  name        = "gpu-security-group"
  description = "允许 SSH、HTTP、HTTPS"
  vpc_id      = volcengine_vpc.main_vpc.id
}

resource "volcengine_security_group_rule" "allow_ssh" {
  security_group_id = volcengine_security_group.gpu_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  protocol          = "tcp"
  port_range        = "22/22"
  policy            = "accept"
}

resource "volcengine_security_group_rule" "allow_http" {
  security_group_id = volcengine_security_group.gpu_sg.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  protocol          = "tcp"
  port_range        = "80/443,8000/8000"
  policy            = "accept"
}

resource "volcengine_instance" "gpu_instance" {
  instance_name         = var.instance_name
  instance_type        = var.instance_type
  subnet_id            = volcengine_subnet.main_subnet.id
  security_group_ids   = [volcengine_security_group.gpu_sg.id]

  image_id             = "image-yq2k8p6k9gvp7c0l"
  system_volume_type   = "ESSD_PL0"
  system_volume_size   = 40

  internet_max_bandwidth_out = 100
  internet_charge_type      = "PostPaidByTraffic"

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
  value       = "ssh root@${volcengine_instance.gpu_instance.public_ip}"
}

output "instance_id" {
  description = "实例 ID"
  value       = volcengine_instance.gpu_instance.id
}
