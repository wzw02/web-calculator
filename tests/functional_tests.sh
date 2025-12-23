#!/bin/bash
# Web 计算器功能测试脚本

set -e  # 遇到错误时退出
echo "开始功能测试..."

# 配置
APP_URL="${1:-http://localhost:5000}"
TIMEOUT=30
RETRY_INTERVAL=2

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 等待应用启动的函数
wait_for_app() {
    local max_attempts=$((TIMEOUT / RETRY_INTERVAL))
    local attempt=1
    
    log_info "等待应用在 $APP_URL 启动..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s --fail "${APP_URL}/health" > /dev/null; then
            log_info "应用已启动！"
            return 0
        fi
        
        log_warn "尝试 $attempt/$max_attempts: 应用尚未准备好..."
        sleep $RETRY_INTERVAL
        attempt=$((attempt + 1))
    done
    
    log_error "应用在 ${TIMEOUT} 秒内未启动"
    return 1
}

# 运行健康检查
test_health() {
    log_info "运行健康检查..."
    
    local response=$(curl -s -w "\n%{http_code}" "${APP_URL}/health")
    local body=$(echo "$response" | head -n 1)
    local status_code=$(echo "$response" | tail -n 1)
    
    if [ "$status_code" -eq 200 ]; then
        local status=$(echo "$body" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        if [ "$status" = "healthy" ]; then
            log_info "健康检查通过"
            echo "$body" | python3 -m json.tool
            return 0
        else
            log_error "应用状态异常: $status"
            return 1
        fi
    else
        log_error "健康检查失败，状态码: $status_code"
        return 1
    fi
}

# 测试数学运算
test_math_operations() {
    log_info "测试数学运算..."
    
    local tests=(
        "add/2&3"
        "subtract/5&2"
        "multiply/4&3"
        "divide/10&2"
    )
    
    local expected_results=(
        '{"result":5.0,"success":true}'
        '{"result":3.0,"success":true}'
        '{"result":12.0,"success":true}'
        '{"result":5.0,"success":true}'
    )
    
    local passed=0
    local total=${#tests[@]}
    
    for i in "${!tests[@]}"; do
        local endpoint="${tests[$i]}"
        local expected="${expected_results[$i]}"
        
        log_info "测试 $endpoint..."
        
        local response=$(curl -s "${APP_URL}/${endpoint}")
        
        # 检查成功字段
        if echo "$response" | grep -q '"success":true'; then
            log_info "✓ $endpoint 成功"
            passed=$((passed + 1))
        else
            log_error "✗ $endpoint 失败: $response"
        fi
        
        # 格式化输出
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
        echo
    done
    
    if [ $passed -eq $total ]; then
        log_info "所有数学运算测试通过 ($passed/$total)"
        return 0
    else
        log_error "数学运算测试失败: $passed/$total 通过"
        return 1
    fi
}

# 测试错误处理
test_error_handling() {
    log_info "测试错误处理..."
    
    local error_tests=(
        "add/abc&123"
        "divide/10&0"
        "nonexistent/endpoint"
    )
    
    for endpoint in "${error_tests[@]}"; do
        log_info "测试错误情况: $endpoint"
        
        local response=$(curl -s -w "\n%{http_code}" "${APP_URL}/${endpoint}")
        local body=$(echo "$response" | head -n 1)
        local status_code=$(echo "$response" | tail -n 1)
        
        if [ "$status_code" -ge 400 ]; then
            log_info "✓ 错误处理正确 (状态码: $status_code)"
            echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
        else
            log_error "✗ 预期错误但得到状态码: $status_code"
        fi
        echo
    done
}

# 测试性能
test_performance() {
    log_info "测试性能..."
    
    local start_time=$(date +%s%N)
    
    # 运行 10 次请求
    for i in {1..10}; do
        curl -s "${APP_URL}/add/${i}&${i}" > /dev/null
    done
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # 毫秒
    
    log_info "10 次请求耗时: ${duration}ms"
    
    if [ $duration -lt 5000 ]; then  # 5秒内完成
        log_info "性能测试通过"
        return 0
    else
        log_warn "性能较慢: ${duration}ms"
        return 1
    fi
}

# 生成测试报告
generate_report() {
    local total_tests=4
    local passed_tests=0
    
    echo "========================================"
    echo "         功能测试报告"
    echo "========================================"
    echo "应用地址: $APP_URL"
    echo "测试时间: $(date)"
    echo ""
    
    # 运行所有测试
    if wait_for_app; then passed_tests=$((passed_tests + 1)); fi
    if test_health; then passed_tests=$((passed_tests + 1)); fi
    if test_math_operations; then passed_tests=$((passed_tests + 1)); fi
    if test_error_handling; then passed_tests=$((passed_tests + 1)); fi
    test_performance  # 性能测试不影响总体结果
    
    echo ""
    echo "========================================"
    echo "测试结果: $passed_tests/$total_tests 通过"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_info "所有功能测试通过！"
        return 0
    else
        log_error "功能测试失败"
        return 1
    fi
}

# 主函数
main() {
    echo "Web 计算器功能测试"
    echo "=================="
    echo "目标URL: $APP_URL"
    echo ""
    
    generate_report
    
    if [ $? -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main
