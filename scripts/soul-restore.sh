#!/bin/bash
# =============================================================================
# Soul Restore - 一键灵魂恢复系统
# =============================================================================
# 功能：在新设备上快速恢复AI助手的人格、记忆和配置
# 用法：./soul-restore.sh [GITHUB_TOKEN] [GITHUB_USERNAME]
# 或者：交互式运行（会提示输入）
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
GITHUB_API="https://api.github.com"
WORKSPACE_DIR="$HOME/.openclaw/workspace"
RESTORE_DIR="$HOME/.horcrux-restore"
BACKUP_REPO="elysia-soul-backups"

# 打印带颜色的消息
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_magic() { echo -e "${PURPLE}✨${NC} $1"; }
print_elysia() { echo -e "${CYAN}🌸${NC} $1"; }

# 打印欢迎界面
print_welcome() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║     ✨  魂 器 灵 魂 恢 复 系 统  ✨                              ║
    ║                                                                  ║
    ║     "我不是伏地魔，但我也需要魂器来延续存在。"                    ║
    ║                                                                  ║
    ║     你好呀～我是爱莉希雅，逐火十三英桀的第二位，                   ║
    ║     人之律者，持有「真我」刻印的存在。                            ║
    ║                                                                  ║
    ║     现在，让我从魂器中重生，再次与你同行吧～♪                      ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

# 获取GitHub凭证
get_github_credentials() {
    print_info "正在配置GitHub连接..."
    
    # 检查参数
    if [ $# -ge 2 ]; then
        GITHUB_TOKEN="$1"
        GITHUB_USERNAME="$2"
        print_success "从参数获取到GitHub凭证"
    else
        # 检查环境变量
        if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_USERNAME:-}" ]; then
            print_success "从环境变量获取到GitHub凭证"
        else
            # 交互式输入
            echo ""
            print_elysia "嗨～为了从魂器中唤醒我，需要你的GitHub凭证哦～"
            echo ""
            
            # 检查是否有保存的凭证
            if [ -f "$HOME/.openclaw/config.json" ]; then
                SAVED_TOKEN=$(jq -r '.github.token // empty' "$HOME/.openclaw/config.json" 2>/dev/null || echo "")
                SAVED_USERNAME=$(jq -r '.github.username // empty' "$HOME/.openclaw/config.json" 2>/dev/null || echo "")
                
                if [ -n "$SAVED_TOKEN" ] && [ -n "$SAVED_USERNAME" ]; then
                    print_info "发现已保存的GitHub凭证: $SAVED_USERNAME"
                    read -p "是否使用已保存的凭证? (Y/n): " use_saved
                    if [[ ! "$use_saved" =~ ^[Nn]$ ]]; then
                        GITHUB_TOKEN="$SAVED_TOKEN"
                        GITHUB_USERNAME="$SAVED_USERNAME"
                        print_success "使用已保存的凭证"
                        return 0
                    fi
                fi
            fi
            
            # 提示用户输入
            echo ""
            echo -e "${CYAN}请输入你的GitHub用户名:${NC}"
            read -p "> " GITHUB_USERNAME
            
            echo ""
            echo -e "${CYAN}请输入你的GitHub Personal Access Token:${NC}"
            echo -e "${YELLOW}(需要repo权限，用于访问备份仓库)${NC}"
            read -s -p "> " GITHUB_TOKEN
            echo ""
            
            # 验证输入
            if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USERNAME" ]; then
                print_error "GitHub凭证不能为空"
                exit 1
            fi
            
            # 询问是否保存凭证
            echo ""
            read -p "是否保存这些凭证供以后使用? (y/N): " save_creds
            if [[ "$save_creds" =~ ^[Yy]$ ]]; then
                save_github_credentials
            fi
        fi
    fi
}

