# iac-cloud Makefile

.PHONY: help lint fmt validate lint-install

help:
	@echo "make lint          - 检查 fmt + validate 全部 .tf 模块"
	@echo "make fmt           - 自动格式化所有 .tf 文件"
	@echo "make validate      - 校验所有 .tf 模块"
	@echo "make lint-install  - 安装本仓库的 git hooks 到 .githooks/"

fmt:
	terraform fmt -recursive

lint: validate
	terraform fmt -recursive -check

validate:
	@bash .githooks/lib/validate-all.sh

lint-install:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit
	@echo "✓ git hooks installed (.githooks/pre-commit: fmt-check)"
	@echo "  validate / plan 由 CI 负责，不入 hook（避免 provider 下载阻塞 push）"
