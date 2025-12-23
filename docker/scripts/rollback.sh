#!/bin/bash

# 回滚到指定环境
set -e

ROLLBACK_TO=${1:-"blue"}

echo "回滚到 $ROLLBACK_TO 环境"

if [ "$ROLLBACK_TO" = "blue" ]; then
    ACTIVE="webcalc-blue:5001"
    BACKUP="webcalc-green:5002"
else
    ACTIVE="webcalc-green:5002"
    BACKUP="webcalc-blue:5001"
fi

# 更新 Nginx 配置
cat > /opt/web-calculator/docker/nginx/upstream.conf << EOF
upstream webcalc_upstream {
    server $ACTIVE;
    server $BACKUP backup;
}
EOF

# 重新加载 Nginx
docker exec webcalc-nginx nginx -s reload

echo "回滚完成，$ROLLBACK_TO 环境现在活跃"
