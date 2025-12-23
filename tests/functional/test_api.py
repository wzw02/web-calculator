import unittest
import sys
import os

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from app.server import app

class TestAPI(unittest.TestCase):
    
    def setUp(self):
        # 创建测试客户端
        self.client = app.test_client()
        self.client.testing = True
    
    def test_health(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['status'], 'healthy')
    
    def test_add_endpoint(self):
        response = self.client.get('/add/5/0/3/0')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['result'], 8.0)
    
    def test_multiply_endpoint(self):
        response = self.client.get('/multiply/4/0/5/0')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['result'], 20.0)
    
    def test_divide_endpoint(self):
        response = self.client.get('/divide/10/0/2/0')
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['result'], 5.0)
    
    def test_divide_by_zero(self):
        response = self.client.get('/divide/5/0/0/0')
        self.assertEqual(response.status_code, 400)
        data = response.get_json()
        self.assertIn('除数不能为零', data['error'])

if __name__ == '__main__':
    unittest.main()