#!/bin/bash
set -e

# 读取当前活跃环境
CURRENT_COLOR_FILE=".current_color"
if [ -f "$CURRENT_COLOR_FILE" ]; then
    CURRENT_COLOR=$(cat $CURRENT_COLOR_FILE)
else
    CURRENT_COLOR="blue"
    echo "blue" > $CURRENT_COLOR_FILE
fi

# 确定新环境
if [ "$CURRENT_COLOR" = "blue" ]; then
    NEW_COLOR="green"
    OLD_PORT="5001"
    NEW_PORT="5002"
else
    NEW_COLOR="blue"
    OLD_PORT="5002"
    NEW_PORT="5001"
fi

echo " 当前环境: $CURRENT_COLOR"
echo " 新环境: $NEW_COLOR"
echo "  镜像标签: $IMAGE_TAG"

# 更新新环境的镜像
sed -i "s/IMAGE_TAG=.*/IMAGE_TAG=$IMAGE_TAG/" .env.$NEW_COLOR

# 启动新环境
echo " 启动 $NEW_COLOR 环境..."
docker-compose up -d app_$NEW_COLOR

# 健康检查
echo " 进行健康检查..."
for i in {1..30}; do
    if curl -f http://localhost:$NEW_PORT/health > /dev/null 2>&1; then
        echo " $NEW_COLOR 环境健康检查通过"
        break
    fi
    if [ $i -eq 30 ]; then
        echo " $NEW_COLOR 环境健康检查失败"
        exit 1
    fi
    sleep 2
done

# 切换流量
echo " 切换流量到 $NEW_COLOR 环境..."
cp nginx/upstream-$NEW_COLOR.conf nginx/upstream.conf
docker-compose exec -T proxy nginx -s reload

# 等待旧环境连接断开
sleep 10

# 停止旧环境
echo " 停止 $CURRENT_COLOR 环境..."
docker-compose stop app_$CURRENT_COLOR

# 更新当前环境记录
echo $NEW_COLOR > $CURRENT_COLOR_FILE

echo " 部署完成！$NEW_COLOR 环境已激活"
