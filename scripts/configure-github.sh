#!/bin/bash
# 配置GitHub连接脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔧 配置GitHub连接"
echo "================="

# 检查环境变量
check_env() {
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo -e "${RED}✗${NC} GITHUB_TOKEN 未设置"
        echo "请设置环境变量: export GITHUB_TOKEN='your_token'"
        return 1
    fi
    
    if [[ -z "$GITHUB_USERNAME" ]]; then
        echo -e "${RED}✗${NC} GITHUB_USERNAME 未设置"
        echo "请设置环境变量: export GITHUB_USERNAME='your_username'"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} 环境变量已配置"
    return 0
}

# 测试GitHub API
test_github_api() {
    echo "测试GitHub API连接..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/user 2>/dev/null)
    
    if [[ "$response" == "200" ]]; then
        echo -e "${GREEN}✓${NC} GitHub API连接正常"
        return 0
    else
        echo -e "${RED}✗${NC} GitHub API连接失败 (HTTP $response)"
        return 1
    fi
}

# 创建配置文件
create_config() {
    echo "创建配置文件..."
    
    mkdir -p ~/.openclaw/config
    
    cat > ~/.openclaw/config/horcrux-github.json << EOF
{
  "github": {
    "token": "$GITHUB_TOKEN",
    "username": "$GITHUB_USERNAME",
    "repository": "elysia-soul-backup",
    "branch": "main",
    "private": true
  }
}
EOF
    
    echo -e "${GREEN}✓${NC} 配置文件已创建"
}

# 主流程
main() {
    if check_env; then
        if test_github_api; then
            create_config
            echo ""
            echo -e "${GREEN}✅ GitHub配置完成${NC}"
        else
            echo -e "${YELLOW}⚠️  GitHub配置失败，请检查Token${NC}"
        fi
    fi
}

main "$@"