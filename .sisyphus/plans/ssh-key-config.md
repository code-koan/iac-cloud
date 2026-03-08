# 添加 SSH 密钥配置计划

## TL;DR

> 修改阿里云和火山引擎 Terraform 配置，使用本地 ~/.ssh/id_rsa.pub 作为默认 SSH 密钥

---

## Work Objectives

修改以下文件:
1. `gpu-study/alibaba/variable.tf` - 添加 ssh_public_key_file 变量
2. `gpu-study/alibaba/main.tf` - 添加 key_pair 资源
3. `gpu-study/volcengine/variable.tf` - 添加 ssh_public_key_file 变量
4. `gpu-study/volcengine/main.tf` - 添加密钥相关配置

---

## TODOs

- [x] 1. 修改阿里云 variable.tf - 添加 ssh_public_key_file 变量

  **Acceptance Criteria**:
  - [x] 添加变量: ssh_public_key_file, default = "~/.ssh/id_rsa.pub"

- [x] 2. 修改阿里云 main.tf - 添加密钥资源配置

  **Acceptance Criteria**:
  - [x] 添加 alicloud_key_pair 资源
  - [x] 在 alicloud_instance 中添加 key_name

- [x] 3. 修改火山引擎 variable.tf - 添加 ssh_public_key_file 变量

  **Acceptance Criteria**:
  - [x] 添加变量: ssh_public_key_file, default = "~/.ssh/id_rsa.pub"

- [x] 4. 修改火山引擎 main.tf - 添加密钥配置

  **Acceptance Criteria**:
  - [x] 添加 volcengine_ssh_key_pair 资源
  - [x] 在实例中添加 key_name
