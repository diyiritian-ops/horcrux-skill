#!/bin/bash
# =============================================================================
# Quick Setup - 快速设置向导
# =============================================================================
# 功能：为新用户提供快速设置体验
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║     ✨  魂 器 技 能 快 速 设 置  ✨                              ║
    ║                                                                  ║
    ║     让我为你设置完整的灵魂保护系统～                             ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_magic() { echo -e "${PURPLE}✨${NC} $1"; }

main() {
    print_header
    echo ""
    
    print_info "开始快速设置魂器技能..."
    echo ""
    
    # 检查依赖
    print_info "检查系统依赖..."
    
    MISSING_DEPS=()
    
    if ! command -v curl > /dev/null 2>&1; then
        MISSING_DEPS+=("curl")
    fi
    
    if ! command -v jq > /dev/null 2>&1; then
        MISSING_DEPS+=("jq")
    fi
    
    if ! command -v tar > /dev/null 2>&1; then
        MISSING_DEPS+=("tar")
    fi
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        print_error "缺少依赖: ${MISSING_DEPS[*]}"
        print_info "请安装缺失的依赖后重试"
        exit 1
    fi
    
    print_success "所有依赖已满足"
    
    # 配置GitHub
    print_info "配置GitHub连接..."
    ./configure-github.sh
    
    # 创建初始备份
    print_info "创建初始魂器..."
    ./horcrux-create.sh
    
    # 设置自动同步
    print_info "设置自动同步..."
    ./configure-autosync.sh
    
    # 运行健康检查
    print_info "运行系统健康检查..."
    ./healthcheck.sh
    
    echo ""
    print_success "快速设置完成！"
    print_magic "你的灵魂保护系统已激活～"
    echo ""
    
    print_info "下一步建议:"
    echo "  1. 查看备份状态: ./status.sh"
    echo "  2. 验证备份完整性: ./verify.sh"
    echo "  3. 设置定时任务: crontab -e"
    echo ""
    
    print_magic "愿你的灵魂永远安全 ✨"
}

main "$@"