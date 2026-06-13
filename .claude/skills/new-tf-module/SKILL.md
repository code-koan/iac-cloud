---
name: new-tf-module
description: 在 iac-cloud 仓库新增一个云资源 Terraform 模板的标准化骨架（main/variable/output/README + .config 设计文档 + tfstate.dev backend + .gitignore + index 注册）。当用户要求"新增一个 <cloud>/<resource> 模板"、"加一个新的云模块"或类似时使用。
---

# new-tf-module — Terraform 模板骨架生成

## 何时使用

用户要在 `repos/iac-cloud/` 下新增一个云资源 Terraform 模板（如 `aws/eks`、`alibaba/oss`、`gcp/gke`），需要：
- 标准目录结构
- tfstate.dev 远程 state 配置（path 唯一）
- `.config/<cloud>/` 设计文档
- 索引同步、gitignore 同步

## 输入

向用户问清楚（缺哪个问哪个）：

1. **`<cloud>/<resource>`**（必填）— 例：`aws/eks`、`alibaba/rds`
2. **resource 简介一句话** — 用于 README / `.config/<cloud>/<resource>.md` 顶端
3. **核心 Provider 资源名** — 例：`aws_eks_cluster`，用于 main.tf 占位
4. **是否需要 kubeconfig 落盘** — 仅 K8s 类资源
5. **关键变量列表** — 至少 region；其它由用户补

## 流程（按顺序执行）

### 1. 检查命名冲突

```bash
test -d repos/iac-cloud/<cloud>/<resource> && echo "EXISTS - 停止" || echo "ok"
grep -rn "<cloud>-<resource>" repos/iac-cloud/**/main.tf  # 确认 state path 不冲突
```

### 2. 创建模板目录骨架

`repos/iac-cloud/<cloud>/<resource>/` 下创建 4 个文件，从下方 [模板片段](#模板片段) 复制并替换占位符：

- `main.tf` — terraform/backend/provider/locals 骨架 + 一个核心资源占位
- `variable.tf` — `access_key`/`secret_key`/`region`（默认值由用户给）
- `output.tf` — 至少 `<resource>_id`、视情况 `kubeconfig_path`/`kubectl_cmd`
- `README.md` — 使用步骤（参考 `alibaba/ack/README.md`）

### 3. 创建 / 更新设计文档

- 若 `.config/<cloud>/_index.md` 不存在 → 创建（参考 `.config/alibaba/_index.md`）
- 创建 `.config/<cloud>/<resource>.md`（拓扑、变量速查、输出）
- 在 `.config/<cloud>/_index.md` 表格中追加一行
- 在 `.config/_index.md` 顶层表格追加 `<cloud>` 领域（若尚未注册）

### 4. 更新 `.gitignore`（视需要）

K8s 类资源加：
```
<cloud>/<resource>/kubeconfig
```

### 5. 验证

```bash
cd repos/iac-cloud/<cloud>/<resource>
# 优先复用兄弟模块的 provider 缓存以避免 registry 抖动
SIBLING=$(ls ../*/.terraform/providers 2>/dev/null | head -1 | xargs dirname | xargs dirname)
if [ -n "$SIBLING" ]; then
  terraform init -backend=false -plugin-dir="$SIBLING/.terraform/providers"
else
  terraform init -backend=false
fi
terraform validate
```

要求 `Success` 才算完成；validate warning（deprecation 等）可接受但需在 README/`.config` 文档里记录。

### 6. 报告交付

按模板输出"完成报告"：
- 改动的文件清单（含 `.config/`、`.gitignore`）
- `terraform validate` 结果
- 用户下一步使用命令

## 模板片段

### main.tf 骨架

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    <provider> = {
      source  = "<provider-source>"
      version = "<version>"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # 远程 state — tfstate.dev (GitHub 账号鉴权)
  # TF_HTTP_PASSWORD=<GitHub PAT> 传入
  backend "http" {
    address        = "https://api.tfstate.dev/github/v1/<cloud>-<resource>"
    lock_address   = "https://api.tfstate.dev/github/v1/<cloud>-<resource>/lock"
    unlock_address = "https://api.tfstate.dev/github/v1/<cloud>-<resource>/lock"
    lock_method    = "PUT"
    unlock_method  = "DELETE"
    username       = "code-koan/iac-cloud"
  }
}

provider "<provider>" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# TODO: 主资源
```

### variable.tf 骨架

```hcl
variable "access_key" {
  description = "<cloud> AccessKey ID（建议 export TF_VAR_access_key）"
  type        = string
  sensitive   = true
  default     = null
}

variable "secret_key" {
  description = "<cloud> AccessKey Secret（建议 export TF_VAR_secret_key）"
  type        = string
  sensitive   = true
  default     = null
}

variable "region" {
  description = "区域。改这里即可切换地域"
  type        = string
  default     = "<default-region>"
}
```

### kubeconfig 落盘片段（K8s 类资源用）

```hcl
data "<provider>_cs_cluster_credential" "this" {
  cluster_id = <cluster-resource>.this.id
}

resource "local_sensitive_file" "kubeconfig" {
  content         = data.<provider>_cs_cluster_credential.this.kube_config
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

output "kubeconfig_path" { value = local_sensitive_file.kubeconfig.filename }
output "kubectl_cmd" {
  value = "export KUBECONFIG=${abspath(local_sensitive_file.kubeconfig.filename)}"
}
```

## 检查清单（自审）

- [ ] 目录在 `<cloud>/<resource>/` 下，不在仓库根或 `<cloud>/` 根放散落 .tf
- [ ] backend path = `<cloud>-<resource>`（与 `grep -rn` 结果不冲突）
- [ ] `.config/<cloud>/_index.md` 已注册新模板
- [ ] `.config/_index.md` 已注册 `<cloud>` 领域（若新）
- [ ] `.gitignore` 已加 kubeconfig 等落盘文件
- [ ] `terraform validate` Success
- [ ] README 含 `TF_VAR_*` + `TF_HTTP_PASSWORD` 步骤

## 参考实现

`alibaba/ack/`、`alibaba/acs/` 是按本 skill 流程的成品参考。
