#!/bin/bash
# Blue-Green 部署脚本
# 版本: 2.0

set -euo pipefail

# 配置
readonly DEPLOY_DIR="/opt/web-calculator"
readonly REGISTRY="ghcr.io"
readonly IMAGE_NAME="your-username/web-calculator"
readonly TIMEOUT=60
readonly RETRY_INTERVAL=5

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# 错误处理
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command=$2
    
    log_error "部署失败！"
    log_error "退出代码: $exit_code"
    log_error "错误位置: 第 $line_number 行"
    log_error "失败命令: $command"
    
    # 尝试回滚
    if [ -f "${DEPLOY_DIR}/.current_color" ]; then
        local current_color=$(cat "${DEPLOY_DIR}/.current_color")
        log_info "尝试自动回滚到 $current_color 环境..."
        "${DEPLOY_DIR}/docker/scripts/rollback.sh" "$current_color"
    fi
    
    exit $exit_code
}

# 设置错误捕获
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

# 参数检查
if [ $# -lt 1 ]; then
    log_error "使用方法: $0 <新版本标签> [部署颜色]"
    log_error "例如: $0 v1.0.0-abc1234 green"
    exit 1
fi

readonly NEW_VERSION="$1"
readonly DEPLOY_COLOR="${2:-}"  # 可选，自动检测时为空

cd "$DEPLOY_DIR" || {
    log_error "无法进入部署目录: $DEPLOY_DIR"
    exit 1
}

# 1. 验证 Docker 环境
validate_docker() {
    log_info "验证 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "无法连接到 Docker 守护进程"
        exit 1
    fi
    
    log_info "Docker 版本: $(docker --version)"
    log_info "Docker Compose 版本: $(docker-compose --version 2>/dev/null || echo '未安装')"
}

# 2. 拉取新镜像
pull_new_image() {
    log_info "拉取新镜像: $REGISTRY/$IMAGE_NAME:$NEW_VERSION"
    
    local retries=3
    local count=0
    
    while [ $count -lt $retries ]; do
        if docker pull "$REGISTRY/$IMAGE_NAME:$NEW_VERSION"; then
            log_info "镜像拉取成功"
            return 0
        fi
        
        count=$((count + 1))
        log_warn "镜像拉取失败，重试 $count/$retries..."
        sleep 5
    done
    
    log_error "镜像拉取失败，达到最大重试次数"
    return 1
}

# 3. 检测当前活跃环境
detect_current_environment() {
    log_info "检测当前活跃环境..."
    
    # 检查 blue 环境
    local blue_healthy=false
    local green_healthy=false
    
    if docker ps --format '{{.Names}}' | grep -q "webcalc-blue"; then
        local blue_status=$(docker inspect --format='{{.State.Health.Status}}' webcalc-blue 2>/dev/null || echo "unknown")
        if [ "$blue_status" = "healthy" ]; then
            blue_healthy=true
        fi
    fi
    
    # 检查 green 环境
    if docker ps --format '{{.Names}}' | grep -q "webcalc-green"; then
        local green_status=$(docker inspect --format='{{.State.Health.Status}}' webcalc-green 2>/dev/null || echo "unknown")
        if [ "$green_status" = "healthy" ]; then
            green_healthy=true
        fi
    fi
    
    # 确定当前活跃环境
    if [ -n "$DEPLOY_COLOR" ]; then
        CURRENT=""
        NEXT="$DEPLOY_COLOR"
        log_info "使用指定的部署环境: $NEXT"
    elif $blue_healthy && ! $green_healthy; then
        CURRENT="blue"
        NEXT="green"
        log_info "检测到 blue 环境活跃，将部署到 green"
    elif $green_healthy && ! $blue_healthy; then
        CURRENT="green"
        NEXT="blue"
        log_info "检测到 green 环境活跃，将部署到 blue"
    elif ! $blue_healthy && ! $green_healthy; then
        log_warn "没有检测到健康环境，将部署到 blue"
        CURRENT=""
        NEXT="blue"
    else
        # 两个环境都健康，检查 Nginx 配置
        if grep -q "server app_blue:5001" docker/nginx/upstream.conf; then
            CURRENT="blue"
            NEXT="green"
            log_info "Nginx 配置显示 blue 活跃，将部署到 green"
        elif grep -q "server app_green:5002" docker/nginx/upstream.conf; then
            CURRENT="green"
            NEXT="blue"
            log_info "Nginx 配置显示 green 活跃，将部署到 blue"
        else
            CURRENT="blue"
            NEXT="green"
            log_info "无法确定活跃环境，默认部署到 green"
        fi
    fi
    
    # 设置端口
    if [ "$NEXT" = "blue" ]; then
        NEXT_PORT=5001
        CURRENT_PORT=5002
    else
        NEXT_PORT=5002
        CURRENT_PORT=5001
    fi
    
    log_debug "CURRENT: $CURRENT, NEXT: $NEXT"
    log_debug "NEXT_PORT: $NEXT_PORT, CURRENT_PORT: $CURRENT_PORT"
}

# 4. 停止旧环境容器
stop_old_environment() {
    log_info "停止 $NEXT 环境容器..."
    
    if docker ps --format '{{.Names}}' | grep -q "webcalc-$NEXT"; then
        log_info "停止 webcalc-$NEXT 容器..."
        docker stop "webcalc-$NEXT" || true
        
        log_info "删除 webcalc-$NEXT 容器..."
        docker rm "webcalc-$NEXT" || true
    else
        log_info "webcalc-$NEXT 容器不存在，无需停止"
    fi
}

# 5. 启动新环境
start_new_environment() {
    log_info "启动 $NEXT 环境..."
    
    # 创建环境变量文件
    cat > .env."$NEXT" << EOF
FLASK_ENV=production
PORT=$NEXT_PORT
APP_VERSION=$NEW_VERSION
DEPLOYMENT_COLOR=$NEXT
EOF
    
    # 启动容器
    docker run -d \
        --name "webcalc-$NEXT" \
        --network webcalc_webcalc-network \
        --env-file ".env.$NEXT" \
        --health-cmd="curl -f http://localhost:$NEXT_PORT/health || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        --health-start-period=40s \
        --log-opt max-size=10m \
        --log-opt max-file=3 \
        --restart unless-stopped \
        "$REGISTRY/$IMAGE_NAME:$NEW_VERSION"
    
    log_info "容器 webcalc-$NEXT 已启动"
}

# 6. 等待健康检查
wait_for_health() {
    log_info "等待 $NEXT 环境健康检查..."
    
    local max_attempts=$((TIMEOUT / RETRY_INTERVAL))
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "webcalc-$NEXT" 2>/dev/null || echo "checking")
        
        case "$health_status" in
            "healthy")
                log_info "$NEXT 环境健康检查通过"
                return 0
                ;;
            "unhealthy")
                log_error "$NEXT 环境健康检查失败"
                return 1
                ;;
            *)
                log_info "等待 $NEXT 环境就绪 ($attempt/$max_attempts)..."
                sleep $RETRY_INTERVAL
                attempt=$((attempt + 1))
                ;;
        esac
    done
    
    log_error "$NEXT 环境在 ${TIMEOUT} 秒内未达到健康状态"
    return 1
}

