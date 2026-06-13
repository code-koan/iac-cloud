output "cluster_id" {
  description = "ACK 集群 ID"
  value       = alicloud_cs_managed_kubernetes.this.id
}

output "cluster_endpoint" {
  description = "API Server 地址"
  value       = alicloud_cs_managed_kubernetes.this.connections
}

output "vpc_id" {
  value = alicloud_vpc.main_vpc.id
}

output "vswitch_ids" {
  value = alicloud_vswitch.cluster_vswitch[*].id
}

output "worker_ram_role_name" {
  description = "Worker 节点 RAM Role 名称"
  value       = alicloud_cs_managed_kubernetes.this.worker_ram_role_name
}

output "default_node_pool_id" {
  description = "默认节点池 ID（未启用则为空）"
  value       = try(alicloud_cs_kubernetes_node_pool.default[0].id, "")
}

output "gpu_node_pool_id" {
  description = "GPU 节点池 ID（未启用则为空）"
  value       = try(alicloud_cs_kubernetes_node_pool.gpu[0].id, "")
}

output "kubeconfig_path" {
  description = "kubeconfig 文件路径"
  value       = local_sensitive_file.kubeconfig.filename
}

output "kubectl_cmd" {
  description = "一键导出 KUBECONFIG 命令"
  value       = "export KUBECONFIG=${abspath(local_sensitive_file.kubeconfig.filename)}"
}

output "installed_addons" {
  description = "已启用的 addon 名称"
  value       = local.addon_names
}
