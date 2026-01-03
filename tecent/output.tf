output "instance_id" {
  description = "实例 ID"
  value       = tencentcloud_instance.docker_spot_instance.id
}

output "public_ip" {
  description = "公网 IP 地址"
  value       = tencentcloud_instance.docker_spot_instance.public_ip
}

output "private_ip" {
  description = "私网 IP 地址"
  value       = tencentcloud_instance.docker_spot_instance.private_ip
}

output "ssh_connection" {
  description = "SSH 连接命令"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${tencentcloud_instance.docker_spot_instance.public_ip}"
}

output "docker_service_url" {
  description = "Docker 容器服务访问地址"
  value       = "http://${tencentcloud_instance.docker_spot_instance.public_ip}:7290"
}
