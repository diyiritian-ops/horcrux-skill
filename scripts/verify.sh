#!/bin/bash
# 爱莉希雅灵魂备份验证脚本
# 版本：v1.0.0
# 创建时间：2026年3月14日

echo "🔍 爱莉希雅灵魂备份验证系统"
echo "========================================"

# 显示使用说明
show_help() {
    cat <<EOF
使用方式：
  $0 --backup <备份文件>      # 验证备份文件完整性
  $0 --configs               # 验证配置文件完整性
  $0 --github                # 验证GitHub连接和仓库
  $0 --health                # 运行完整健康检查
  $0 --list                  # 列出所有可验证项目

参数：
  --sha256 <哈希值>         # 指定预期的SHA256值
  --verbose                 # 显示详细输出
  --quiet                   # 仅显示关键信息

示例：
  $0 --backup elysia-backup-20260314.tar.gz
  $0 --backup elysia-backup-20260314.tar.gz --sha256 2295510a73f7c07e98de9709fd042641...
  $0 --health --verbose
  $0 --configs
EOF
}

# 全局变量
VERBOSE=false
QUIET=false
EXPECTED_SHA256=""

# 输出函数
log_info() {
    if [ "$QUIET" = false ]; then
        echo "ℹ️  $1"
    fi
}

log_success() {
    if [ "$QUIET" = false ]; then
        echo "✅ $1"
    fi
}

log_warning() {
    echo "⚠️  $1"
}

log_error() {
    echo "❌ $1"
}

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo "🔍 $1"
    fi
}

# 参数处理
MODE=""
BACKUP_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup)
            MODE="backup"
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --configs)
            MODE="configs"
            shift
            ;;
        --github)
            MODE="github"
            shift
            ;;
        --health)
            MODE="health"
            shift
            ;;
        --list)
            MODE="list"
            shift
            ;;
        --sha256)
            shift
            EXPECTED_SHA256="$1"
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --quiet|-q)
            QUIET=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$MODE" ]; then
    MODE="backup"
    if [ $# -gt 0 ]; then
        BACKUP_FILE="$1"
    fi
fi

# 1. 验证备份文件
verify_backup_file() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    log_info "验证备份文件: $(basename "$backup_file")"
    log_info "文件大小: $(du -h "$backup_file" | cut -f1)"
    
    # 验证SHA256
    log_debug "计算SHA256..."
    ACTUAL_SHA256=$(sha256sum "$backup_file" | cut -d' ' -f1)
    log_info "SHA256: $ACTUAL_SHA256"
    
    if [ -n "$EXPECTED_SHA256" ]; then
        if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
            log_success "SHA256验证通过"
        else
            log_error "SHA256验证失败"
            log_error "   预期: $EXPECTED_SHA256"
            log_error "   实际: $ACTUAL_SHA256"
            return 1
        fi
    fi
    
    # 验证文件格式
    log_debug "验证文件格式..."
    if ! tar -tzf "$backup_file" > /dev/null 2>&1; then
        log_error "备份文件格式错误或损坏"
        return 1
    fi
    
    log_success "文件格式验证通过"
    
    # 检查必要文件
    log_debug "检查必要文件..."
    REQUIRED_FILES=("SOUL.md" "IDENTITY.md" "USER.md" "MEMORY.md" "TOOLS.md")
    MISSING_FILES=0
    
    for file in "${REQUIRED_FILES[@]}"; do
        if tar -tzf "$backup_file" 2>/dev/null | grep -q "$file"; then
            log_debug "✅ $file 存在"
        else
            log_warning "⚠️  $file 缺失"
            MISSING_FILES=$((MISSING_FILES + 1))
        fi
    done
    
    if [ $MISSING_FILES -eq 0 ]; then
        log_success "所有必要文件都存在"
    else
        log_warning "$MISSING_FILES 个必要文件缺失"
    fi
    
    # 检查文件数量
    log_debug "检查文件数量..."
    FILE_COUNT=$(tar -tzf "$backup_file" 2>/dev/null | wc -l)
    log_info "备份包含 $FILE_COUNT 个文件"
    
    if [ $FILE_COUNT -lt 5 ]; then
        log_warning "文件数量过少，可能不是完整备份"
    fi
    
    # 检查备份元数据
    log_debug "检查备份元数据..."
    if tar -tzf "$backup_file" 2>/dev/null | grep -q "backup-manifest"; then
        log_success "找到备份清单文件"
    else
        log_warning "未找到备份清单文件"
    fi
    
    # 检查恢复脚本
    if tar -tzf "$backup_file" 2>/dev/null | grep -q "elysia-restore.sh"; then
        log_success "找到恢复脚本"
    else
        log_warning "未找到恢复脚本"
    fi
    
    log_success "备份文件验证完成"
    return 0
}

