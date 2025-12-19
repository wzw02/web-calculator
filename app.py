from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return "欢迎使用计算器！"

@app.route('/add/<a>&<b>')
def add(a, b):
    try:
        result = float(a) + float(b)
        return jsonify({"operation": "add", "result": result})
    except:
        return jsonify({"error": "输入错误"}), 400

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
