# AutoDL GPU 租用指南

AutoDL 是一个提供 GPU 算力租赁的平台，适合深度学习训练、模型开发等场景。

## 访问官网

- 官网: https://www.autodl.com/home
- 控制台: https://www.autodl.com/console

## 注册账号

1. 访问 AutoDL 官网，点击「注册」
2. 使用手机号或邮箱注册账号
3. 完成实名认证（必须）
4. **建议完成学生认证，可享 95 折优惠**

## 租用 GPU 实例

### 1. 进入算力市场

登录后在控制台点击「算力市场」或访问 https://www.autodl.com/market

### 2. 选择配置

| 参数 | 推荐选项 |
|------|----------|
| 显卡 | RTX 4090 / A100 / RTX 3090 |
| 显存 | 24GB 以上 |
| 地域 | 靠近使用地点（华北、华东等） |
| 框架 | PyTorch / TensorFlow |

### 3. 价格参考

- RTX 4090: 约 1.88 元/小时
- RTX 3090: 约 1.5 元/小时
- A100: 约 3-5 元/小时

### 4. 租用方式

- **按时长租**: 按小时计费，用完释放
- **包月租**: 长时任务更划算

选择机型后点击「立即租用」，选择镜像（推荐使用 PyTorch 镜像），确认订单即可。

## 连接实例

### 1. JupyterLab 连接

租用成功后，在控制台点击「JupyterLab」即可直接使用浏览器访问。

### 2. SSH 连接

```bash
# 使用 AutoDL 提供的 SSH 命令
ssh -p 端口号 root@内网地址
# 示例
ssh -p 12345 root@localhost
```

### 3. vscode 远程连接

1. 安装 Remote - SSH 扩展
2. 输入连接命令
3. 打开远程文件夹即可开发

## 常用命令

### 查看 GPU 状态

```bash
nvidia-smi
```

### 查看 CUDA 版本

```bash
nvcc --version
```

### 查看 Python 环境

```bash
python --version
pip list
```

### 监控 GPU 使用

```bash
# 实时监控
watch -n 1 nvidia-smi

# 使用 gpustat
pip install gpustat
gpustat -i 1
```

### 文件传输

```bash
# 从本地上传文件
# 在 JupyterLab 中可直接拖拽上传

# 使用 scp
scp -P 端口号 local_file.txt root@内网地址:/root/
```

## 计费说明

- **按时计费**: 从实例创建开始计时，释放时停止计费
- **费用计算**: 实际使用时长 × 单价
- **包月价格**: 月卡价格 = 时价 × 24 × 30 × 0.85（约 85 折）
- **欠费提醒**: 余额不足时会有通知，请及时充值
- **学生优惠**: 完成学生认证后享受 95 折

## 注意事项

1. **数据保存**: 实例释放后数据会清除，请及时备份重要数据
2. **实例保存**: 可使用「保存镜像」功能保存环境
3. **按时长租**: 建议先用按时长租测试环境，确认没问题再包月
4. **安全组**: 确保开放相应端口（22 SSH、8888 JupyterLab 等）

## 相关链接

- AutoDL 官网: https://www.autodl.com/home
- 算力市场: https://www.autodl.com/market
- 控制台: https://www.autodl.com/console
- 帮助文档: https://www.autodl.com/docs
- 学生认证: https://www.autodl.com/student
