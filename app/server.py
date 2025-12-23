from flask import Flask, jsonify, request
from app.calculator import Calculator

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "name": "Web Calculator API",
        "version": "1.0.0",
        "endpoints": {
            "add": "/add?a=5&b=3",
            "subtract": "/subtract?a=5&b=3", 
            "multiply": "/multiply?a=4&b=5",
            "divide": "/divide?a=10&b=2",
            "health": "/health"
        }
    })

@app.route('/add')
def add():
    try:
        a = float(request.args.get('a', 0))
        b = float(request.args.get('b', 0))
        result = Calculator.add(a, b)
        return jsonify({"operation": "add", "a": a, "b": b, "result": result})
    except (ValueError, TypeError):
        return jsonify({"error": "无效的参数"}), 400

@app.route('/subtract')
def subtract():
    try:
        a = float(request.args.get('a', 0))
        b = float(request.args.get('b', 0))
        result = Calculator.subtract(a, b)
        return jsonify({"operation": "subtract", "a": a, "b": b, "result": result})
    except (ValueError, TypeError):
        return jsonify({"error": "无效的参数"}), 400

@app.route('/multiply')
def multiply():
    try:
        a = float(request.args.get('a', 0))
        b = float(request.args.get('b', 0))
        result = Calculator.multiply(a, b)
        return jsonify({"operation": "multiply", "a": a, "b": b, "result": result})
    except (ValueError, TypeError):
        return jsonify({"error": "无效的参数"}), 400

@app.route('/divide')
def divide():
    try:
        a = float(request.args.get('a', 0))
        b = float(request.args.get('b', 1))
        if b == 0:
            return jsonify({"error": "除数不能为零"}), 400
        result = Calculator.divide(a, b)
        return jsonify({"operation": "divide", "a": a, "b": b, "result": result})
    except (ValueError, TypeError):
        return jsonify({"error": "无效的参数"}), 400

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)