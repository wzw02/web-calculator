from flask import Flask, request, jsonify
import sys
import os

# 添加当前目录到Python路径
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

class Calculator:
        def add(self, a, b):
            """加法运算"""
            return a + b
        
        def subtract(self, a, b):
            """减法运算"""
            return a - b
        
        def multiply(self, a, b):
            """乘法运算"""
            return a * b
        
        def divide(self, a, b):
            """除法运算"""
            if b == 0:
                raise ValueError("Division by zero")
            return a / b
        
        def power(self, a, b):
            """幂运算"""
            return a ** b

app = Flask(__name__)
calc = Calculator()

app = Flask(__name__)
calc = Calculator()

app = Flask(__name__)
calc = Calculator()

@app.route('/')
def index():
    """API首页"""
    return jsonify({
        "name": "Web Calculator API",
        "version": "1.0.0",
        "endpoints": {
            "add": "/add/<a>&<b>",
            "subtract": "/subtract/<a>&<b>",
            "multiply": "/multiply/<a>&<b>",
            "divide": "/divide/<a>&<b>",
            "power": "/power/<a>&<b>",
            "health": "/health"
        }
    })

@app.route('/add/<a>&<b>')
def add(a, b):
    """加法端点"""
    try:
        result = calc.add(float(a), float(b))
        return jsonify({
            "operation": "add",
            "operands": [float(a), float(b)],
            "result": result
        })
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/subtract/<a>&<b>')
def subtract(a, b):
    """减法端点"""
    try:
        result = calc.subtract(float(a), float(b))
        return jsonify({
            "operation": "subtract",
            "operands": [float(a), float(b)],
            "result": result
        })
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/multiply/<a>&<b>')
def multiply(a, b):
    """乘法端点"""
    try:
        result = calc.multiply(float(a), float(b))
        return jsonify({
            "operation": "multiply",
            "operands": [float(a), float(b)],
            "result": result
        })
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/divide/<a>&<b>')
def divide(a, b):
    """除法端点"""
    try:
        result = calc.divide(float(a), float(b))
        return jsonify({
            "operation": "divide",
            "operands": [float(a), float(b)],
            "result": result
        })
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/power/<a>&<b>')
def power(a, b):
    """幂运算端点"""
    try:
        result = calc.power(float(a), float(b))
        return jsonify({
            "operation": "power",
            "operands": [float(a), float(b)],
            "result": result
        })
    except (ValueError, OverflowError) as e:
        return jsonify({"error": str(e)}), 400

@app.route('/health')
def health():
    """健康检查端点"""
    return jsonify({
        "status": "healthy",
        "service": "web-calculator",
        "timestamp": "2024-01-01T00:00:00Z"
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)