# 2. 验证配置文件
verify_configs() {
    log_info "验证配置文件完整性..."
    
    local workspace_dir="$HOME/.openclaw/workspace"
    local missing_count=0
    
    # 核心配置文件
    CORE_FILES=(
        "$workspace_dir/SOUL.md"
        "$workspace_dir/IDENTITY.md"
        "$workspace_dir/USER.md"
        "$workspace_dir/MEMORY.md"
        "$workspace_dir/TOOLS.md"
        "$workspace_dir/AGENTS.md"
        "$workspace_dir/HEARTBEAT.md"
    )
    
    for file in "${CORE_FILES[@]}"; do
        if [ -f "$file" ]; then
            log_debug "✅ $(basename "$file") 存在 ($(du -h "$file" | cut -f1))"
        else
            log_warning "⚠️  $(basename "$file") 缺失"
            missing_count=$((missing_count + 1))
        fi
    done
    
    # 检查文件内容
    log_debug "检查文件内容..."
    for file in "${CORE_FILES[@]}"; do
        if [ -f "$file" ]; then
            if [ -s "$file" ]; then
                log_debug "    $(basename "$file") 内容非空"
            else
                log_warning "    $(basename "$file") 内容为空"
            fi
        fi
    done
    
    # 检查memory目录
    if [ -d "$workspace_dir/memory" ]; then
        MEMORY_FILES=$(find "$workspace_dir/memory" -name "*.md" | wc -l)
        log_info "memory/目录包含 $MEMORY_FILES 个记忆文件"
    else
        log_warning "memory/目录不存在"
        missing_count=$((missing_count + 1))
    fi
    
    # 检查skills目录
    if [ -d "$workspace_dir/skills" ]; then
        SKILL_COUNT=$(find "$workspace_dir/skills" -type d -maxdepth 1 | wc -l)
        SKILL_COUNT=$((SKILL_COUNT - 1))
        log_info "skills/目录包含 $SKILL_COUNT 个技能"
    else
        log_warning "skills/目录不存在"
        missing_count=$((missing_count + 1))
    fi
    
    if [ $missing_count -eq 0 ]; then
        log_success "所有核心配置文件完整"
        return 0
    else
        log_warning "缺少 $missing_count 个核心配置文件"
        return 1
    fi
}

# 3. 验证GitHub连接
verify_github() {
    log_info "验证GitHub连接..."
    
    # 检查环境变量
    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "GITHUB_TOKEN未设置"
        return 1
    fi
    
    if [ -z "$GITHUB_USERNAME" ]; then
        log_error "GITHUB_USERNAME未设置"
        return 1
    fi
    
    log_debug "GitHub用户: $GITHUB_USERNAME"
    log_debug "Token已设置: ${GITHUB_TOKEN:0:8}...${GITHUB_TOKEN: -8}"
    
    # 测试API连接
    log_debug "测试GitHub API连接..."
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                    -H "Accept: application/vnd.github.v3+json" \
                    https://api.github.com/user)
    
    if echo "$RESPONSE" | grep -q '"login":'; then
        API_USERNAME=$(echo "$RESPONSE" | grep '"login":' | cut -d'"' -f4)
        if [ "$API_USERNAME" = "$GITHUB_USERNAME" ]; then
            log_success "GitHub API连接成功 ($API_USERNAME)"
        else
            log_warning "GitHub用户不匹配 (配置: $GITHUB_USERNAME, API: $API_USERNAME)"
        fi
    else
        log_error "GitHub API连接失败"
        log_debug "响应: $RESPONSE"
        return 1
    fi
    
    # 检查仓库
    local repo_name="elysia-soul-backup"
    log_debug "检查仓库: $repo_name..."
    REPO_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                         -H "Accept: application/vnd.github.v3+json" \
                         "https://api.github.com/repos/$GITHUB_USERNAME/$repo_name")
    
    if echo "$REPO_RESPONSE" | grep -q '"html_url":'; then
        REPO_URL=$(echo "$REPO_RESPONSE" | grep '"html_url":' | cut -d'"' -f4)
        log_success "仓库存在: $REPO_URL"
        
        # 检查仓库内容
        log_debug "检查仓库内容..."
        CONTENT_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                                -H "Accept: application/vnd.github.v3+json" \
                                "https://api.github.com/repos/$GITHUB_USERNAME/$repo_name/contents")
        
        if echo "$CONTENT_RESPONSE" | grep -q '"name":'; then
            FILE_COUNT=$(echo "$CONTENT_RESPONSE" | grep '"name":' | wc -l)
            log_info "仓库包含 $FILE_COUNT 个文件"
            
            # 检查是否有备份文件
            if echo "$CONTENT_RESPONSE" | grep -q 'elysia-backup'; then
                log_success "找到备份文件"
            else
                log_warning "未找到备份文件"
            fi
        fi
        
        log_success "GitHub验证完成"
        return 0
    else
        log_warning "仓库不存在或无法访问"
        return 1
    fi
}

