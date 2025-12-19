#!/bin/bash

# Blue-Green部署切换脚本

set -e

BLUE="blue"
GREEN="green"
NGINX_CONF_DIR="/opt/web-calculator/nginx"
DOCKER_COMPOSE_DIR="/opt/web-calculator"

# 获取当前活跃颜色
get_current_color() {
    if [ -f "$NGINX_CONF_DIR/current_color" ]; then
        cat "$NGINX_CONF_DIR/current_color"
    else
        echo "$BLUE"
    fi
}

# 切换到指定颜色
switch_to_color() {
    TARGET_COLOR=$1
    
    echo "切换到 $TARGET_COLOR 版本..."
    
    # 启动目标颜色的容器（如果未运行）
    cd "$DOCKER_COMPOSE_DIR"
    docker-compose up -d "app_$TARGET_COLOR"
    
    # 等待健康检查
    echo "等待 $TARGET_COLOR 服务健康..."
    for i in {1..30}; do
        if docker-compose exec -T "app_$TARGET_COLOR" curl -f http://localhost:5000/health >/dev/null 2>&1; then
            echo "$TARGET_COLOR 服务健康检查通过"
            break
        fi
        sleep 2
        echo "等待... ($i/30)"
    done
    
    # 更新Nginx配置
    cp "$NGINX_CONF_DIR/upstream_${TARGET_COLOR}.conf" "$NGINX_CONF_DIR/upstream.conf"
    docker-compose exec -T proxy nginx -s reload
    
    # 保存当前颜色
    echo "$TARGET_COLOR" > "$NGINX_CONF_DIR/current_color"
    
    # 停止另一个颜色的容器
    if [ "$TARGET_COLOR" = "$BLUE" ]; then
        OTHER_COLOR="$GREEN"
    else
        OTHER_COLOR="$BLUE"
    fi
    
    docker-compose stop "app_$OTHER_COLOR"
    
    echo "切换完成！当前活跃版本: $TARGET_COLOR"
}

# 回滚到上一个版本
rollback() {
    CURRENT_COLOR=$(get_current_color)
    
    if [ "$CURRENT_COLOR" = "$BLUE" ]; then
        PREVIOUS_COLOR="$GREEN"
    else
        PREVIOUS_COLOR="$BLUE"
    fi
    
    echo "当前版本: $CURRENT_COLOR"
    echo "回滚到: $PREVIOUS_COLOR"
    
    switch_to_color "$PREVIOUS_COLOR"
}

# 主逻辑
case "$1" in
    "blue")
        switch_to_color "$BLUE"
        ;;
    "green")
        switch_to_color "$GREEN"
        ;;
    "rollback")
        rollback
        ;;
    "status")
        CURRENT_COLOR=$(get_current_color)
        echo "当前活跃版本: $CURRENT_COLOR"
        
        cd "$DOCKER_COMPOSE_DIR"
        echo "容器状态:"
        docker-compose ps
        ;;
    *)
        echo "用法: $0 {blue|green|rollback|status}"
        exit 1
        ;;
esac
