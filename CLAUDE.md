# iac-cloud

Terraform IaC 模板集，快速搭建云基础设施。

## 目录结构

```
iac-cloud/
├── CLAUDE.md              # AI 编程入口（本文件）
├── AGENTS.md              # 项目知识库
├── README.md              # 项目介绍
├── .config/               # AI 编程设计文档
│   ├── _index.md
│   ├── tecent/
│   │   └── _index.md
│   ├── gpu-study/
│   │   └── _index.md
│   └── skills/
│       └── _index.md
├── tecent/                # 腾讯云抢占式实例模块
│   ├── main.tf
│   ├── variable.tf
│   ├── output.tf
│   └── scripts/user-data.sh
├── gpu-study/             # GPU 学习环境模板
│   ├── alibaba/           # 阿里云 GPU 实例 Terraform
│   ├── autodl/            # AutoDL 操作指南
│   └── volcengine/        # 火山引擎 GPU 实例 Terraform
├── alibaba/               # 阿里云 Provider 配置
├── autodl/                # AutoDL 客户端脚本
└── skills/                # AI 可安装 skill
    ├── SKILL.md
    └── evals/evals.json
```

## 文档输出规范（CRITICAL）

AI 产出的所有方案、文档、沉淀总结必须简洁：

- **步骤用列表** — 流程类内容用列表，不用大段叙述
- **多维用矩阵** — 多方案/多维度对比用表格
- **一句话高密度** — 一句说清链路：做什么 → 为什么 → 接下来几步

## 设计文档入口

业务设计文档集中在 `.config/`，按领域组织：
- [.config/_index.md](.config/_index.md) — 总索引

## 命名规范

- Terraform 资源: `类型_用途` (main_vpc, app_subnet)
- 变量: snake_case
- Tag: PascalCase
- 缩进: 2 空格

## 安全规则

- 禁止硬编码密钥 → `export TF_VAR_*`
- 使用 `tfstate.dev` 远程管理 state
- 禁止提交 `.tfstate` 文件

## 模块新增约定

- 新增云资源模板时，优先调用 `.claude/skills/new-tf-module/`（自动生成骨架 + state path + 索引同步 + validate）
- 每个云资源 = 一个独立子目录（`<cloud>/<resource>/`，含 `main.tf` / `variable.tf` / `output.tf` / `README.md`）；禁止在仓库根或 `<cloud>/` 根直接放散落 `.tf` 文件
- 远程 state path 必须唯一：`<cloud>-<resource>`（如 `alibaba-ack`、`alibaba-acs`），避免和已有模板冲突
- 同步注册到 `.config/<cloud>/_index.md` + `.config/_index.md`
- `terraform init` 撞 registry 抖动时，复用兄弟模块缓存：`terraform init -backend=false -plugin-dir=../<sibling>/.terraform/providers`

## 开发排障速查

### Provider 下载卡 github（典型：aliyun/alicloud）

`alicloud` provider zip ~60M+，国内直连 github 常 i/o timeout 或 EOF。**`network_mirror` 不解决**（只代理元数据，archive URL 仍指 github），**`plugin_cache_dir` 也不解决**（只是下载完顺手存一份，仍需先成功下载）。

**唯一离线方案：`filesystem_mirror`**。手动放 binary 到本地 mirror，terraform 直接从磁盘加载，零网络请求。

```hcl
# ~/.terraformrc
plugin_cache_dir   = "$HOME/.terraform.d/plugin-cache"
disable_checkpoint = true

provider_installation {
    filesystem_mirror {
        path    = "/home/<user>/.terraform.d/plugins"
        include = ["registry.terraform.io/*/*"]
    }
    network_mirror {
        url     = "https://terraform-registry-mirror.ru/"
        include = ["registry.terraform.io/*/*"]
    }
    direct { exclude = ["registry.terraform.io/*/*"] }
}
```

放置 binary 的目录结构（严格遵守，否则 terraform 找不到）：

```
~/.terraform.d/plugins/registry.terraform.io/<namespace>/<name>/<version>/<os>_<arch>/terraform-provider-<name>_v<version>
```

例：`registry.terraform.io/aliyun/alicloud/1.281.0/linux_amd64/terraform-provider-alicloud_v1.281.0`

获取 binary 的两条路：
1. 有网环境跑 `terraform providers mirror ~/.terraform.d/plugins` 一次性同步当前模块所有依赖
2. 手动从 github releases 下载 zip → unzip 到上述目录 → `chmod +x`