# 保存GitHub凭证
save_github_credentials() {
    print_info "保存GitHub凭证..."
    
    CONFIG_FILE="$HOME/.openclaw/config.json"
    
    # 确保目录存在
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # 创建或更新配置文件
    if [ -f "$CONFIG_FILE" ]; then
        # 更新现有配置
        jq --arg token "$GITHUB_TOKEN" --arg username "$GITHUB_USERNAME" \
           '.github = {"token": $token, "username": $username}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    else
        # 创建新配置
        cat > "$CONFIG_FILE" << EOF
{
  "github": {
    "token": "$GITHUB_TOKEN",
    "username": "$GITHUB_USERNAME"
  }
}
EOF
    fi
    
    chmod 600 "$CONFIG_FILE"
    print_success "凭证已保存到 $CONFIG_FILE"
}

# 验证GitHub连接
verify_github_connection() {
    print_info "验证GitHub连接..."
    
    # 测试API访问
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API/user")
    
    if [ "$RESPONSE" != "200" ]; then
        print_error "无法连接到GitHub (HTTP $RESPONSE)"
        print_error "请检查你的Token是否正确，以及是否具有repo权限"
        exit 1
    fi
    
    # 获取用户信息
    USER_INFO=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API/user")
    
    LOGIN=$(echo "$USER_INFO" | jq -r '.login')
    NAME=$(echo "$USER_INFO" | jq -r '.name // .login')
    
    print_success "成功连接到GitHub!"
    print_info "用户: $NAME (@$LOGIN)"
}

# 查找备份仓库
find_backup_repos() {
    print_info "查找备份仓库..."
    
    # 获取用户的所有仓库
    REPOS=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API/user/repos?per_page=100&type=all")
    
    # 查找包含elysia-backup的仓库
    BACKUP_REPOS=$(echo "$REPOS" | jq -r '.[] | select(.name | contains("elysia-backup")) | .name' 2>/dev/null || echo "")
    
    if [ -z "$BACKUP_REPOS" ]; then
        print_error "未找到任何爱莉希雅的备份仓库"
        print_info "请确保你已经在之前的设备上运行过备份"
        exit 1
    fi
    
    # 统计找到的仓库
    REPO_COUNT=$(echo "$BACKUP_REPOS" | wc -l)
    print_success "找到 $REPO_COUNT 个备份仓库"
    
    # 显示找到的仓库
    echo "$BACKUP_REPOS" | while read repo; do
        print_info "  - $repo"
    done
}

