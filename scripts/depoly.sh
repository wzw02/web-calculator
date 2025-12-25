#!/bin/bash
# Blue-Green Deployment Script

set -e

COLOR=$1
if [[ ! "$COLOR" =~ ^(blue|green)$ ]]; then
    echo "Usage: $0 [blue|green]"
    exit 1
fi

echo "Deploying to $COLOR environment..."

# 确定当前活动颜色
if grep -q "server app_blue:5000 max_fails" nginx/conf.d/default.conf; then
    CURRENT="blue"
else
    CURRENT="green"
fi

if [ "$COLOR" = "$CURRENT" ]; then
    echo "Already on $COLOR environment"
    exit 0
fi

# 更新环境变量
if [ "$COLOR" = "blue" ]; then
    echo "BLUE_TAG=latest" > .env
    echo "GREEN_TAG=previous" >> .env
else
    echo "BLUE_TAG=previous" > .env
    echo "GREEN_TAG=latest" >> .env
fi

# 拉取镜像
docker-compose pull app_${COLOR}

# 启动新版本
docker-compose up -d app_${COLOR}

# 等待健康检查
echo "Waiting for $COLOR to be healthy..."
for i in {1..30}; do
    if docker-compose ps app_${COLOR} | grep -q "(healthy)"; then
        echo "$COLOR is healthy"
        break
    fi
    sleep 2
done

# 切换流量
if [ "$COLOR" = "green" ]; then
    sed -i 's/server app_blue:5000 max_fails=1 fail_timeout=5s;/server app_blue:5000;/' nginx/conf.d/default.conf
    sed -i 's/server app_green:5000;/server app_green:5000 max_fails=1 fail_timeout=5s;/' nginx/conf.d/default.conf
else
    sed -i 's/server app_green:5000 max_fails=1 fail_timeout=5s;/server app_green:5000;/' nginx/conf.d/default.conf
    sed -i 's/server app_blue:5000;/server app_blue:5000 max_fails=1 fail_timeout=5s;/' nginx/conf.d/default.conf
fi

# 重新加载Nginx
docker-compose exec -T proxy nginx -s reload

echo "✅ Successfully switched to $COLOR environment"