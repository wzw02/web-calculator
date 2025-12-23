from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/health')
def health():
    """健康检查端点"""
    return jsonify({'status': 'healthy', 'version': '1.0.0'}), 200

@app.route('/add/<int:a>/<int:b>')
def add(a, b):
    """加法计算"""
    result = a + b
    return jsonify({'operation': 'addition', 'a': a, 'b': b, 'result': result})

@app.route('/multiply/<int:a>/<int:b>')
def multiply(a, b):
    """乘法计算"""
    result = a * b
    return jsonify({'operation': 'multiplication', 'a': a, 'b': b, 'result': result})

@app.route('/subtract/<int:a>/<int:b>')
def subtract(a, b):
    """减法计算"""
    result = a - b
    return jsonify({'operation': 'subtraction', 'a': a, 'b': b, 'result': result})

@app.route('/divide/<int:a>/<int:b>')
def divide(a, b):
    """除法计算"""
    if b == 0:
        return jsonify({'error': 'Division by zero'}), 400
    result = a / b
    return jsonify({'operation': 'division', 'a': a, 'b': b, 'result': result})

@app.route('/')
def index():
    """主页"""
    return jsonify({
        'name': 'Web Calculator API',
        'version': '1.0.0',
        'endpoints': [
            '/health',
            '/add/<a>/<b>',
            '/multiply/<a>/<b>',
            '/subtract/<a>/<b>',
            '/divide/<a>/<b>'
        ]
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)