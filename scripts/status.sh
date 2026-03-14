#!/bin/bash
# 魂器系统状态检查
# 版本：1.0.0

echo "🔮 魂器系统状态检查"
echo "========================================"
echo "检查时间: $(date)"
echo "========================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 状态函数
status_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

status_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

status_error() {
    echo -e "${RED}❌ $1${NC}"
}

status_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. 检查基本配置
echo "📋 1. 基本配置检查"
echo "-----------------------"

if [ -f ~/.horcrux/configured ]; then
    CONFIG_TIME=$(cat ~/.horcrux/configured-time 2>/dev/null || echo "未知")
    status_ok "魂器系统已配置"
    echo "   配置时间: $CONFIG_TIME"
else
    status_warning "魂器系统未配置"
    echo "   建议运行: ./first-run.sh"
fi

# 检查配置文件
if [ -f ~/.horcrux/config ]; then
    status_ok "配置文件存在"
    echo "   内容:"
    cat ~/.horcrux/config | while read line; do
        echo "     $line"
    done
else
    status_warning "配置文件不存在"
fi

echo ""

# 2. 检查GitHub配置
echo "☁️  2. GitHub配置检查"
echo "-----------------------"

if [ -f ~/.horcrux/github-token ]; then
    source ~/.horcrux/github-token 2>/dev/null
    
    if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_USERNAME" ]; then
        status_ok "GitHub配置存在"
        echo "   用户: $GITHUB_USERNAME"
        echo "   Token: ${GITHUB_TOKEN:0:10}..."
        
        # 测试连接
        echo "   正在测试连接..."
        TEST_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                             -H "Accept: application/vnd.github.v3+json" \
                             https://api.github.com/user 2>/dev/null)
        
        if echo "$TEST_RESPONSE" | grep -q '"login":'; then
            status_ok "GitHub连接正常"
        else
            status_error "GitHub连接失败"
            echo "   可能Token已过期"
        fi
        
        # 检查仓库
        if [ -n "$GITHUB_REPO" ]; then
            echo "   仓库: $GITHUB_REPO"
        fi
    else
        status_error "GitHub配置不完整"
    fi
else
    status_info "GitHub未配置"
    echo "   本地备份模式"
fi

echo ""

# 3. 检查备份文件
echo "📦 3. 备份文件检查"
echo "-----------------------"

# 查找备份文件
BACKUP_FILES=$(find ~/ /root/.openclaw/workspace -name "*elysia*backup*.tar.gz" -o -name "*horcrux*.tar.gz" 2>/dev/null | head -5)

