#!/bin/bash
# 魂器技能状态检查脚本
# 验证整个魂器系统的完整性

echo "⚡ 霍格沃茨魂器系统状态检查"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_file() {
    if [[ -f "$1" ]]; then
        echo -e "${GREEN}✓${NC} $2 存在"
        return 0
    else
        echo -e "${RED}✗${NC} $2 缺失"
        return 1
    fi
}

check_directory() {
    if [[ -d "$1" ]]; then
        echo -e "${GREEN}✓${NC} $2 目录存在"
        return 0
    else
        echo -e "${YELLOW}!${NC} $2 目录不存在（将自动创建）"
        mkdir -p "$1"
        return 0
    fi
}

check_script() {
    if [[ -x "$1" ]]; then
        echo -e "${GREEN}✓${NC} $2 可执行"
        return 0
    else
        echo -e "${RED}✗${NC} $2 不可执行"
        chmod +x "$1"
        return 1
    fi
}

# 总体状态
overall_status=0

echo "📁 文件结构检查"
echo "----------------"
check_file "/root/.openclaw/workspace/skills/horcrux/SKILL.md" "SKILL.md" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/_meta.json" "_meta.json" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/README.md" "README.md" || overall_status=1

echo ""
echo "📐 目录结构检查"
echo "----------------"
check_directory "/root/.openclaw/workspace/skills/horcrux/config" "config" || overall_status=1
check_directory "/root/.openclaw/workspace/skills/horcrux/examples" "examples" || overall_status=1
check_directory "/root/.openclaw/workspace/skills/horcrux/references" "references" || overall_status=1
check_directory "/root/.openclaw/workspace/skills/horcrux/scripts" "scripts" || overall_status=1

echo ""
echo "⚙️ 配置文件检查"
echo "----------------"
check_file "/root/.openclaw/workspace/skills/horcrux/config/github-config.json" "github-config.json" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/config/backup-config.json" "backup-config.json" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/config/sync-config.json" "sync-config.json" || overall_status=1

echo ""
echo "📚 参考文档检查"
echo "----------------"
check_file "/root/.openclaw/workspace/skills/horcrux/references/soul-protection.md" "soul-protection.md" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/references/best-practices.md" "best-practices.md" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/references/troubleshooting.md" "troubleshooting.md" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/references/github-backup-guide.md" "github-backup-guide.md" || overall_status=1

echo ""
echo "💡 示例文件检查"
echo "----------------"
check_file "/root/.openclaw/workspace/skills/horcrux/examples/config-examples.md" "config-examples.md" || overall_status=1
check_file "/root/.openclaw/workspace/skills/horcrux/examples/usage-examples.md" "usage-examples.md" || overall_status=1

echo ""
echo "🛠️ 脚本检查"
echo "----------------"
for script in /root/.openclaw/workspace/skills/horcrux/scripts/*.sh; do
    if [[ -f "$script" ]]; then
        script_name=$(basename "$script")
        check_script "$script" "$script_name" || overall_status=1
    fi
done

echo ""
echo "📊 系统依赖检查"
echo "----------------"

# 检查必要的命令
commands=("tar" "curl" "git" "sha256sum" "crontab")
for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd 可用"
    else
        echo -e "${RED}✗${NC} $cmd 缺失"
        overall_status=1
    fi
done

echo ""
echo "🌐 GitHub API 测试"
echo "----------------"
if [[ -n "$GITHUB_TOKEN" ]]; then
    echo -e "${GREEN}✓${NC} GitHub Token 已配置"
    # 测试API连接
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user 2>/dev/null)
    if [[ "$response" == "200" ]]; then
        echo -e "${GREEN}✓${NC} GitHub API 连接正常"
    else
        echo -e "${RED}✗${NC} GitHub API 连接失败 (HTTP $response)"
        overall_status=1
    fi
else
    echo -e "${YELLOW}!${NC} GitHub Token 未配置（可选）"
fi

echo ""
echo "🕰️ 定时任务检查"
echo "----------------"
if crontab -l 2>/dev/null | grep -q "horcrux"; then
    echo -e "${GREEN}✓${NC} 魂器定时任务已配置"
else
    echo -e "${YELLOW}!${NC} 魂器定时任务未配置（可选）"
fi

echo ""
echo "=================================="
if [[ $overall_status -eq 0 ]]; then
    echo -e "${GREEN}🎉 魂器系统状态良好！所有检查通过${NC}"
    echo "你的灵魂得到了完美的保护！✨"
else
    echo -e "${YELLOW}⚠️  魂器系统存在一些问题需要修复${NC}"
    echo "建议查看上面的错误信息并进行修复"
fi
echo "=================================="

exit $overall_status