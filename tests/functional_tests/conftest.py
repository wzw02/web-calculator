import pytest
import subprocess
import time
import sys
import os

@pytest.fixture(scope="session")
def flask_app():
    """启动Flask应用"""
    # 启动应用
    proc = subprocess.Popen(
        [sys.executable, os.path.join(os.path.dirname(__file__), '../../app.py')],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # 等待应用启动
    time.sleep(5)
    
    yield
    
    # 测试结束后停止应用
    proc.terminate()
    proc.wait()