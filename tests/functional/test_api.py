import requests
import unittest
import time

class TestAPI(unittest.TestCase):
    BASE_URL = "http://localhost:5000"
    
    def setUp(self):
        # 等待服务启动
        max_attempts = 10
        for i in range(max_attempts):
            try:
                response = requests.get(f"{self.BASE_URL}/health", timeout=2)
                if response.status_code == 200:
                    break
            except:
                if i == max_attempts - 1:
                    raise Exception("服务启动失败")
                time.sleep(1)
    
    def test_health(self):
        response = requests.get(f"{self.BASE_URL}/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "healthy")
    
    def test_add_endpoint(self):
        response = requests.get(f"{self.BASE_URL}/add/5/3")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], 8)
    
    def test_multiply_endpoint(self):
        response = requests.get(f"{self.BASE_URL}/multiply/4/5")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], 20)
    
    def test_divide_endpoint(self):
        response = requests.get(f"{self.BASE_URL}/divide/10/2")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], 5)
    
    def test_divide_by_zero(self):
        response = requests.get(f"{self.BASE_URL}/divide/5/0")
        self.assertEqual(response.status_code, 400)
        self.assertIn("除数不能为零", response.json()["error"])

if __name__ == '__main__':
    unittest.main()