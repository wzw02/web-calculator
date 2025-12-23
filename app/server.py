from flask import Flask, jsonify, request
from app.calculator import Calculator

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "name": "Web Calculator API",
        "version": "1.0.0",
        "endpoints": {
            "add": "/add/<a>/<b>",
            "subtract": "/subtract/<a>/<b>",
            "multiply": "/multiply/<a>/<b>",
            "divide": "/divide/<a>/<b>",
            "health": "/health"
        }
    })

@app.route('/add/<float:a>/<float:b>')
def add(a, b):
    result = Calculator.add(a, b)
    return jsonify({"operation": "add", "a": a, "b": b, "result": result})

@app.route('/subtract/<float:a>/<float:b>')
def subtract(a, b):
    result = Calculator.subtract(a, b)
    return jsonify({"operation": "subtract", "a": a, "b": b, "result": result})

@app.route('/multiply/<float:a>/<float:b>')
def multiply(a, b):
    result = Calculator.multiply(a, b)
    return jsonify({"operation": "multiply", "a": a, "b": b, "result": result})

@app.route('/divide/<float:a>/<float:b>')
def divide(a, b):
    try:
        result = Calculator.divide(a, b)
        return jsonify({"operation": "divide", "a": a, "b": b, "result": result})
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)