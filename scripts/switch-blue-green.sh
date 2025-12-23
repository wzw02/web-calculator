#!/bin/bash

# 切换 Blue-Green 流量
TARGET=$1

if [ "$TARGET" = "blue" ]; then
    echo "切换流量到 Blue 环境"
    cp docker/nginx/nginx.blue.conf docker/nginx/nginx.conf
elif [ "$TARGET" = "green" ]; then
    echo "切换流量到 Green 环境"
    cp docker/nginx/nginx.green.conf docker/nginx/nginx.conf
else
    echo "错误: 目标环境必须是 'blue' 或 'green'"
    exit 1
fi

# 重新加载 Nginx
docker exec web-calculator-proxy nginx -s reload