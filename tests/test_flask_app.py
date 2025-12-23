"""简单的Flask应用测试"""
import sys
import os
sys.path.insert(0, os.path.abspath('.'))

def test_flask_app_structure():
    """检查Flask应用结构"""
    import app.server
    
    # 确保应用可以导入
    assert hasattr(app.server, 'app'), "Flask应用不存在"
    print("✓ Flask应用结构正常")
    
    # 检查路由
    rules = list(app.server.app.url_map.iter_rules())
    assert len(rules) > 0, "没有定义路由"
    print(f"✓ 找到 {len(rules)} 个路由")
    
    # 检查必要的端点
    endpoints = [rule.rule for rule in rules]
    assert '/' in endpoints, "首页路由不存在"
    assert '/health' in endpoints, "健康检查路由不存在"
    
    print("✓ 基本路由检查通过")
    return True

if __name__ == "__main__":
    test_flask_app_structure()