import unittest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from app.server import app

class TestAPI(unittest.TestCase):
    
    def setUp(self):
        # 创建测试客户端
        self.app = app.test_client()
        self.app.testing = True
    
    def test_health(self):
        response = self.app.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['status'], 'healthy')
    
    def test_add_endpoint(self):
        response = self.app.get('/add/5/3')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['result'], 8)
    
    def test_multiply_endpoint(self):
        response = self.app.get('/multiply/4/5')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['result'], 20)
    
    def test_divide_endpoint(self):
        response = self.app.get('/divide/10/2')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['result'], 5)
    
    def test_divide_by_zero(self):
        response = self.app.get('/divide/5/0')
        self.assertEqual(response.status_code, 400)
        self.assertIn('除数不能为零', response.json['error'])

if __name__ == '__main__':
    unittest.main()