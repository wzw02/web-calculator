#!/bin/bash

# 等待应用启动
echo "等待应用启动..."
sleep 5

# 测试健康检查
echo "测试健康检查..."
curl -f http://localhost:5000/health || exit 1

# 测试各个端点
echo "测试加法端点..."
curl -s http://localhost:5000/add/2&3 | grep -q '"result":5' || exit 1

echo "测试减法端点..."
curl -s http://localhost:5000/subtract/5&3 | grep -q '"result":2' || exit 1

echo "测试乘法端点..."
curl -s http://localhost:5000/multiply/2&3 | grep -q '"result":6' || exit 1

echo "测试除法端点..."
curl -s http://localhost:5000/divide/6&3 | grep -q '"result":2' || exit 1

echo "所有功能测试通过！"
