# GPU 学习 IaC 模板创建计划

## TL;DR

> 创建 GPU 学习用的 IaC 模板，包含三个平台的配置：AutoDL 操作文档、阿里云 Terraform、火山引擎 Terraform

**交付物**:
- `gpu-study/autodl/README.md` - AutoDL 操作指南
- `gpu-study/alibaba/main.tf` + `variable.tf` - 阿里云 GPU 实例 Terraform
- `gpu-study/volcengine/main.tf` + `variable.tf` - 火山引擎 GPU 实例 Terraform

**预计工作量**: 小
**并行执行**: 是

---

## Context

### 用户需求
- 创建 GPU 学习用的 IaC 模板
- 三个平台：AutoDL、阿里云、火山引擎
- AutoDL 提供操作文档
- 阿里云和火山引擎使用 Terraform (最小化配置)

---

## Work Objectives

### 核心目标
创建最小化的 IaC 模板，用于快速搭建 GPU 学习环境

### 具体交付物
1. **AutoDL 目录**: `gpu-study/autodl/README.md`
   - 注册、租用、连接步骤
   - 常用命令
   - 计费说明

2. **阿里云目录**: `gpu-study/alibaba/`
   - `main.tf` - VPC/安全组/GPU实例
   - `variable.tf` - 可配置变量

3. **火山引擎目录**: `gpu-study/volcengine/`
   - `main.tf` - VPC/安全组/GPU实例
   - `variable.tf` - 可配置变量

---

## Verification Strategy

- [x] AutoDL README.md 语法正确，内容完整
- [x] 阿里云 Terraform 语法通过验证
- [x] 火山引擎 Terraform 语法通过验证
- [x] 目录结构正确

---

## Execution Strategy

### 任务列表

**Wave 1 (并行)**:
- [x] 1. 创建目录结构
- [x] 2. 创建 AutoDL README.md
- [x] 3. 创建阿里云 Terraform 配置
- [x] 4. 创建火山引擎 Terraform 配置

---

## TODOs

- [x] 1. 创建目录结构 `gpu-study/{autodl,alibaba,volcengine}`

  **What to do**:
  - 创建 `gpu-study/autodl/` 目录
  - 创建 `gpu-study/alibaba/` 目录
  - 创建 `gpu-study/volcengine/` 目录

  **Agent Profile**: quick

  **Acceptance Criteria**:
  - [x] 三个目录创建成功

- [x] 2. 创建 AutoDL README.md

  **What to do**:
  - 创建 `gpu-study/autodl/README.md`
  - 内容包含：注册步骤、租用 GPU、连接实例、常用命令、计费说明

  **Agent Profile**: writing

  **Acceptance Criteria**:
  - [x] README.md 包含完整操作指南

- [x] 3. 创建阿里云 Terraform 配置

  **What to do**:
  - 创建 `gpu-study/alibaba/variable.tf` - 区域、实例类型、实例名变量
  - 创建 `gpu-study/alibaba/main.tf` - VPC、安全组、GPU实例配置
  - 使用 ecs.gn6i-c4g1.2xlarge (T4付费

  **) 或按量Agent Profile**: unspecified-low

  **Acceptance Criteria**:
  - [x] variable.tf 包含必要变量
  - [x] main.tf 包含 GPU 实例配置
  - [x] 使用按量付费 (PostPaid)

- [x] 4. 创建火山引擎 Terraform 配置

  **What to do**:
  - 创建 `gpu-study/volcengine/variable.tf` - 区域、实例类型、实例名变量
  - 创建 `gpu-study/volcengine/main.tf` - VPC、安全组、GPU实例配置
  - 使用 gpu.g3 或 gpu.g2 系列，按量付费

  **Agent Profile**: unspecified-low

  **Acceptance Criteria**:
  - [x] variable.tf 包含必要变量
  - [x] main.tf 包含 GPU 实例配置
  - [x] 使用按量付费

---

## Success Criteria

- [x] `gpu-study/autodl/README.md` 存在且内容完整
- [x] `gpu-study/alibaba/main.tf` 和 `variable.tf` 存在
- [x] `gpu-study/volcengine/main.tf` 和 `variable.tf` 存在
