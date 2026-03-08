#!/bin/bash
# AutoDL GPU 实例连接脚本
# 使用方法: ./connect.sh <instance-ip> <port> <password>

set -euo pipefail

# AutoDL 实例信息 (手动填写从AutoDL网站获取)
HOST="${1:-}"
PORT="${2:-22}"
PASSWORD="${3:-}"

if [[ -z "$HOST" || -z "$PASSWORD" ]]; then
  echo "Usage: ./connect.sh <host> <port> <password>"
  echo ""
  echo "从 AutoDL 网站获取实例信息:"
  echo "  1. 访问 https://www.autodl.com/home"
  echo "  2. 租用 GPU 实例"
  echo "  3. 在实例详情页获取 SSH 连接信息"
  exit 1
fi

echo "连接到 AutoDL GPU 实例: $HOST:$PORT"
echo "密码: $PASSWORD"

# 使用 sshpass 自动输入密码 (需要先安装: brew install sshpass)
if command -v sshpass &> /dev/null; then
  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$HOST -p $PORT
else
  echo "提示: 安装 sshpass 以自动输入密码"
  echo "  brew install sshpass"
  echo ""
  echo "或手动连接:"
  echo "  ssh -p $PORT root@$HOST"
  echo "  密码: $PASSWORD"
  ssh -p $PORT root@$HOST
fi
