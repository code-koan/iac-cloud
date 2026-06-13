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
