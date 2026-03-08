#!/bin/bash
# AutoDL GPU 实例初始化脚本
# 在实例首次连接后运行

set -euo pipefail

echo "=== GPU 实例初始化 ==="

# 检查 GPU
echo "[1/4] 检查 GPU..."
nvidia-smi || echo "警告: nvidia-smi 不可用"

# 检查 CUDA
echo "[2/4] 检查 CUDA..."
nvcc --version 2>/dev/null || echo "警告: nvcc 不可用"

# 创建工作目录
echo "[3/4] 创建工作目录..."
mkdir -p /workspace
cd /workspace

# 安装基础工具
echo "[4/4] 安装基础工具..."
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
  torch \
  transformers \
  accelerate \
  deepspeed \
  vllm \
  openai \
  uvicorn \
  fastapi

echo "=== 初始化完成 ==="
echo "工作目录: /workspace"
echo ""
echo "常用命令:"
echo "  nvidia-smi          # 查看 GPU 状态"
echo "  python -c 'import torch; print(torch.cuda.get_device_name(0))'  # 检查 PyTorch GPU"
