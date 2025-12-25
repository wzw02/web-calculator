#!/bin/bash
# Rollback Script

set -e

cd /opt/web-calculator

# 检查当前活动颜色
if grep -q "server app_blue:5000 max_fails" nginx/conf.d/default.conf; then
    CURRENT="blue"
    PREVIOUS="green"
else
    CURRENT="green"
    PREVIOUS="blue"
fi

echo "Rolling back from $CURRENT to $PREVIOUS"

# 切换流量
if [ "$PREVIOUS" = "green" ]; then
    sed -i 's/server app_blue:5000 max_fails=1 fail_timeout=5s;/server app_blue:5000;/' nginx/conf.d/default.conf
    sed -i 's/server app_green:5000;/server app_green:5000 max_fails=1 fail_timeout=5s;/' nginx/conf.d/default.conf
else
    sed -i 's/server app_green:5000 max_fails=1 fail_timeout=5s;/server app_green:5000;/' nginx/conf.d/default.conf
    sed -i 's/server app_blue:5000;/server app_blue:5000 max_fails=1 fail_timeout=5s;/' nginx/conf.d/default.conf
fi

# 确保上一个版本正在运行
docker-compose start app_${PREVIOUS}

# 等待健康检查
echo "Waiting for $PREVIOUS to be healthy..."
for i in {1..30}; do
    if docker-compose ps app_${PREVIOUS} | grep -q "(healthy)"; then
        echo "$PREVIOUS is healthy"
        break
    fi
    sleep 2
done

# 重新加载Nginx
docker-compose exec -T proxy nginx -s reload

# 停止当前版本
docker-compose stop app_${CURRENT}

echo "✅ Rollback completed to $PREVIOUS version"