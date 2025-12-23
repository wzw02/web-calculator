"""最简单的计算器测试，确保CI能通过"""
import sys
import os
sys.path.insert(0, os.path.abspath('.'))

def test_calculator_basics():
    """基本计算器功能测试"""
    from app.calculator import Calculator
    
    # 测试加法
    assert Calculator.add(2, 3) == 5
    print("✓ 加法测试通过")
    
    # 测试减法
    assert Calculator.subtract(5, 3) == 2
    print("✓ 减法测试通过")
    
    # 测试乘法
    assert Calculator.multiply(4, 5) == 20
    print("✓ 乘法测试通过")
    
    # 测试除法
    assert Calculator.divide(10, 2) == 5
    print("✓ 除法测试通过")
    
    # 测试除零异常
    try:
        Calculator.divide(5, 0)
        assert False, "应该抛出异常"
    except ValueError as e:
        assert "除数不能为零" in str(e)
        print("✓ 除零异常测试通过")
    
    print("\n✅ 所有计算器测试通过！")
    return True

if __name__ == "__main__":
    test_calculator_basics()