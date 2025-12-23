#!/bin/bash
# 本地模拟Blue-Green部署脚本

set -e

echo "=== 本地Blue-Green部署模拟 ==="

# 获取当前时间戳作为版本标签
VERSION_TAG="v$(date +%Y%m%d-%H%M%S)"
echo "部署版本: $VERSION_TAG"

# 构建新镜像
echo "1. 构建Docker镜像..."
docker build -t web-calculator:$VERSION_TAG -f docker/Dockerfile .

# 检查当前活动环境
if docker ps --format "table {{.Names}}" | grep -q "web-calculator-blue" && \
   docker ps --format "table {{.Names}}" | grep "web-calculator-blue" | grep -q "Up"; then
    CURRENT="blue"
    NEXT="green"
else
    CURRENT="green"
    NEXT="blue"
fi

echo "2. 当前活动环境: $CURRENT"
echo "   部署到环境: $NEXT"

# 停止并移除下一个环境的容器
echo "3. 准备 $NEXT 环境..."
docker stop web-calculator-$NEXT 2>/dev/null || true
docker rm web-calculator-$NEXT 2>/dev/null || true

# 启动下一个环境
echo "4. 启动 $NEXT 环境..."
if [ "$NEXT" = "blue" ]; then
    docker run -d \
        --name web-calculator-blue \
        --network web-calculator_webcalc-network \
        -e FLASK_ENV=production \
        -e APP_COLOR=blue \
        --health-cmd="curl -f http://localhost:5000/health || exit 1" \
        --health-interval=10s \
        --health-timeout=2s \
        --health-retries=3 \
        --health-start-period=30s \
        web-calculator:$VERSION_TAG
else
    docker run -d \
        --name web-calculator-green \
        --network web-calculator_webcalc-network \
        -e FLASK_ENV=production \
        -e APP_COLOR=green \
        --health-cmd="curl -f http://localhost:5000/health || exit 1" \
        --health-interval=10s \
        --health-timeout=2s \
        --health-retries=3 \
        --health-start-period=30s \
        web-calculator:$VERSION_TAG
fi

# 等待新环境健康检查
echo "5. 等待 $NEXT 环境健康检查..."
for i in {1..30}; do
    if docker inspect --format='{{.State.Health.Status}}' web-calculator-$NEXT | grep -q "healthy"; then
        echo "   $NEXT 环境健康检查通过！"
        break
    fi
    sleep 2
    echo "   等待中... ($i/30)"
    
    if [ $i -eq 30 ]; then
        echo "   ⚠️  $NEXT 环境健康检查超时，部署失败！"
        echo "   执行回滚：恢复 $CURRENT 环境..."
        
        # 回滚：停止新的失败环境
        docker stop web-calculator-$NEXT 2>/dev/null || true
        docker rm web-calculator-$NEXT 2>/dev/null || true
        
        echo "   ✅ 回滚完成，继续使用 $CURRENT 环境"
        exit 1
    fi
done

# 切换Nginx配置
echo "6. 切换流量到 $NEXT 环境..."
if [ "$NEXT" = "blue" ]; then
    # 切换到blue
    cat > docker/nginx/conf.d/upstream.conf << EOF
upstream webcalc_upstream {
    server app_blue:5000 max_fails=1 fail_timeout=5s;
    server app_green:5000 backup;
}
EOF
else
    # 切换到green
    cat > docker/nginx/conf.d/upstream.conf << EOF
upstream webcalc_upstream {
    server app_green:5000 max_fails=1 fail_timeout=5s;
    server app_blue:5000 backup;
}
EOF
fi

# 重新加载Nginx
echo "7. 重新加载Nginx配置..."
docker exec web-calculator-proxy nginx -s reload 2>/dev/null || true

# 验证部署
echo "8. 验证部署..."
sleep 3
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "   ✅ 部署验证成功！"
    
    # 停止旧环境（可选，保留作为快速回滚）
    echo "9. 停止旧 $CURRENT 环境..."
    docker stop web-calculator-$CURRENT 2>/dev/null || true
    
    # 记录部署历史
    echo "$(date): 部署版本 $VERSION_TAG 到 $NEXT 环境" >> deployment-history.log
else
    echo "   ❌ 部署验证失败！执行回滚..."
    
    # 回滚到旧环境
    if [ "$CURRENT" = "blue" ]; then
        cat > docker/nginx/conf.d/upstream.conf << EOF
upstream webcalc_upstream {
    server app_blue:5000 max_fails=1 fail_timeout=5s;
    server app_green:5000 backup;
}
EOF
    else
        cat > docker/nginx/conf.d/upstream.conf << EOF
upstream webcalc_upstream {
    server app_green:5000 max_fails=1 fail_timeout=5s;
    server app_blue:5000 backup;
}
EOF
    fi
    
    docker exec web-calculator-proxy nginx -s reload 2>/dev/null || true
    docker stop web-calculator-$NEXT 2>/dev/null || true
    docker rm web-calculator-$NEXT 2>/dev/null || true
    
    echo "   ✅ 回滚到 $CURRENT 环境完成"
fi

echo "=== 部署完成 ==="
echo "访问地址: http://localhost:8080"
echo "健康检查: http://localhost:8080/health"
echo "Nginx状态: http://localhost:8080/status"
