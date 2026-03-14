#!/bin/bash
# 配置自动同步脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔄 配置自动同步"
echo "==============="

# 检查参数
FREQUENCY="${1:-hourly}"

# 创建日志目录
mkdir -p ~/.openclaw/logs

# 配置定时任务
setup_cron() {
    echo "设置定时任务..."
    
    case "$FREQUENCY" in
        "hourly")
            cron_schedule="0 * * * *"
            ;;
        "daily")
            cron_schedule="0 0 * * *"
            ;;
        "weekly")
            cron_schedule="0 0 * * 0"
            ;;
        *)
            cron_schedule="0 * * * *"
            ;;
    esac
    
    # 移除旧的定时任务
    crontab -l 2>/dev/null | grep -v "horcrux" | crontab - 2>/dev/null || true
    
    # 添加新的定时任务
    (crontab -l 2>/dev/null; echo "$cron_schedule cd /root/.openclaw/workspace/skills/horcrux && ./scripts/autosync.sh >> ~/.openclaw/logs/autosync.log 2>&1") | crontab -
    
    echo -e "${GREEN}✓${NC} 定时任务已设置 ($FREQUENCY)"
}

# 测试自动同步
test_autosync() {
    echo "测试自动同步..."
    if ./scripts/autosync.sh --test; then
        echo -e "${GREEN}✓${NC} 自动同步测试通过"
    else
        echo -e "${YELLOW}!${NC} 自动同步测试失败，请检查配置"
    fi
}

# 主流程
main() {
    setup_cron
    test_autosync
    
    echo ""
    echo -e "${GREEN}✅ 自动同步配置完成${NC}"
    echo "频率: $FREQUENCY"
    echo "日志: ~/.openclaw/logs/autosync.log"
}

main "$@"