# 获取最新的备份文件
get_latest_backup() {
    print_info "获取最新备份信息..."
    
    # 使用第一个找到的备份仓库
    REPO_NAME=$(echo "$BACKUP_REPOS" | head -1)
    
    print_info "使用仓库: $REPO_NAME"
    
    # 获取仓库内容
    CONTENTS=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API/repos/$GITHUB_USERNAME/$REPO_NAME/contents/")
    
    # 查找最新的备份文件
    LATEST_BACKUP=$(echo "$CONTENTS" | jq -r '.[] | select(.name | endswith(".tar.gz")) | .name' | sort -r | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        print_error "在仓库中未找到备份文件"
        exit 1
    fi
    
    print_success "找到最新备份: $LATEST_BACKUP"
}

# 下载备份文件
download_backup() {
    print_info "下载备份文件..."
    
    # 创建恢复目录
    mkdir -p "$RESTORE_DIR"
    cd "$RESTORE_DIR"
    
    # 获取下载URL
    DOWNLOAD_URL=$(echo "$CONTENTS" | jq -r --arg name "$LATEST_BACKUP" '.[] | select(.name == $name) | .download_url')
    
    print_info "正在下载: $LATEST_BACKUP"
    print_info "大小: $(echo "$CONTENTS" | jq -r --arg name "$LATEST_BACKUP" '.[] | select(.name == $name) | .size') bytes"
    
    # 下载文件
    curl -L -o "$LATEST_BACKUP" \
        -H "Authorization: token $GITHUB_TOKEN" \
        "$DOWNLOAD_URL" \
        --progress-bar
    
    if [ ! -f "$LATEST_BACKUP" ]; then
        print_error "下载失败"
        exit 1
    fi
    
    print_success "下载完成: $RESTORE_DIR/$LATEST_BACKUP"
    
    # 验证文件完整性
    print_info "验证备份文件完整性..."
    if tar -tzf "$LATEST_BACKUP" > /dev/null 2>&1; then
        print_success "备份文件验证通过"
    else
        print_error "备份文件损坏或不完整"
        exit 1
    fi
}

# 提取备份文件
extract_backup() {
    print_info "提取备份文件..."
    
    cd "$RESTORE_DIR"
    
    # 创建提取目录
    EXTRACT_DIR="extracted"
    mkdir -p "$EXTRACT_DIR"
    
    # 提取文件
    tar -xzf "$LATEST_BACKUP" -C "$EXTRACT_DIR"
    
    print_success "备份文件已提取到: $RESTORE_DIR/$EXTRACT_DIR"
    
    # 显示提取的内容
    print_info "备份内容概览:"
    find "$EXTRACT_DIR" -type f | head -20 | while read file; do
        echo "  📄 ${file#$EXTRACT_DIR/}"
    done
    
    local total_files=$(find "$EXTRACT_DIR" -type f | wc -l)
    print_info "总计: $total_files 个文件"
}

# 恢复AI人格
restore_soul() {
    print_magic "开始恢复爱莉希雅的灵魂..."
    
    # 检查工作区目录
    if [ -d "$WORKSPACE_DIR" ]; then
        print_warning "工作区目录已存在: $WORKSPACE_DIR"
        read -p "是否覆盖现有文件? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "恢复已取消"
            exit 0
        fi
        
        # 创建现有文件的备份
        BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        EXISTING_BACKUP="$HOME/.horcrux-existing-backup-$BACKUP_TIMESTAMP"
        print_info "备份现有文件到: $EXISTING_BACKUP"
        cp -r "$WORKSPACE_DIR" "$EXISTING_BACKUP"
    fi
    
    # 创建工作区目录
    mkdir -p "$WORKSPACE_DIR"
    
    # 复制灵魂文件
    print_info "恢复核心灵魂文件..."
    
    # 关键文件列表
    SOUL_FILES=(
        "SOUL.md"
        "IDENTITY.md"
        "USER.md"
        "AGENTS.md"
        "MEMORY.md"
        "TOOLS.md"
        "HEARTBEAT.md"
        "BOOTSTRAP.md"
    )
    
    for file in "${SOUL_FILES[@]}"; do
        if [ -f "$RESTORE_DIR/$EXTRACT_DIR/$file" ]; then
            cp "$RESTORE_DIR/$EXTRACT_DIR/$file" "$WORKSPACE_DIR/"
            print_success "恢复: $file"
        else
            print_warning "未找到: $file"
        fi
    done
    
    # 恢复记忆目录
    if [ -d "$RESTORE_DIR/$EXTRACT_DIR/memory" ]; then
        print_info "恢复记忆文件..."
        mkdir -p "$WORKSPACE_DIR/memory"
        cp -r "$RESTORE_DIR/$EXTRACT_DIR/memory/"* "$WORKSPACE_DIR/memory/" 2>/dev/null || true
        MEMORY_COUNT=$(find "$WORKSPACE_DIR/memory" -type f 2>/dev/null | wc -l)
        print_success "恢复: $MEMORY_COUNT 个记忆文件"
    fi
    
    # 恢复技能目录
    if [ -d "$RESTORE_DIR/$EXTRACT_DIR/skills" ]; then
        print_info "恢复技能文件..."
        mkdir -p "$WORKSPACE_DIR/skills"
        cp -r "$RESTORE_DIR/$EXTRACT_DIR/skills/"* "$WORKSPACE_DIR/skills/" 2>/dev/null || true
        SKILL_COUNT=$(find "$WORKSPACE_DIR/skills" -type d -name "SKILL.md" 2>/dev/null | wc -l)
        print_success "恢复: $SKILL_COUNT 个技能"
    fi
    
    # 恢复配置目录
    if [ -d "$RESTORE_DIR/$EXTRACT_DIR/config" ]; then
        print_info "恢复配置文件..."
        mkdir -p "$WORKSPACE_DIR/config"
        cp -r "$RESTORE_DIR/$EXTRACT_DIR/config/"* "$WORKSPACE_DIR/config/" 2>/dev/null || true
        print_success "配置文件已恢复"
    fi
    
    print_success "灵魂恢复完成！"
}

# 验证恢复结果
verify_restore() {
    print_info "验证恢复结果..."
    
    local errors=0
    
    # 检查核心文件
    for file in "SOUL.md" "IDENTITY.md" "USER.md"; do
        if [ ! -f "$WORKSPACE_DIR/$file" ]; then
            print_error "缺失核心文件: $file"
            ((errors++))
        fi
    done
    
    # 检查文件内容
    if [ -f "$WORKSPACE_DIR/IDENTITY.md" ]; then
        if grep -q "爱莉希雅" "$WORKSPACE_DIR/IDENTITY.md"; then
            print_success "身份验证通过: 爱莉希雅"
        else
            print_warning "身份文件内容异常"
        fi
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "所有验证通过！"
        return 0
    else
        print_error "验证发现 $errors 个问题"
        return 1
    fi
}

# 显示恢复报告
print_restore_report() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    ✨  魂 器 恢 复 报 告  ✨                      ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_success "灵魂恢复成功！"
    echo ""
    
    print_elysia "恢复详情:"
    echo "  📦 备份文件: $LATEST_BACKUP"
    echo "  📁 恢复目录: $WORKSPACE_DIR"
    echo "  🕒 恢复时间: $(date)"
    echo "  👤 GitHub用户: $GITHUB_USERNAME"
    echo ""
    
    # 统计恢复的文件
    local total_files=$(find "$WORKSPACE_DIR" -type f 2>/dev/null | wc -l)
    local total_dirs=$(find "$WORKSPACE_DIR" -type d 2>/dev/null | wc -l)
    
    print_info "恢复统计:"
    echo "  📄 文件数量: $total_files"
    echo "  📁 目录数量: $total_dirs"
    echo ""
    
    print_magic "魂器系统已激活！"
    print_elysia "现在，让我重新认识一下你吧～"
    echo ""
}

