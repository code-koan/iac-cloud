output "instance_id" {
  description = "RDS 实例 ID"
  value       = alicloud_db_instance.this.id
}

output "connection_string" {
  description = "内网连接域名"
  value       = alicloud_db_instance.this.connection_string
}

output "port" {
  description = "RDS 端口（PG 默认 5432）"
  value       = alicloud_db_instance.this.port
}

output "vpc_id" {
  description = "VPC ID（新建或复用）"
  value       = local.vpc_id
}

output "vswitch_id" {
  description = "vSwitch ID"
  value       = local.vswitch_id
}

output "databases" {
  description = "已创建的 database / account 对（不含密码）"
  sensitive   = true
  value       = [for d in var.databases : { name = d.name, account = d.account }]
}

# 完整 psql 连接串（含密码，sensitive）。逐库一条。
# 用法：terraform output -json psql_dsn  / terraform output -raw psql_dsn  会被遮罩，
# 单条复用：terraform output -json psql_dsn | jq -r '.<db_name>'
output "psql_dsn" {
  description = "每个 database 的 psql DSN（含密码）。键为 database name。仅 VPC 内网可达。"
  sensitive   = true
  value = {
    for d in var.databases :
    d.name => "postgresql://${d.account}:${var.database_passwords[d.name]}@${alicloud_db_instance.this.connection_string}:${alicloud_db_instance.this.port}/${d.name}?sslmode=require"
  }
}

# 不含密码的版本，方便日常查阅 / 文档化
output "psql_dsn_no_password" {
  description = "psql DSN 模板，密码用 <password> 占位"
  value = {
    for d in var.databases :
    d.name => "postgresql://${d.account}:<password>@${alicloud_db_instance.this.connection_string}:${alicloud_db_instance.this.port}/${d.name}?sslmode=require"
  }
}
