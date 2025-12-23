#!/usr/bin/env python3
"""
Web 计算器单元测试
"""

import json
import os
import sys

import pytest

# 在导入本地模块之前修改 Python 路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app import app


@pytest.fixture
def client():
    """创建测试客户端"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestHealthEndpoint:
    """健康检查端点测试"""

    def test_health_endpoint(self, client):
        """测试健康检查"""
        response = client.get('/health')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['status'] == 'healthy'
        assert 'version' in data
        assert 'timestamp' in data


class TestMathOperations:
    """数学运算测试"""

    def test_addition_valid(self, client):
        """测试有效的加法"""
        response = client.get('/add/2&3')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['operation'] == 'addition'
        assert data['a'] == 2.0
        assert data['b'] == 3.0
        assert data['result'] == 5.0
        assert data['success'] is True

    def test_addition_invalid(self, client):
        """测试无效的加法参数"""
        response = client.get('/add/abc&3')
        data = json.loads(response.data)

        assert response.status_code == 400
        assert data['success'] is False
        assert 'error' in data

    def test_subtraction_valid(self, client):
        """测试有效的减法"""
        response = client.get('/subtract/5&3')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['operation'] == 'subtraction'
        assert data['result'] == 2.0
        assert data['success'] is True

    def test_multiplication_valid(self, client):
        """测试有效的乘法"""
        response = client.get('/multiply/2&3')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['operation'] == 'multiplication'
        assert data['result'] == 6.0
        assert data['success'] is True

    def test_division_valid(self, client):
        """测试有效的除法"""
        response = client.get('/divide/6&2')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['operation'] == 'division'
        assert data['result'] == 3.0
        assert data['success'] is True

    def test_division_by_zero(self, client):
        """测试除零错误"""
        response = client.get('/divide/5&0')
        data = json.loads(response.data)

        assert response.status_code == 400
        assert data['success'] is False
        assert 'error' in data
        assert '除数不能为零' in data['error']


class TestOtherEndpoints:
    """其他端点测试"""

    def test_index_endpoint(self, client):
        """测试主页"""
        response = client.get('/')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['message'] == 'Web 计算器 API'
        assert 'endpoints' in data

    def test_version_endpoint(self, client):
        """测试版本信息"""
        response = client.get('/version')
        data = json.loads(response.data)

        assert response.status_code == 200
        assert data['name'] == 'web-calculator'
        assert 'version' in data
        assert 'deployment_color' in data

    def test_not_found(self, client):
        """测试 404 错误"""
        response = client.get('/nonexistent')
        data = json.loads(response.data)

        assert response.status_code == 404
        assert data['success'] is False
        assert 'error' in data


class TestErrorHandling:
    """错误处理测试"""

    def test_internal_error_simulation(self, client):
        """模拟内部错误处理"""
        pass


if __name__ == '__main__':
    pytest.main(['-v', __file__])