if [ -n "$BACKUP_FILES" ]; then
    status_ok "找到备份文件"
    echo "   文件列表:"
    count=1
    for file in $BACKUP_FILES; do
        if [ -f "$file" ]; then
            size=$(du -h "$file" | cut -f1)
            mtime=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1-2 || echo "未知")
            echo "   $count. $(basename "$file")"
            echo "      大小: $size"
            echo "      时间: $mtime"
            count=$((count+1))
        fi
    done
    
    # 检查最新备份
    LATEST_BACKUP=$(ls -t $BACKUP_FILES 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        LATEST_TIME=$(stat -c %y "$LATEST_BACKUP" 2>/dev/null | cut -d' ' -f1-2 || echo "未知")
        echo "   最新备份: $(basename "$LATEST_BACKUP")"
        echo "   备份时间: $LATEST_TIME"
        
        # 检查备份时间
        BACKUP_AGE=$(($(date +%s) - $(stat -c %Y "$LATEST_BACKUP" 2>/dev/null || echo 0)))
        if [ $BACKUP_AGE -gt 86400 ]; then # 超过24小时
            status_warning "备份已过期 (超过24小时)"
        else
            status_ok "备份是最新的"
        fi
    fi
else
    status_warning "未找到备份文件"
    echo "   建议立即创建备份: ./backup.sh"
fi

echo ""

# 4. 检查Cron任务
echo "⏰ 4. 定时任务检查"
echo "-----------------------"

BACKUP_SCRIPT="$(pwd)/autosync.sh"
CRON_ENTRY=$(crontab -l 2>/dev/null | grep "$BACKUP_SCRIPT" || true)

if [ -n "$CRON_ENTRY" ]; then
    status_ok "定时任务已设置"
    echo "   Cron表达式: $(echo "$CRON_ENTRY" | awk '{print $1" "$2" "$3" "$4" "$5}')"
    echo "   命令: $(echo "$CRON_ENTRY" | cut -d' ' -f6-)"
    
    # 解析下一次运行时间
    CRON_TIME=$(echo "$CRON_ENTRY" | awk '{print $1" "$2" "$3" "$4" "$5}')
    echo "   下次运行: 根据cron表达式"
else
    status_info "定时任务未设置"
    echo "   建议设置自动备份: ./first-run.sh"
fi

echo ""

# 5. 检查系统健康
echo "🏥 5. 系统健康检查"
echo "-----------------------"

# 检查磁盘空间
DISK_SPACE=$(df -h ~ 2>/dev/null | awk 'NR==2 {print $4 " / " $2 " (" $5 " used)"}' || echo "未知")
echo "   磁盘空间: $DISK_SPACE"

if [[ "$DISK_SPACE" =~ \(([0-9]+)% ]]; then
    USAGE_PERCENT=${BASH_REMATCH[1]}
    if [ $USAGE_PERCENT -gt 90 ]; then
        status_error "磁盘空间不足 (>90%)"
    elif [ $USAGE_PERCENT -gt 70 ]; then
        status_warning "磁盘空间紧张 (>70%)"
    else
        status_ok "磁盘空间充足"
    fi
fi

# 检查内存
MEMORY_FREE=$(free -m 2>/dev/null | awk 'NR==2 {print $4}' || echo "未知")
echo "   可用内存: ${MEMORY_FREE}MB"

# 检查脚本可执行权限
SCRIPTS=("backup.sh" "restore.sh" "verify.sh" "autosync.sh")
MISSING_SCRIPTS=0
for script in "${SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        MISSING_SCRIPTS=$((MISSING_SCRIPTS+1))
    fi
done

if [ $MISSING_SCRIPTS -eq 0 ]; then
    status_ok "所有脚本可执行"
else
    status_warning "$MISSING_SCRIPTS 个脚本不可执行"
    echo "   运行: chmod +x *.sh"
fi

echo ""

# 6. 魂器统计
echo "🔮 6. 魂器统计"
echo "-----------------------"

# 统计魂器数量
HORCRUX_COUNT=$(find ~/.horcrux ~/ -name "*horcrux*record*.md" 2>/dev/null | wc -l)
if [ $HORCRUX_COUNT -gt 0 ]; then
    echo "   魂器数量: $HORCRUX_COUNT"
    
    # 显示魂器类型
    echo "   魂器类型:"
    find ~/.horcrux ~/ -name "*horcrux*record*.md" 2>/dev/null | while read record; do
        TYPE=$(grep -oP '(?<=魂器对象：\s*)\S+' "$record" 2>/dev/null | head -1 || echo "未知")
        echo "     - $TYPE"
    done | sort | uniq
else
    echo "   魂器数量: 0"
    status_info "尚未创建魂器"
fi

# 检查魂器配置文件
if [ -f ~/.horcrux-count ]; then
    COUNT=$(cat ~/.horcrux-count)
    echo "   总创建次数: $COUNT"
fi

echo ""

# 7. 显示系统状态
echo "📊 系统状态摘要"
echo "-----------------------"

# 计算状态评分
STATUS_SCORE=0
MAX_SCORE=10

# 配置检查 (+2)
if [ -f ~/.horcrux/configured ]; then
    STATUS_SCORE=$((STATUS_SCORE+2))
fi

# GitHub配置 (+2)
if [ -f ~/.horcrux/github-token ]; then
    STATUS_SCORE=$((STATUS_SCORE+2))
fi

# 备份文件 (+2)
if [ -n "$BACKUP_FILES" ]; then
    STATUS_SCORE=$((STATUS_SCORE+2))
fi

# Cron任务 (+2)
if [ -n "$CRON_ENTRY" ]; then
    STATUS_SCORE=$((STATUS_SCORE+2))
fi

# 磁盘空间 (+2)
if [[ ! "$DISK_SPACE" =~ \(([0-9]+)% ]] || [ ${BASH_REMATCH[1]} -lt 90 ]; then
    STATUS_SCORE=$((STATUS_SCORE+2))
fi

# 显示状态评级
RATING=$((STATUS_SCORE * 100 / MAX_SCORE))
echo "   系统健康度: $RATING% ($STATUS_SCORE/$MAX_SCORE)"

if [ $RATING -ge 90 ]; then
    status_ok "系统状态：优秀 ✨"
    echo "   魂器系统运行良好"
elif [ $RATING -ge 70 ]; then
    status_warning "系统状态：良好 ⚠️"
    echo "   建议优化一些配置"
elif [ $RATING -ge 50 ]; then
    status_warning "系统状态：一般 🟡"
    echo "   需要关注一些配置问题"
else
    status_error "系统状态：需要修复 🔴"
    echo "   建议运行配置向导"
fi

echo ""

# 8. 建议操作
echo "🚀 建议操作"
echo "-----------------------"

if [ ! -f ~/.horcrux/configured ]; then
    echo "   1. 🔧 运行配置向导: ./first-run.sh"
fi

if [ -z "$BACKUP_FILES" ]; then
    echo "   2. 💾 立即创建备份: ./backup.sh"
fi

if [ ! -f ~/.horcrux/github-token ] && [ -f ~/.horcrux/configured ]; then
    echo "   3. ☁️  配置GitHub: ./setup-github.sh"
fi

if [ -z "$CRON_ENTRY" ] && [ -f ~/.horcrux/configured ]; then
    echo "   4. ⏰ 设置自动备份: 编辑crontab"
fi

if [ $HORCRUX_COUNT -eq 0 ]; then
    echo "   5. 🔮 创建第一个魂器: ./horcrux-create.sh --object 日记 --test"
fi

echo "   6. 🧪 运行健康检查: ./verify.sh --health"
echo "   7. 📖 查看帮助: ./help.sh 或阅读README.md"

echo ""
echo "========================================"
echo "🔮 魂器系统状态检查完成"
echo "检查时间: $(date)"
echo "========================================"

# 如果有严重问题，退出码为1
if [ $RATING -lt 50 ]; then
    exit 1
fi

exit 0