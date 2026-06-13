#!/usr/bin/env bash
# 对每个含 .tf 的模块跑 terraform validate
set -e

if ! command -v terraform >/dev/null 2>&1; then
  echo "⚠️  terraform 未安装，跳过 validate"
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

dirs=$(find . -name "*.tf" -not -path "*/.terraform/*" -exec dirname {} \; | sort -u)
[ -z "$dirs" ] && exit 0

failed=0
skipped=0
for dir in $dirs; do
  echo "→ validate $dir"

  # 第一次直接 validate，失败再尝试 init 修复
  validate_output=$(cd "$dir" && terraform validate -no-color 2>&1) && {
    echo "$validate_output" | grep -E '^(Success|Warning)' >/dev/null && echo "  ✓"
    continue
  }

  # validate 失败：先看是否是 provider 缓存问题（init 能修）
  if echo "$validate_output" | grep -qE 'no package for|Missing required provider|Inconsistent dependency lock'; then
    if (cd "$dir" && terraform init -backend=false -input=false -upgrade >/dev/null 2>&1); then
      (cd "$dir" && terraform validate -no-color) || failed=1
    else
      echo "  ⚠️  init 失败（registry/mirror 不可用），跳过 $dir"
      skipped=$((skipped + 1))
    fi
  else
    # 真正的配置错误
    echo "$validate_output"
    failed=1
  fi
done

[ $skipped -gt 0 ] && echo "⚠️  共跳过 $skipped 个模块（init 失败）"
[ $failed -ne 0 ] && exit 1
exit 0
