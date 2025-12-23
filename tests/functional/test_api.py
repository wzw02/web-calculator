import unittest
import sys
import os
import requests
import time

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

class TestAPI(unittest.TestCase):
    BASE_URL = "http://localhost:5001"  # 注意：这是容器的端口
    
    def setUp(self):
        # 等待服务启动
        max_attempts = 20  # 增加重试次数
        for i in range(max_attempts):
            try:
                response = requests.get(f"{self.BASE_URL}/health", timeout=2)
                if response.status_code == 200:
                    print(f"服务在第{i+1}次尝试后启动成功")
                    break
            except:
                if i == max_attempts - 1:
                    # 最后一次尝试，输出更详细的错误信息
                    print("服务启动失败，尝试直接测试应用逻辑")
                    # 这里我们选择跳过网络测试，直接测试应用逻辑
                    raise Exception("服务启动失败")
                time.sleep(1)  # 等待1秒
    
    def test_health(self):
        response = requests.get(f"{self.BASE_URL}/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "healthy")
        print("健康检查测试通过")
    
    def test_add_endpoint(self):
        response = requests.get(f"{self.BASE_URL}/add/5/3")  # 修正路径
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], 8)
        print("加法测试通过")
    
    def test_multiply_endpoint(self):
        response = requests.get(f"{self.BASE_URL}/multiply/4/5")  # 修正路径
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], 20)
        print("乘法测试通过")
    
    def test_divide_endpoint(self):
        response = requests.get(f"{self.BASE_URL}/divide/10/2")  # 修正路径
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], 5)
        print("除法测试通过")
    
    def test_divide_by_zero(self):
        response = requests.get(f"{self.BASE_URL}/divide/5/0")  # 修正路径
        self.assertEqual(response.status_code, 400)
        self.assertIn("除数不能为零", response.json()["error"])
        print("除零异常测试通过")

if __name__ == '__main__':
    unittest.main()