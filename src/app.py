#!/usr/bin/env python3
"""
Web 计算器应用 - Flask 实现
支持基本数学运算和健康检查
"""

from flask import Flask, jsonify
import logging
import os
from typing import Dict, Any
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 获取环境变量
PORT = int(os.getenv("PORT", "5000"))
ENVIRONMENT = os.getenv("FLASK_ENV", "development")
VERSION = os.getenv("APP_VERSION", "1.0.0")
DEPLOYMENT_COLOR = os.getenv("DEPLOYMENT_COLOR", "unknown")


@app.route("/")
def index() -> Dict[str, str]:
    """主页"""
    return jsonify(
        {
            "message": "Web 计算器 API",
            "version": VERSION,
            "environment": ENVIRONMENT,
            "deployment_color": DEPLOYMENT_COLOR,
            "port": PORT,
            "endpoints": {
                "health": "/health",
                "add": "/add/<a>&<b>",
                "subtract": "/subtract/<a>&<b>",
                "multiply": "/multiply/<a>&<b>",
                "divide": "/divide/<a>&<b>",
            },
        }
    )


@app.route("/health")
def health() -> Dict[str, Any]:
    """健康检查端点"""
    return jsonify(
        {
            "status": "healthy",
            "version": VERSION,
            "timestamp": datetime.now().isoformat(),
            "environment": ENVIRONMENT,
            "deployment_color": DEPLOYMENT_COLOR,
        }
    )


@app.route("/add/<a>&<b>")
def add(a: str, b: str) -> Dict[str, Any]:
    """加法运算"""
    try:
        num_a = float(a)
        num_b = float(b)
        result = num_a + num_b

        logger.info(f"加法运算: {num_a} + {num_b} = {result}")

        return jsonify(
            {
                "operation": "addition",
                "a": num_a,
                "b": num_b,
                "result": result,
                "success": True,
            }
        )
    except ValueError:
        return (
            jsonify(
                {
                    "operation": "addition",
                    "error": "参数必须是数字",
                    "success": False,
                }
            ),
            400,
        )


@app.route("/subtract/<a>&<b>")
def subtract(a: str, b: str) -> Dict[str, Any]:
    """减法运算"""
    try:
        num_a = float(a)
        num_b = float(b)
        result = num_a - num_b

        logger.info(f"减法运算: {num_a} - {num_b} = {result}")

        return jsonify(
            {
                "operation": "subtraction",
                "a": num_a,
                "b": num_b,
                "result": result,
                "success": True,
            }
        )
    except ValueError:
        return (
            jsonify(
                {
                    "operation": "subtraction",
                    "error": "参数必须是数字",
                    "success": False,
                }
            ),
            400,
        )


@app.route("/multiply/<a>&<b>")
def multiply(a: str, b: str) -> Dict[str, Any]:
    """乘法运算"""
    try:
        num_a = float(a)
        num_b = float(b)
        result = num_a * num_b

        logger.info(f"乘法运算: {num_a} * {num_b} = {result}")

        return jsonify(
            {
                "operation": "multiplication",
                "a": num_a,
                "b": num_b,
                "result": result,
                "success": True,
            }
        )
    except ValueError:
        return (
            jsonify(
                {
                    "operation": "multiplication",
                    "error": "参数必须是数字",
                    "success": False,
                }
            ),
            400,
        )


@app.route("/divide/<a>&<b>")
def divide(a: str, b: str) -> Dict[str, Any]:
    """除法运算"""
    try:
        num_a = float(a)
        num_b = float(b)

        if num_b == 0:
            return (
                jsonify(
                    {
                        "operation": "division",
                        "error": "除数不能为零",
                        "success": False,
                    }
                ),
                400,
            )

        result = num_a / num_b

        logger.info(f"除法运算: {num_a} / {num_b} = {result}")

        return jsonify(
            {
                "operation": "division",
                "a": num_a,
                "b": num_b,
                "result": result,
                "success": True,
            }
        )
    except ValueError:
        return (
            jsonify(
                {
                    "operation": "division",
                    "error": "参数必须是数字",
                    "success": False,
                }
            ),
            400,
        )


@app.route("/version")
def version() -> Dict[str, str]:
    """版本信息"""
    return jsonify(
        {
            "name": "web-calculator",
            "version": VERSION,
            "environment": ENVIRONMENT,
            "deployment_color": DEPLOYMENT_COLOR,
            "api_version": "1.0",
        }
    )


@app.errorhandler(404)
def not_found(error) -> Dict[str, str]:
    """404 错误处理"""
    return (
        jsonify(
            {
                "error": "Endpoint not found",
                "message": "请检查 API 文档",
                "success": False,
            }
        ),
        404,
    )


@app.errorhandler(500)
def internal_error(error) -> Dict[str, str]:
    """500 错误处理"""
    logger.error("服务器内部错误: %s", str(error))
    return (
        jsonify(
            {
                "error": "Internal server error",
                "message": "服务器遇到问题，请稍后再试",
                "success": False,
            }
        ),
        500,
    )


if __name__ == "__main__":
    logger.info("启动 Web 计算器应用...")
    logger.info("环境: %s", ENVIRONMENT)
    logger.info("版本: %s", VERSION)
    logger.info("部署颜色: %s", DEPLOYMENT_COLOR)
    logger.info("监听端口: %s", PORT)

    host = "127.0.0.1" if ENVIRONMENT == "production" else "0.0.0.0"

    app.run(
        host=host,
        port=PORT,
        debug=(ENVIRONMENT == "development"),
        threaded=True,
    )
