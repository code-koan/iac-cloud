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
  vpc_name  = "gpu-vpc"
  cidr_block = "10.0.0.0/16"
}

resource "volcengine_subnet" "main_subnet" {
  subnet_name = "gpu-subnet"
  cidr_block = "10.0.1.0/24"
  vpc_id     = volcengine_vpc.main_vpc.id
  zone_id    = "${var.region}-01"
}

resource "volcengine_security_group" "gpu_sg" {
  security_group_name = "gpu-security-group"
  description         = "允许 SSH、HTTP、HTTPS"
  vpc_id              = volcengine_vpc.main_vpc.id
}

resource "volcengine_ecs_key_pair" "ssh_key" {
  key_pair_name = "gpu-study-key"
  public_key    = file(var.ssh_public_key_file)
}

resource "volcengine_ecs_instance" "gpu_instance" {
  instance_name       = var.instance_name
  instance_type       = var.instance_type
  subnet_id           = volcengine_subnet.main_subnet.id
  security_group_ids  = [volcengine_security_group.gpu_sg.id]
  key_pair_name      = volcengine_ecs_key_pair.ssh_key.key_pair_name

  image_id            = "image-yq2k8p6k9gvp7c0l"
  system_volume_type  = "ESSD_PL0"
  system_volume_size  = 40

  instance_charge_type = "PostPaid"

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
  value       = "ssh root@${volcengine_ecs_instance.gpu_instance.primary_ip_address}"
}

output "instance_id" {
  description = "实例 ID"
  value       = volcengine_ecs_instance.gpu_instance.id
}
