from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Web Calculator API", 
                    "endpoints": ["/add/<a>&<b>", "/subtract/<a>&<b>", 
                                  "/multiply/<a>&<b>", "/divide/<a>&<b>", 
                                  "/health"]})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/add/<a>&<b>')
def add(a, b):
    try:
        result = float(a) + float(b)
        return jsonify({"operation": "add", "result": result})
    except ValueError:
        return jsonify({"error": "Invalid input"}), 400

@app.route('/subtract/<a>&<b>')
def subtract(a, b):
    try:
        result = float(a) - float(b)
        return jsonify({"operation": "subtract", "result": result})
    except ValueError:
        return jsonify({"error": "Invalid input"}), 400

@app.route('/multiply/<a>&<b>')
def multiply(a, b):
    try:
        result = float(a) * float(b)
        return jsonify({"operation": "multiply", "result": result})
    except ValueError:
        return jsonify({"error": "Invalid input"}), 400

@app.route('/divide/<a>&<b>')
def divide(a, b):
    try:
        if float(b) == 0:
            return jsonify({"error": "Division by zero"}), 400
        result = float(a) / float(b)
        return jsonify({"operation": "divide", "result": result})
    except ValueError:
        return jsonify({"error": "Invalid input"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
