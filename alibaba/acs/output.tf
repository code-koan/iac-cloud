output "cluster_id" {
  description = "ACS 集群 ID"
  value       = alicloud_cs_managed_kubernetes.this.id
}

output "cluster_endpoint" {
  description = "API Server 地址（公网，若开启）"
  value       = try(data.alicloud_cs_cluster_credential.this.cluster_name, alicloud_cs_managed_kubernetes.this.name)
}

output "vpc_id" {
  value = alicloud_vpc.main_vpc.id
}

output "vswitch_ids" {
  value = alicloud_vswitch.cluster_vswitch[*].id
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

output "cluster_spec" {
  description = "集群规格（standard / pro）"
  value       = local.cluster_spec
}
