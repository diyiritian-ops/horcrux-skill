#!/bin/bash
# 系统健康检查脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🏥 魂器系统健康检查"
echo "=================="

# 健康度计数
health_score=0
max_score=10

# 检查GitHub连接
check_github() {
    echo "检查GitHub连接..."
    if [[ -n "$GITHUB_TOKEN" ]]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: token $GITHUB_TOKEN" \
            https://api.github.com/user 2>/dev/null)
        if [[ "$response" == "200" ]]; then
            echo -e "${GREEN}✓${NC} GitHub连接正常"
            ((health_score++))
        else
            echo -e "${RED}✗${NC} GitHub连接失败"
        fi
    else
        echo -e "${YELLOW}!${NC} GitHub Token未配置"
    fi
}

# 检查备份目录
check_backup_dir() {
    echo "检查备份目录..."
    if [[ -d ~/.openclaw/backups ]]; then
        echo -e "${GREEN}✓${NC} 备份目录存在"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 备份目录不存在"
        mkdir -p ~/.openclaw/backups
    fi
}

# 检查日志目录
check_log_dir() {
    echo "检查日志目录..."
    if [[ -d ~/.openclaw/logs ]]; then
        echo -e "${GREEN}✓${NC} 日志目录存在"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 日志目录不存在"
        mkdir -p ~/.openclaw/logs
    fi
}

# 检查定时任务
check_cron() {
    echo "检查定时任务..."
    # 检查传统cron
    if command -v crontab >/dev/null 2>&1 && crontab -l 2>/dev/null | grep -q "horcrux"; then
        echo -e "${GREEN}✓${NC} 传统定时任务已配置"
        ((health_score++))
    # 检查OpenClaw cron
    elif [ -f "/root/.openclaw/workspace/skills/horcrux/config/cron-alternative.json" ]; then
        echo -e "${GREEN}✓${NC} OpenClaw定时任务已配置"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 定时任务未配置"
    fi
}

# 检查配置文件
check_config() {
    echo "检查配置文件..."
    if [[ -f ~/.openclaw/config/github-config.json ]] || [[ -f /root/.openclaw/workspace/skills/horcrux/config/github-config.json ]]; then
        echo -e "${GREEN}✓${NC} GitHub配置存在"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} GitHub配置不存在"
    fi
}

# 检查备份文件
check_backups() {
    echo "检查备份文件..."
    backup_count=$(ls ~/.openclaw/backups/*.tar.gz 2>/dev/null | wc -l)
    if [[ $backup_count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} 找到 $backup_count 个备份文件"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 未找到备份文件"
    fi
}

# 检查脚本完整性
check_scripts() {
    echo "检查脚本完整性..."
    script_count=$(ls /root/.openclaw/workspace/skills/horcrux/scripts/*.sh 2>/dev/null | wc -l)
    if [[ $script_count -ge 10 ]]; then
        echo -e "${GREEN}✓${NC} 脚本完整 ($script_count 个)"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 脚本不完整 ($script_count 个)"
    fi
}

# 检查文档完整性
check_docs() {
    echo "检查文档完整性..."
    if [[ -f /root/.openclaw/workspace/skills/horcrux/SKILL.md ]]; then
        echo -e "${GREEN}✓${NC} 文档完整"
        ((health_score++))
    else
        echo -e "${RED}✗${NC} 文档缺失"
    fi
}

# 检查存储空间
check_storage() {
    echo "检查存储空间..."
    available=$(df ~/.openclaw | tail -1 | awk '{print $4}')
    if [[ $available -gt 1048576 ]]; then  # 1GB
        echo -e "${GREEN}✓${NC} 存储空间充足"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 存储空间不足"
    fi
}

# 检查网络连接
check_network() {
    echo "检查网络连接..."
    if curl -s -I https://github.com | head -1 | grep -q "200\|302"; then
        echo -e "${GREEN}✓${NC} 网络连接正常"
        ((health_score++))
    else
        echo -e "${YELLOW}!${NC} 网络连接异常"
    fi
}

# 主流程
main() {
    check_github
    check_backup_dir
    check_log_dir
    check_cron
    check_config
    check_backups
    check_scripts
    check_docs
    check_storage
    check_network
    
    echo ""
    echo "=================="
    echo "健康度: $health_score/$max_score"
    
    if [[ $health_score -eq $max_score ]]; then
        echo -e "${GREEN}🎉 系统状态：完美${NC}"
    elif [[ $health_score -ge 7 ]]; then
        echo -e "${GREEN}✅ 系统状态：良好${NC}"
    elif [[ $health_score -ge 4 ]]; then
        echo -e "${YELLOW}⚠️  系统状态：需要修复${NC}"
    else
        echo -e "${RED}❌ 系统状态：严重问题${NC}"
    fi
    echo "=================="
}

main "$@"