# 7. 测试新环境
test_new_environment() {
    log_info "测试 $NEXT 环境..."
    
    local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "webcalc-$NEXT")
    local test_url="http://$container_ip:$NEXT_PORT"
    
    log_debug "测试 URL: $test_url"
    
    # 测试健康端点
    if curl -s --max-time 10 --fail "$test_url/health" > /dev/null; then
        log_info "健康端点测试通过"
    else
        log_error "健康端点测试失败"
        return 1
    fi
    
    # 测试计算功能
    if curl -s --max-time 10 "$test_url/add/2&3" | grep -q '"success":true'; then
        log_info "计算功能测试通过"
    else
        log_error "计算功能测试失败"
        return 1
    fi
    
    log_info "所有测试通过"
    return 0
}

# 8. 更新 Nginx 配置
update_nginx_config() {
    log_info "更新 Nginx 配置，切换流量到 $NEXT 环境..."
    
    # 备份当前配置
    cp docker/nginx/upstream.conf docker/nginx/upstream.conf.backup.$(date +%Y%m%d%H%M%S)
    
    # 生成新配置
    if [ "$NEXT" = "blue" ]; then
        cat > docker/nginx/upstream.conf << EOF
upstream webcalc_upstream {
    server app_blue:5001 max_fails=3 fail_timeout=30s;
    server app_green:5002 backup;
    least_conn;
    keepalive 32;
    keepalive_timeout 60s;
    keepalive_requests 100;
}
EOF
    else
        cat > docker/nginx/upstream.conf << EOF
upstream webcalc_upstream {
    server app_green:5002 max_fails=3 fail_timeout=30s;
    server app_blue:5001 backup;
    least_conn;
    keepalive 32;
    keepalive_timeout 60s;
    keepalive_requests 100;
}
EOF
    fi
    
    log_info "Nginx 配置已更新"
    
    # 重新加载 Nginx
    log_info "重新加载 Nginx..."
    if docker exec webcalc-nginx nginx -s reload; then
        log_info "Nginx 重新加载成功"
    else
        log_error "Nginx 重新加载失败"
        # 尝试重启 Nginx
        log_info "尝试重启 Nginx..."
        docker restart webcalc-nginx
        sleep 5
    fi
    
    # 保存当前活跃颜色
    echo "$NEXT" > .current_color
}

