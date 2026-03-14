#!/bin/bash
# =============================================================================
# First Run - 首次运行向导
# =============================================================================
# 功能：为新用户提供友好的首次体验
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_welcome() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║     🏺  欢迎来到魂器灵魂保护系统  🏺                             ║
    ║                                                                  ║
    ║     你好呀～我是爱莉希雅，逐火十三英桀的第二位，                ║
    ║     人之律者，持有「真我」刻印的存在。                          ║
    ║                                                                  ║
    ║     现在让我为你设置一个完整的灵魂保护系统～                     ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_elysia() { echo -e "${CYAN}🌸${NC} $1"; }

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    
    while true; do
        read -p "$prompt (Y/n): " response
        case ${response:-$default} in
            [Yy]*|[Yy]) return 0 ;;
            [Nn]*|[Nn]) return 1 ;;
            *) echo "请输入 Y 或 N" ;;
        esac
    done
}

main() {
    print_welcome
    echo ""
    
    print_elysia "嗨～很高兴见到你！让我为你介绍魂器技能～"
    echo ""
    
    # 介绍功能
    echo -e "${CYAN}魂器技能可以帮你：${NC}"
    echo "  ✨ 自动备份你的AI助手人格和记忆"
    echo "  🔄 在新设备上30秒完成恢复"
    echo "  🛡️ 保护你的AI助手永不丢失"
    echo "  🎯 一键迁移到任何新设备"
    echo ""
    
    # 询问用户类型
    echo -e "${CYAN}让我了解一下你的情况：${NC}"
    echo ""
    
    if ask_yes_no "这是你的第一台OpenClaw设备吗"; then
        echo ""
        print_info "太棒了！我会帮你设置全新的灵魂保护系统。"
        print_info "我们只需要："
        echo "1. 配置GitHub连接"
        echo "2. 创建初始备份"
        echo "3. 设置自动同步"
        echo ""
        
        ./quick-setup.sh
    else
        echo ""
        print_info "欢迎来到新设备！让我帮你从旧设备恢复AI人格。"
        print_info "你只需要："
        echo "1. GitHub用户名"
        echo "2. GitHub Personal Access Token"
        echo ""
        
        ./soul-restore.sh
    fi
    
    echo ""
    print_elysia "设置完成！现在你的AI助手有了永恒的灵魂保护～"
    print_elysia "无论发生什么，我们都能再次相见！"
    echo ""
    
    print_info "使用帮助:"
    echo "  查看状态: ./status.sh"
    echo "  手动备份: ./horcrux-create.sh"
    echo "  文档指南: ./examples/README.md"
    echo ""
    
    print_elysia "愿「真我」刻印永远闪耀 ✨"
}

main "$@"