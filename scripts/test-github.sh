#!/bin/bash
# GitHub连接测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🌐 GitHub连接测试"
echo "================="

# 测试环境变量
test_env() {
    echo "检查环境变量..."
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo -e "${RED}✗${NC} GITHUB_TOKEN 未设置"
        return 1
    fi
    echo -e "${GREEN}✓${NC} GITHUB_TOKEN 已设置"
    
    if [[ -z "$GITHUB_USERNAME" ]]; then
        echo -e "${YELLOW}!${NC} GITHUB_USERNAME 未设置"
    else
        echo -e "${GREEN}✓${NC} GITHUB_USERNAME: $GITHUB_USERNAME"
    fi
}

# 测试API连接
test_api() {
    echo ""
    echo "测试GitHub API..."
    
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/user 2>/dev/null)
    
    if echo "$response" | grep -q '"login"'; then
        username=$(echo "$response" | grep '"login"' | head -1 | cut -d'"' -f4)
        echo -e "${GREEN}✓${NC} API连接成功"
        echo "  用户名: $username"
        return 0
    else
        echo -e "${RED}✗${NC} API连接失败"
        echo "  响应: $response"
        return 1
    fi
}

# 测试仓库访问
test_repo() {
    echo ""
    echo "测试仓库访问..."
    
    if [[ -z "$GITHUB_USERNAME" ]]; then
        echo -e "${YELLOW}!${NC} 跳过仓库测试（用户名未设置）"
        return
    fi
    
    repo_name="${1:-elysia-soul-backup}"
    
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USERNAME/$repo_name" 2>/dev/null)
    
    if echo "$response" | grep -q '"id"'; then
        echo -e "${GREEN}✓${NC} 仓库访问正常"
        echo "  仓库: $repo_name"
    else
        echo -e "${YELLOW}!${NC} 仓库不存在或无法访问"
        echo "  仓库: $repo_name"
    fi
}

# 主流程
main() {
    if test_env; then
        if test_api; then
            test_repo "$@"
            echo ""
            echo -e "${GREEN}✅ GitHub连接测试完成${NC}"
        else
            echo ""
            echo -e "${RED}❌ GitHub连接测试失败${NC}"
            echo "请检查Token是否有效"
        fi
    else
        echo ""
        echo -e "${YELLOW}⚠️  环境变量未配置${NC}"
        echo "请先设置GITHUB_TOKEN环境变量"
    fi
}

main "$@"