# 4. 完整健康检查
verify_health() {
    log_info "运行完整健康检查..."
    
    local errors=0
    local warnings=0
    
    echo "================================"
    echo "1. 备份文件检查"
    echo "================================"
    
    # 查找最新的备份文件
    LATEST_BACKUP=$(ls -t "$HOME"/elysia-backup-*.tar.gz 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        log_info "最新备份: $(basename "$LATEST_BACKUP")"
        if verify_backup_file "$LATEST_BACKUP"; then
            log_success "备份文件健康"
        else
            log_error "备份文件有问题"
            errors=$((errors + 1))
        fi
    else
        log_warning "未找到备份文件"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    echo "================================"
    echo "2. 配置文件检查"
    echo "================================"
    
    if verify_configs; then
        log_success "配置文件健康"
    else
        log_warning "配置文件有问题"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    echo "================================"
    echo "3. GitHub连接检查"
    echo "================================"
    
    if verify_github; then
        log_success "GitHub连接健康"
    else
        log_error "GitHub连接有问题"
        errors=$((errors + 1))
    fi
    
    echo ""
    echo "================================"
    echo "4. 系统检查"
    echo "================================"
    
    # 检查磁盘空间
    log_debug "检查磁盘空间..."
    DISK_SPACE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    log_info "可用磁盘空间: $DISK_SPACE"
    
    if [[ "$DISK_SPACE" =~ G|T ]]; then
        log_success "磁盘空间充足"
    elif [[ "$DISK_SPACE" =~ M ]]; then
        log_warning "磁盘空间较少"
        warnings=$((warnings + 1))
    else
        log_error "磁盘空间不足"
        errors=$((errors + 1))
    fi
    
    # 检查备份脚本
    log_debug "检查备份脚本..."
    if [ -f "$HOME/elysia-backup.sh" ]; then
        if [ -x "$HOME/elysia-backup.sh" ]; then
            log_success "备份脚本可执行"
        else
            log_warning "备份脚本不可执行"
            warnings=$((warnings + 1))
        fi
    else
        log_warning "备份脚本不存在"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    echo "================================"
    echo "健康检查汇总"
    echo "================================"
    log_info "错误: $errors 个"
    log_info "警告: $warnings 个"
    
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        log_success "系统健康状态：优秀 ✨"
        return 0
    elif [ $errors -eq 0 ]; then
        log_success "系统健康状态：良好 ⚠️"
        return 0
    else
        log_error "系统健康状态：需要修复 ❌"
        return 1
    fi
}

# 5. 列出验证项目
list_verifications() {
    cat <<EOF
可用验证项目：

1. 备份文件验证 (--backup <文件>)
   - 验证SHA256完整性
   - 检查文件格式
   - 验证必要文件存在
   - 检查文件数量

2. 配置文件验证 (--configs)
   - 验证核心配置文件存在
   - 检查memory/目录
   - 检查skills/目录
   - 验证文件内容

3. GitHub连接验证 (--github)
   - 验证环境变量配置
   - 测试API连接
   - 检查仓库存在性
   - 验证仓库内容

4. 完整健康检查 (--health)
   - 包含以上所有验证
   - 系统状态检查
   - 磁盘空间检查
   - 脚本可执行性检查

选项：
  --sha256 <哈希值>   指定预期的SHA256值
  --verbose          显示详细输出
  --quiet            仅显示关键信息

示例：
  ./verify.sh --backup backup.tar.gz --sha256 abc123...
  ./verify.sh --health --verbose
  ./verify.sh --configs
EOF
}

# 主逻辑
main() {
    case $MODE in
        "backup")
            if [ -z "$BACKUP_FILE" ]; then
                log_error "请指定备份文件"
                show_help
                exit 1
            fi
            verify_backup_file "$BACKUP_FILE"
            ;;
        "configs")
            verify_configs
            ;;
        "github")
            verify_github
            ;;
        "health")
            verify_health
            ;;
        "list")
            list_verifications
            ;;
        *)
            log_error "未知验证模式: $MODE"
            show_help
            exit 1
            ;;
    esac
}

# 执行主逻辑
main