#!/bin/bash
# 简化版Blue-Green部署脚本

set -e

echo "=== 简化版Blue-Green部署 ==="

# 构建镜像
echo "1. 构建Docker镜像..."
docker build -t web-calculator:local -f docker/Dockerfile .

# 检查当前运行的环境
CURRENT_PORT=""
if docker ps --format "table {{.Names}} {{.Ports}}" | grep -q "web-calculator-blue"; then
    CURRENT_PORT="8080"
    NEXT_PORT="8081"
    CURRENT_NAME="blue"
    NEXT_NAME="green"
elif docker ps --format "table {{.Names}} {{.Ports}}" | grep -q "web-calculator-green"; then
    CURRENT_PORT="8081"
    NEXT_PORT="8080"
    CURRENT_NAME="green"
    NEXT_NAME="blue"
else
    CURRENT_PORT="8080"
    NEXT_PORT="8081"
    CURRENT_NAME="blue"
    NEXT_NAME="green"
fi

echo "2. 当前环境: $CURRENT_NAME (端口: $CURRENT_PORT)"
echo "   部署到环境: $NEXT_NAME (端口: $NEXT_PORT)"

# 停止并移除下一个环境的容器
echo "3. 清理 $NEXT_NAME 环境..."
docker stop web-calculator-$NEXT_NAME 2>/dev/null || true
docker rm web-calculator-$NEXT_NAME 2>/dev/null || true

# 启动新环境
echo "4. 启动 $NEXT_NAME 环境..."
docker run -d \
    --name web-calculator-$NEXT_NAME \
    -p $NEXT_PORT:5000 \
    -e FLASK_ENV=production \
    -e APP_COLOR=$NEXT_NAME \
    web-calculator:local

# 等待健康检查
echo "5. 等待 $NEXT_NAME 环境启动..."
for i in {1..15}; do
    if curl -f http://localhost:$NEXT_PORT/health > /dev/null 2>&1; then
        echo "   ✅ $NEXT_NAME 环境健康检查通过"
        break
    fi
    sleep 2
    echo "   等待中... ($i/15)"
    
    if [ $i -eq 15 ]; then
        echo "   ❌ $NEXT_NAME 环境启动失败，执行回滚..."
        docker stop web-calculator-$NEXT_NAME 2>/dev/null || true
        docker rm web-calculator-$NEXT_NAME 2>/dev/null || true
        echo "   ✅ 已回滚，保持 $CURRENT_NAME 环境运行"
        exit 1
    fi
done

# 测试新环境
echo "6. 测试 $NEXT_NAME 环境..."
curl -s "http://localhost:$NEXT_PORT/add/2/3" | grep -q '"result":5' && \
    echo "   ✅ $NEXT_NAME 环境功能测试通过" || \
    echo "   ⚠️  $NEXT_NAME 环境功能测试警告"

# 模拟流量切换（在实际环境中这里会更新负载均衡器）
echo "7. 模拟流量切换..."
echo "   在实际生产中，这里会："
echo "   1. 更新负载均衡器配置指向 $NEXT_NAME 环境"
echo "   2. 等待连接耗尽"
echo "   3. 停止 $CURRENT_NAME 环境"

# 停止旧环境（可选）
read -p "是否停止旧 $CURRENT_NAME 环境？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "8. 停止旧 $CURRENT_NAME 环境..."
    docker stop web-calculator-$CURRENT_NAME 2>/dev/null || true
    echo "   ✅ 旧环境已停止"
else
    echo "8. 保留旧 $CURRENT_NAME 环境以便快速回滚"
fi

echo "=== 部署完成 ==="
echo "新环境访问地址: http://localhost:$NEXT_PORT"
echo "健康检查: curl http://localhost:$NEXT_PORT/health"
echo "测试计算: curl http://localhost:$NEXT_PORT/add/5/3"