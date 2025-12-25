# Web Calculator CI/CD with Blue-Green Deployment

## 📋 项目概述

这是一个使用 Flask 构建的 Web 计算器应用，实现了完整的 CI/CD 流水线，并采用 Blue-Green 部署策略。

## 🏗️ 项目结构
web-calculator/
├── app.py # Flask 主应用
├── calculator.py # 计算器核心逻辑
├── requirements.txt # Python 依赖
├── Dockerfile # Docker 镜像配置
├── docker-compose.yml # Blue-Green 部署配置
├── .github/workflows/ # GitHub Actions CI/CD
│ └── ci-cd.yml
├── nginx/ # Nginx 反向代理配置
│ └── conf.d/
│ └── default.conf
├── tests/ # 测试文件
│ ├── unit_tests/
│ │ └── test_calculator.py
│ └── functional_tests/
│ ├── conftest.py
│ └── test_api.py
├── scripts/ # 部署脚本
│ ├── deploy.sh
│ └── rollback.sh
├── .gitignore # Git 忽略文件
└── README.md # 项目文档

## 🚀 快速开始

### 本地开发
```bash
# 克隆项目
git clone <repository-url>
cd web-calculator

# 安装依赖
pip install -r requirements.txt

# 运行应用
python app.py

# 访问应用
curl http://localhost:5000/