#!/bin/bash

# Blue-Green 部署脚本
set -e

COMMIT_SHA=$1
if [ -z "$COMMIT_SHA" ]; then
    echo "错误: 需要提供提交哈希"
    exit 1
fi

IMAGE_NAME="ghcr.io/$GITHUB_REPOSITORY"
TAG="$COMMIT_SHA"

# 登录到 GitHub Container Registry
echo "$GITHUB_TOKEN" | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# 拉取最新镜像
docker pull "$IMAGE_NAME:$TAG"

# 确定当前运行的环境
if docker ps --format "table {{.Names}}" | grep -q "app_green"; then
    CURRENT="green"
    NEXT="blue"
else
    CURRENT="blue"
    NEXT="green"
fi

echo "当前环境: $CURRENT"
echo "部署到环境: $NEXT"

# 部署新环境
if [ "$NEXT" = "blue" ]; then
    docker-compose -f docker-compose.yml -f docker-compose.blue.yml up -d --force-recreate app_blue
    # 等待健康检查
    sleep 10
    # 切换流量
    ./scripts/switch-blue-green.sh blue
    # 停止旧环境
    docker-compose stop app_green
else
    docker-compose -f docker-compose.yml -f docker-compose.green.yml up -d --force-recreate app_green
    sleep 10
    ./scripts/switch-blue-green.sh green
    docker-compose stop app_blue
fi

echo "部署完成!"