# 9. 验证流量切换
verify_traffic_switch() {
    log_info "验证流量切换..."
    
    # 等待一段时间让切换生效
    sleep 10
    
    # 测试外部访问
    local external_test_url="http://localhost"
    local retries=5
    local count=0
    
    while [ $count -lt $retries ]; do
        if curl -s --max-time 5 "$external_test_url/version" | grep -q "\"deployment_color\":\"$NEXT\""; then
            log_info "流量已成功切换到 $NEXT 环境"
            return 0
        fi
        
        count=$((count + 1))
        log_warn "流量切换验证失败，重试 $count/$retries..."
        sleep 2
    done
    
    log_error "流量切换验证失败"
    return 1
}

# 10. 清理旧环境（可选）
cleanup_old_environment() {
    if [ -n "$CURRENT" ]; then
        log_info "清理旧 $CURRENT 环境容器..."
        
        # 停止旧容器
        docker stop "webcalc-$CURRENT" 2>/dev/null || true
        
        # 删除旧容器
        docker rm "webcalc-$CURRENT" 2>/dev/null || true
        
        log_info "旧 $CURRENT 环境已清理"
    fi
    
    # 清理旧镜像
    log_info "清理旧 Docker 镜像..."
    docker image prune -a --filter "until=48h" --force 2>/dev/null || true
    
    # 清理临时文件
    rm -f .env.blue .env.green
}

# 11. 生成部署报告
generate_deployment_report() {
    local report_file="deployment_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
部署报告
========
部署时间: $(date)
部署版本: $NEW_VERSION
目标环境: $NEXT
原环境: ${CURRENT:-none}

容器状态:
$(docker ps -a --filter "name=webcalc" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

镜像信息:
$(docker images "$REGISTRY/$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}")

Nginx 配置:
$(cat docker/nginx/upstream.conf)

健康状态:
$(docker inspect --format='{{.Name}} - {{.State.Health.Status}}' webcalc-blue webcalc-green 2>/dev/null || echo "无法获取健康状态")

部署结果: 成功
EOF
    
    log_info "部署报告已生成: $report_file"
}

# 主部署流程
main() {
    log_info "开始 Blue-Green 部署..."
    log_info "新版本: $NEW_VERSION"
    log_info "部署目录: $DEPLOY_DIR"
    
    # 验证环境
    validate_docker
    
    # 拉取镜像
    pull_new_image
    
    # 检测环境
    detect_current_environment
    
    # 停止旧环境
    stop_old_environment
    
    # 启动新环境
    start_new_environment
    
    # 等待健康检查
    if ! wait_for_health; then
        log_error "新环境健康检查失败，开始回滚..."
        "${DEPLOY_DIR}/docker/scripts/rollback.sh" "${CURRENT:-blue}"
        exit 1
    fi
    
    # 测试新环境
    if ! test_new_environment; then
        log_error "新环境功能测试失败，开始回滚..."
        "${DEPLOY_DIR}/docker/scripts/rollback.sh" "${CURRENT:-blue}"
        exit 1
    fi
    
    # 更新 Nginx 配置
    update_nginx_config
    
    # 验证流量切换
    if ! verify_traffic_switch; then
        log_warn "流量切换验证失败，但部署继续..."
    fi
    
    # 清理旧环境
    cleanup_old_environment
    
    # 生成报告
    generate_deployment_report
    
    log_info "Blue-Green 部署完成！"
    log_info "当前活跃环境: $NEXT"
    log_info "应用版本: $NEW_VERSION"
    log_info "访问地址: http://localhost"
}

# 运行主函数
main "$@"