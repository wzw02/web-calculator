import pytest
import requests
import time

BASE_URL = "http://localhost:5000"

@pytest.fixture(scope="module")
def wait_for_service():
    """等待服务启动"""
    max_retries = 30
    for i in range(max_retries):
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=2)
            if response.status_code == 200:
                print("Service is ready")
                break
        except requests.exceptions.ConnectionError:
            pass
        time.sleep(2)
    else:
        pytest.fail("Service did not start in time")

class TestCalculatorAPI:
    def test_health_endpoint(self, wait_for_service):
        """测试健康检查"""
        response = requests.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
    
    def test_index_endpoint(self, wait_for_service):
        """测试首页"""
        response = requests.get(BASE_URL)
        assert response.status_code == 200
        data = response.json()
        assert 'endpoints' in data
    
    def test_add_endpoint(self, wait_for_service):
        """测试加法端点"""
        response = requests.get(f"{BASE_URL}/add/2&3")
        assert response.status_code == 200
        data = response.json()
        assert data['operation'] == 'add'
        assert data['result'] == 5.0
    
    def test_multiply_endpoint(self, wait_for_service):
        """测试乘法端点"""
        response = requests.get(f"{BASE_URL}/multiply/4&5")
        assert response.status_code == 200
        data = response.json()
        assert data['operation'] == 'multiply'
        assert data['result'] == 20.0
    
    def test_invalid_input(self, wait_for_service):
        """测试无效输入"""
        response = requests.get(f"{BASE_URL}/add/abc&def")
        assert response.status_code == 400
        assert 'error' in response.json()