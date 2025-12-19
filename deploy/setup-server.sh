#!/bin/bash

# 在目标服务器上运行此脚本以设置部署环境

set -e

echo "设置部署环境..."

# 创建应用目录
sudo mkdir -p /opt/web-calculator/nginx
sudo mkdir -p /opt/web-calculator/nginx/conf.d
sudo mkdir -p /opt/web-calculator/nginx/templates

# 设置权限
sudo chown -R $USER:$USER /opt/web-calculator

# 安装Docker（如果未安装）
if ! command -v docker &> /dev/null; then
    echo "安装Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# 安装Docker Compose（如果未安装）
if ! command -v docker-compose &> /dev/null; then
    echo "安装Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# 安装curl（如果未安装）
sudo apt-get update
sudo apt-get install -y curl

echo "服务器设置完成！"
echo "请将以下文件复制到 /opt/web-calculator:"
echo "1. docker-compose.yml"
echo "2. nginx/ 目录内容"
echo "3. deploy/blue-green-switch.sh"
