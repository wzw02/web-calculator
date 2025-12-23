import pytest
from src.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    """测试健康检查端点"""
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json == {'status': 'healthy'}

def test_add_endpoint(client):
    """测试加法端点"""
    response = client.get('/add/2/3')
    assert response.status_code == 200
    # 根据实际应用调整断言
    # assert response.json == {'result': 5}

def test_multiply_endpoint(client):
    """测试乘法端点"""
    response = client.get('/multiply/2/3')
    assert response.status_code == 200
    # assert response.json == {'result': 6}

if __name__ == '__main__':
    pytest.main()