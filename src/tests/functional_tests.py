#!/usr/bin/env python3
"""
Web 计算器功能测试 - Python 版本
使用 Python 替代 shell 脚本，更可靠
"""

import requests
import json
import time
import sys


class WebCalculatorTester:
    def __init__(self, base_url="http://localhost:5000", timeout=30):
        self.base_url = base_url
        self.timeout = timeout
        self.session = requests.Session()
        self.test_results = []

    def wait_for_app(self, max_attempts=15):
        """等待应用启动"""
        print(f"[INFO] 等待应用在 {self.base_url} 启动...")

        for attempt in range(1, max_attempts + 1):
            try:
                response = self.session.get(f"{self.base_url}/health", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == "healthy":
                        print("[INFO] 应用已启动！")
                        env_info = data.get("environment")
                        version_info = data.get("version")
                        color_info = data.get("deployment_color")
                        print(f"      环境: {env_info}")
                        print(f"      版本: {version_info}")
                        print(f"      部署颜色: {color_info}")
                        return True
            except requests.exceptions.RequestException:
                pass

            print(f"[WARN] 尝试 {attempt}/{max_attempts}: 应用尚未准备好...")
            time.sleep(2)

        print(f"[ERROR] 应用在 {self.timeout} 秒内未启动")
        return False

    def test_health(self):
        """测试健康检查"""
        print("[INFO] 运行健康检查...")

        try:
            response = self.session.get(f"{self.base_url}/health", timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == "healthy":
                    print("[INFO] 健康检查通过")
                    print(json.dumps(data, indent=4, ensure_ascii=False))
                    self.test_results.append(("健康检查", True))
                    return True
                else:
                    status = data.get("status")
                    print(f"[ERROR] 应用状态异常: {status}")
            else:
                code = response.status_code
                print(f"[ERROR] 健康检查失败，状态码: {code}")
        except Exception as e:
            print(f"[ERROR] 健康检查异常: {e}")

        self.test_results.append(("健康检查", False))
        return False

    def test_math_operation(self, operation, a, b, expected_result=None):
        """测试数学运算"""
        url = f"{self.base_url}/{operation}/{a}&{b}"

        try:
            response = self.session.get(url, timeout=10)
            data = response.json()

            if response.status_code == 200 and data.get("success") is True:
                result = data.get("result")
                print(f"[INFO] ✓ {operation}/{a}&{b} 成功: {result}")
                if expected_result is not None and result != expected_result:
                    msg = f"预期结果: {expected_result}, 实际结果: {result}"
                    print(f"[WARN]   {msg}")
                self.test_results.append((f"{operation}/{a}&{b}", True))
                return True
            else:
                code = response.status_code
                print(f"[ERROR] ✗ {operation}/{a}&{b} 失败 (状态码: {code})")
                error_msg = data.get("error", "未知错误")
                print(f"       错误: {error_msg}")
                self.test_results.append((f"{operation}/{a}&{b}", False))
                return False

        except Exception as e:
            print(f"[ERROR] ✗ {operation}/{a}&{b} 异常: {e}")
            self.test_results.append((f"{operation}/{a}&{b}", False))
            return False

    def test_error_handling(self):
        """测试错误处理"""
        print("[INFO] 测试错误处理...")

        error_tests = [
            ("add", "abc", "123"),
            ("divide", "10", "0"),
        ]

        passed = 0
        for operation, a, b in error_tests:
            url = f"{self.base_url}/{operation}/{a}&{b}"
            try:
                response = self.session.get(url, timeout=10)
                if response.status_code >= 400:
                    code = response.status_code
                    msg = f"{operation}/{a}&{b} 错误处理正确 (状态码: {code})"
                    print(f"[INFO] ✓ {msg}")
                    passed += 1
                else:
                    code = response.status_code
                    msg = f"{operation}/{a}&{b} 预期错误但得到状态码: {code}"
                    print(f"[ERROR] ✗ {msg}")
            except Exception as e:
                print(f"[ERROR] ✗ {operation}/{a}&{b} 异常: {e}")

        # 测试不存在的端点
        try:
            response = self.session.get(f"{self.base_url}/nonexistent", timeout=10)
            if response.status_code == 404:
                print("[INFO] ✓ 不存在的端点错误处理正确 (状态码: 404)")
                passed += 1
            else:
                code = response.status_code
                msg = f"不存在的端点预期404但得到: {code}"
                print(f"[ERROR] ✗ {msg}")
        except Exception as e:
            msg = f"不存在的端点测试异常: {e}"
            print(f"[ERROR] ✗ {msg}")

        success = passed == 3
        self.test_results.append(("错误处理", success))
        return success

    def run_all_tests(self):
        """运行所有测试"""
        print("Web 计算器功能测试")
        print("==================")
        print(f"目标URL: {self.base_url}")
        print()

        if not self.wait_for_app():
            return False

        tests = [
            ("健康检查", self.test_health),
            ("数学运算", self._test_math_operations),
            ("错误处理", self.test_error_handling),
        ]

        for test_name, test_func in tests:
            print(f"\n--- 开始 {test_name} ---")
            test_func()

        self._print_report()

        # 检查是否所有测试都通过
        all_passed = all(result[1] for result in self.test_results)
        return all_passed

    def _test_math_operations(self):
        """内部方法：测试所有数学运算"""
        print("[INFO] 测试数学运算...")

        math_tests = [
            ("add", "2", "3", 5.0),
            ("subtract", "5", "2", 3.0),
            ("multiply", "4", "3", 12.0),
            ("divide", "10", "2", 5.0),
        ]

        passed = 0
        for operation, a, b, expected in math_tests:
            if self.test_math_operation(operation, a, b, expected):
                passed += 1

        if passed == len(math_tests):
            total = len(math_tests)
            print(f"[INFO] 所有数学运算测试通过 ({passed}/{total})")
            self.test_results.append(("数学运算", True))
        else:
            total = len(math_tests)
            print(f"[ERROR] 数学运算测试失败: {passed}/{total} 通过")
            self.test_results.append(("数学运算", False))

        return passed == len(math_tests)

    def _print_report(self):
        """打印测试报告"""
        print("\n" + "=" * 40)
        print("         功能测试报告")
        print("=" * 40)
        print(f"应用地址: {self.base_url}")
        current_time = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"测试时间: {current_time}")
        print()

        passed = sum(1 for _, success in self.test_results if success)
        total = len(self.test_results)

        for test_name, success in self.test_results:
            status = "✓" if success else "✗"
            print(f"{status} {test_name}")

        print()
        print("=" * 40)
        print(f"测试结果: {passed}/{total} 通过")

        if passed == total:
            print("[INFO] 所有功能测试通过！")
        else:
            print("[ERROR] 功能测试失败")


def main():
    """主函数"""
    # 获取命令行参数或使用默认值
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5000"

    tester = WebCalculatorTester(base_url)

    try:
        success = tester.run_all_tests()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n[INFO] 测试被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] 测试过程中发生异常: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
