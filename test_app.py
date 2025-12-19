import pytest
from app import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_add_endpoint(client):
    response = client.get('/add/2&3')
    assert response.status_code == 200
    data = response.get_json()
    assert data['operation'] == 'add'
    assert data['result'] == 5.0

def test_subtract_endpoint(client):
    response = client.get('/subtract/5&3')
    assert response.status_code == 200
    data = response.get_json()
    assert data['operation'] == 'subtract'
    assert data['result'] == 2.0

def test_multiply_endpoint(client):
    response = client.get('/multiply/2&3')
    assert response.status_code == 200
    data = response.get_json()
    assert data['operation'] == 'multiply'
    assert data['result'] == 6.0

def test_divide_endpoint(client):
    response = client.get('/divide/6&3')
    assert response.status_code == 200
    data = response.get_json()
    assert data['operation'] == 'divide'
    assert data['result'] == 2.0

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_invalid_input(client):
    response = client.get('/add/abc&def')
    assert response.status_code == 400
