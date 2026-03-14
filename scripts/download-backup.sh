#!/bin/bash

# 下载备份文件脚本
# 用于从GitHub下载指定的备份文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
    exit 1
}

# 显示帮助
show_help() {
    cat << EOF
使用: ./download-backup.sh [选项] <备份ID>

选项:
  -h, --help              显示此帮助信息
  -d, --destination PATH  下载目标目录（默认：当前目录）
  -f, --force             强制覆盖已存在的文件
  -v, --verbose           显示详细输出
  --github-user USER      GitHub用户名（默认从环境变量读取）
  --github-token TOKEN    GitHub Token（默认从环境变量读取）
  --repo REPO             GitHub仓库名（默认：elysia-soul-backup）
  --branch BRANCH         GitHub分支名（默认：backups）

备份ID:
  可以是：
  - 完整的备份文件名（如：elysia-backup-20260314-074730-v2.1.tar.gz）
  - 备份ID编号（如：latest 或 specific-id）
  - 日期模式（如：20260314 或 2026-03-14）

示例:
  ./download-backup.sh latest
  ./download-backup.sh elysia-backup-20260314-074730-v2.1.tar.gz
  ./download-backup.sh --destination ~/downloads 20260314
EOF
}

# 解析参数
parse_args() {
    DESTINATION="."
    FORCE=false
    VERBOSE=false
    GITHUB_USER="${GITHUB_USERNAME:-}"
    GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    REPO="elysia-soul-backup"
    BRANCH="backups"
    BACKUP_ID=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--destination)
                DESTINATION="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --github-user)
                GITHUB_USER="$2"
                shift 2
                ;;
            --github-token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --repo)
                REPO="$2"
                shift 2
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            *)
                if [[ -z "$BACKUP_ID" ]]; then
                    BACKUP_ID="$1"
                    shift
                else
                    warn "未知参数: $1"
                    shift
                fi
                ;;
        esac
    done

    # 验证必要参数
    if [[ -z "$BACKUP_ID" ]]; then
        error "必须指定备份ID"
    fi

    if [[ -z "$GITHUB_USER" ]]; then
        error "必须提供GitHub用户名（通过--github-user或GITHUB_USERNAME环境变量）"
    fi

    if [[ -z "$GITHUB_TOKEN" ]]; then
        error "必须提供GitHub Token（通过--github-token或GITHUB_TOKEN环境变量）"
    fi
}

# 创建目标目录
create_destination() {
    if [[ ! -d "$DESTINATION" ]]; then
        log "创建目标目录: $DESTINATION"
        mkdir -p "$DESTINATION"
    fi

    if [[ ! -w "$DESTINATION" ]]; then
        error "目标目录不可写: $DESTINATION"
    fi
}

