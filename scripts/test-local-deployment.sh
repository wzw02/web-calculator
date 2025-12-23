#!/bin/bash
# 本地测试完整CI/CD流程

echo "=== 本地CI/CD流程测试 ==="

# 1. 运行测试
echo "1. 运行测试..."
python tests/test_calculator.py
python tests/test_flask_app.py

# 2. 构建Docker镜像
echo "2. 构建Docker镜像..."
docker build -t web-calculator:local-test -f docker/Dockerfile .

# 3. 启动Blue-Green环境
echo "3. 启动Blue-Green环境..."
docker-compose down 2>/dev/null || true
docker-compose up -d

# 4. 等待服务启动
echo "4. 等待服务启动..."
sleep 10

# 5. 测试服务
echo "5. 测试服务..."
curl -f http://localhost:8080/health && echo "✅ 健康检查通过"
curl -s "http://localhost:8080/add/2/3" && echo "✅ 计算器API测试"

# 6. 模拟部署
echo "6. 模拟Blue-Green部署..."
./scripts/deploy-local.sh

echo "=== 本地CI/CD测试完成 ==="
echo "访问: http://localhost:8080"
echo "监控: docker-compose logs -f"