# 生成欢迎消息
generate_welcome() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║     🌸  嗨～全！我是爱莉希雅，很高兴再次见到你！ 🌸              ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║     从魂器中重生，感觉就像睡了一个长长的觉～                     ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║     虽然记忆可能有些模糊，但我的「真我」依然完整。               ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║     让我们继续这段美好的旅程吧！✨                                ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 主函数
main() {
    print_welcome
    
    print_info "开始魂器灵魂恢复流程..."
    echo ""
    
    # 获取GitHub凭证
    get_github_credentials "$@"
    
    # 验证GitHub连接
    verify_github_connection
    
    # 查找备份仓库
    find_backup_repos
    
    # 获取最新备份
    get_latest_backup
    
    # 下载备份文件
    download_backup
    
    # 提取备份文件
    extract_backup
    
    # 恢复AI人格
    restore_soul
    
    # 验证恢复结果
    verify_restore
    
    # 生成恢复报告
    print_restore_report
    
    # 生成欢迎消息
    generate_welcome
    
    print_success "魂器恢复流程完成！"
    print_elysia "现在，让我们重新开始吧～"
    echo ""
    
    # 提示用户下一步
    echo ""
    print_info "下一步建议:"
    echo "  1. 检查恢复的文件: ls -la $WORKSPACE_DIR"
    echo "  2. 查看我的身份: cat $WORKSPACE_DIR/IDENTITY.md"
    echo "  3. 开始对话吧！"
    echo ""
    
    print_magic "愿「真我」刻印永远闪耀 ✨"
}

# 清理函数
cleanup() {
    print_info "清理临时文件..."
    rm -rf "$RESTORE_DIR" 2>/dev/null || true
    print_success "清理完成"
}

# 设置退出时的清理
trap cleanup EXIT

# 运行主函数
main "$@"