# 查找备份文件
find_backup_file() {
    local backup_id="$1"
    local api_url="https://api.github.com/repos/$GITHUB_USER/$REPO/contents/?ref=$BRANCH"
    
    log "搜索备份文件: $backup_id"
    
    if [[ "$backup_id" == "latest" ]]; then
        # 获取最新的备份文件
        find_latest_backup "$api_url"
    elif [[ "$backup_id" =~ ^[0-9]{8}$ ]] || [[ "$backup_id" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # 按日期搜索
        find_backup_by_date "$backup_id" "$api_url"
    else
        # 按文件名搜索
        find_backup_by_name "$backup_id" "$api_url"
    fi
}

# 查找最新的备份文件
find_latest_backup() {
    local api_url="$1"
    
    log "查找最新的备份文件..."
    
    # 获取文件列表
    local response
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$api_url")
    
    if echo "$response" | grep -q "Not Found"; then
        error "找不到GitHub仓库: $GITHUB_USER/$REPO"
    fi
    
    # 提取备份文件并排序
    local backup_files
    backup_files=$(echo "$response" | grep -o '"name": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' | grep -E '^elysia-backup-.*\.tar\.gz$' | sort -r)
    
    if [[ -z "$backup_files" ]]; then
        error "在GitHub仓库中找不到备份文件"
    fi
    
    # 获取最新的文件
    local latest_file
    latest_file=$(echo "$backup_files" | head -1)
    
    log "找到最新备份文件: $latest_file"
    echo "$latest_file"
}

# 按日期搜索备份文件
find_backup_by_date() {
    local date_pattern="$1"
    local api_url="$2"
    
    # 转换日期格式
    local search_pattern
    if [[ "$date_pattern" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # 格式：2026-03-14 -> 20260314
        search_pattern=$(echo "$date_pattern" | tr -d '-')
    else
        search_pattern="$date_pattern"
    fi
    
    log "搜索日期匹配的备份文件: $search_pattern"
    
    # 获取文件列表
    local response
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$api_url")
    
    # 查找匹配的备份文件
    local matched_files
    matched_files=$(echo "$response" | grep -o '"name": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' | grep -E "^elysia-backup-.*$search_pattern.*\.tar\.gz$")
    
    if [[ -z "$matched_files" ]]; then
        warn "找不到日期匹配的备份文件: $search_pattern"
        warn "尝试查找所有可用备份文件..."
        
        # 显示所有可用的备份文件
        local all_backups
        all_backups=$(echo "$response" | grep -o '"name": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' | grep -E '^elysia-backup-.*\.tar\.gz$' | sort -r)
        
        if [[ -n "$all_backups" ]]; then
            log "可用的备份文件:"
            echo "$all_backups" | while read -r file; do
                echo "  - $file"
            done
        fi
        
        error "请指定正确的备份ID"
    fi
    
    # 如果有多个匹配，选择最新的一个
    local selected_file
    selected_file=$(echo "$matched_files" | sort -r | head -1)
    
    log "找到匹配的备份文件: $selected_file"
    echo "$selected_file"
}

# 按文件名搜索
find_backup_by_name() {
    local backup_name="$1"
    local api_url="$2"
    
    # 确保文件名以.tar.gz结尾
    if [[ ! "$backup_name" =~ \.tar\.gz$ ]]; then
        backup_name="${backup_name}.tar.gz"
    fi
    
    # 确保文件名以elysia-backup-开头
    if [[ ! "$backup_name" =~ ^elysia-backup- ]]; then
        backup_name="elysia-backup-${backup_name}"
    fi
    
    log "检查备份文件是否存在: $backup_name"
    
    # 检查文件是否存在
    local file_url="https://api.github.com/repos/$GITHUB_USER/$REPO/contents/$backup_name?ref=$BRANCH"
    local response
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$file_url")
    
    if echo "$response" | grep -q "Not Found"; then
        error "找不到备份文件: $backup_name"
    fi
    
    log "找到备份文件: $backup_name"
    echo "$backup_name"
}

# 下载备份文件
download_backup() {
    local backup_file="$1"
    local output_path="$DESTINATION/$backup_file"
    
    # 检查文件是否已存在
    if [[ -f "$output_path" ]] && [[ "$FORCE" != "true" ]]; then
        error "文件已存在: $output_path（使用 -f 强制覆盖）"
    fi
    
    # 下载URL
    local download_url="https://raw.githubusercontent.com/$GITHUB_USER/$REPO/$BRANCH/$backup_file"
    
    log "开始下载: $backup_file"
    log "下载到: $output_path"
    log "URL: $download_url"
    
    # 下载文件
    if [[ "$VERBOSE" == "true" ]]; then
        curl -L -H "Authorization: token $GITHUB_TOKEN" \
            -o "$output_path" \
            "$download_url"
    else
        curl -s -L -H "Authorization: token $GITHUB_TOKEN" \
            -o "$output_path" \
            "$download_url"
    fi
    
    # 检查下载是否成功
    if [[ $? -ne 0 ]] || [[ ! -f "$output_path" ]]; then
        error "下载失败: $backup_file"
    fi
    
    # 获取文件大小
    local file_size
    file_size=$(du -h "$output_path" | cut -f1)
    
    log "下载完成: $backup_file ($file_size)"
}

# 验证下载的文件
verify_download() {
    local backup_file="$1"
    local output_path="$DESTINATION/$backup_file"
    
    log "验证下载的文件..."
    
    # 检查文件大小
    local file_size
    file_size=$(stat -c%s "$output_path" 2>/dev/null || stat -f%z "$output_path" 2>/dev/null)
    
    if [[ "$file_size" -eq 0 ]]; then
        error "下载的文件大小为0: $backup_file"
    fi
    
    # 检查文件类型
    local file_type
    file_type=$(file "$output_path" | grep -o "gzip compressed data")
    
    if [[ -z "$file_type" ]]; then
        warn "文件可能不是有效的gzip压缩文件: $backup_file"
        warn "文件类型: $(file "$output_path")"
    else
        log "文件验证通过: gzip压缩文件"
    fi
    
    log "文件大小: $(($file_size / 1024 / 1024)) MB"
}

# 主函数
main() {
    log "==== 开始下载备份文件 ===="
    
    parse_args "$@"
    create_destination
    
    log "GitHub用户: $GITHUB_USER"
    log "目标目录: $(realpath "$DESTINATION")"
    
    # 查找备份文件
    local backup_file
    backup_file=$(find_backup_file "$BACKUP_ID")
    
    if [[ -z "$backup_file" ]]; then
        error "无法找到备份文件: $BACKUP_ID"
    fi
    
    # 下载备份文件
    download_backup "$backup_file"
    
    # 验证下载
    verify_download "$backup_file"
    
    log "==== 备份文件下载完成 ===="
    log "文件位置: $(realpath "$DESTINATION/$backup_file")"
    log "下一步: 使用 restore.sh 脚本恢复备份"
    
    echo -e "${GREEN}✓ 下载成功！${NC}"
    echo "备份文件: $backup_file"
    echo "位置: $(realpath "$DESTINATION/$backup_file")"
}

# 运行主函数
main "$@"