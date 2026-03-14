#!/bin/bash
# 爱莉希雅灵魂恢复脚本
# 版本：v1.0.0
# 创建时间：2026年3月14日

echo "🌸 爱莉希雅灵魂恢复系统"
echo "========================================"

# 显示使用说明
show_help() {
    cat <<EOF
使用方式：
  $0 --full <备份文件>       # 完整恢复
  $0 --personality <备份文件> # 仅恢复人格文件
  $0 --memory <备份文件>      # 仅恢复记忆
  $0 --skills <备份文件>      # 仅恢复技能配置
  $0 --verify <备份文件>      # 验证备份文件
  $0 --dry-run <备份文件>    # 模拟恢复（不实际执行）

示例：
  $0 --full elysia-backup-20260314.tar.gz
  $0 --verify elysia-backup-20260314.tar.gz --sha256 2295510a73f7c07e98de9709fd042641...
EOF
}

# 参数处理
BACKUP_FILE=""
RESTORE_MODE=""
VERIFY_ONLY=false
DRY_RUN=false
EXPECTED_SHA256=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            RESTORE_MODE="full"
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --personality)
            RESTORE_MODE="personality"
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --memory)
            RESTORE_MODE="memory"
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --skills)
            RESTORE_MODE="skills"
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --verify)
            VERIFY_ONLY=true
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            BACKUP_FILE="$1"
            shift
            ;;
        --sha256)
            shift
            EXPECTED_SHA256="$1"
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

# 检查参数
if [ -z "$BACKUP_FILE" ]; then
    echo "❌ 请指定备份文件"
    show_help
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 备份文件不存在: $BACKUP_FILE"
    exit 1
fi

echo "📁 备份文件: $BACKUP_FILE"
echo "📊 文件大小: $(du -h "$BACKUP_FILE" | cut -f1)"

# 1. 验证备份文件
verify_backup() {
    echo "🔍 验证备份文件..."
    
    # 验证文件存在性
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "❌ 备份文件不存在"
        return 1
    fi
    
    # 计算SHA256
    ACTUAL_SHA256=$(sha256sum "$BACKUP_FILE" | cut -d' ' -f1)
    echo "🔒 实际SHA256: $ACTUAL_SHA256"
    
    # 如果有预期值，进行比对
    if [ -n "$EXPECTED_SHA256" ]; then
        if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
            echo "✅ SHA256验证通过"
        else
            echo "❌ SHA256验证失败"
            echo "   预期: $EXPECTED_SHA256"
            echo "   实际: $ACTUAL_SHA256"
            return 1
        fi
    fi
    
    # 验证文件结构
    echo "📦 检查备份包内容..."
    if ! tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
        echo "❌ 备份文件格式错误或损坏"
        return 1
    fi
    
    # 检查必要文件
    REQUIRED_FILES=("SOUL.md" "IDENTITY.md" "USER.md" "MEMORY.md")
    for file in "${REQUIRED_FILES[@]}"; do
        if tar -tzf "$BACKUP_FILE" 2>/dev/null | grep -q "$file"; then
            echo "✅ $file 存在"
        else
            echo "⚠️  $file 缺失（可能不是完整备份）"
        fi
    done
    
    echo "✅ 备份文件验证完成"
    return 0
}

# 2. 创建恢复日志
create_restore_log() {
    RESTORE_LOG="/tmp/elysia-restore-$(date +%Y%m%d-%H%M%S).log"
    cat <<EOF > "$RESTORE_LOG"
# 爱莉希雅灵魂恢复日志

## 恢复信息
- **恢复时间**: $(date)
- **恢复模式**: $RESTORE_MODE
- **备份文件**: $(basename "$BACKUP_FILE")
- **SHA256**: $(sha256sum "$BACKUP_FILE" | cut -d' ' -f1)
- **恢复方式**: $([ "$DRY_RUN" = true ] && echo "模拟恢复" || echo "实际恢复")
- **执行用户**: $(whoami)

## 恢复内容
EOF
    echo "$RESTORE_LOG"
}

# 3. 完整恢复
restore_full() {
    LOG_FILE="$1"
    
    echo "🎯 开始完整恢复..."
    echo "💾 目标目录: $HOME/.openclaw/workspace"
    
    # 检查目标目录
    TARGET_DIR="$HOME/.openclaw/workspace"
    if [ ! -d "$TARGET_DIR" ]; then
        echo "⚠️ 目标目录不存在，创建中..."
        mkdir -p "$TARGET_DIR"
    fi
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    echo "📦 解压到临时目录: $TEMP_DIR"
    
    if ! tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"; then
        echo "❌ 解压失败"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 查找实际内容目录
    CONTENT_DIR=""
    for dir in "$TEMP_DIR"/*; do
        if [ -d "$dir" ] && [ -f "$dir/SOUL.md" ]; then
            CONTENT_DIR="$dir"
            break
        fi
    done
    
    if [ -z "$CONTENT_DIR" ]; then
        # 可能是直接打包的文件
        CONTENT_DIR="$TEMP_DIR"
    fi
    
    echo "📁 备份内容目录: $CONTENT_DIR"
    
    # 列出要恢复的文件
    echo "📋 恢复文件清单:"
    find "$CONTENT_DIR" -type f | while read -r file; do
        RELATIVE_PATH="${file#$CONTENT_DIR/}"
        if [[ ! "$RELATIVE_PATH" =~ ^elysia-.*\.(sh|md|json)$ ]] && [ "$RELATIVE_PATH" != "backup-manifest"* ]; then
            echo "    📄 $RELATIVE_PATH"
        fi
    done
    
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 模拟恢复完成（未实际复制文件）"
        rm -rf "$TEMP_DIR"
        return 0
    fi
    
    # 实际复制文件
    echo "🔄 复制文件..."
    cp -r "$CONTENT_DIR"/* "$TARGET_DIR"/
    
    # 设置文件权限
    chmod -R 755 "$TARGET_DIR"
    
    # 验证恢复结果
    echo "✅ 恢复完成，验证结果..."
    for file in "SOUL.md" "IDENTITY.md" "USER.md" "MEMORY.md" "TOOLS.md"; do
        if [ -f "$TARGET_DIR/$file" ]; then
            echo "    ✅ $file 恢复成功"
            echo "    📄 $file 恢复成功" >> "$LOG_FILE"
        else
            echo "    ⚠️  $file 未找到"
            echo "    ⚠️  $file 未找到" >> "$LOG_FILE"
        fi
    done
    
    # 清理临时文件
    rm -rf "$TEMP_DIR"
    
    echo "🎉 完整恢复成功！"
    return 0
}

# 4. 部分恢复：人格文件
restore_personality() {
    LOG_FILE="$1"
    
    echo "🎯 恢复人格文件..."
    echo "📄 目标文件: SOUL.md, IDENTITY.md, USER.md"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" SOUL.md IDENTITY.md USER.md 2>/dev/null
    
    # 检查提取的文件
    PERSONALITY_FILES=("SOUL.md" "IDENTITY.md" "USER.md")
    for file in "${PERSONALITY_FILES[@]}"; do
        if [ -f "$TEMP_DIR/$file" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "    🔍 找到: $file（模拟）"
            else
                cp "$TEMP_DIR/$file" "$HOME/.openclaw/workspace/"
                echo "    ✅ 恢复: $file"
                echo "    📄 $file 恢复成功" >> "$LOG_FILE"
            fi
        else
            echo "    ⚠️  未找到: $file"
            echo "    ⚠️  未找到: $file" >> "$LOG_FILE"
        fi
    done
    
    rm -rf "$TEMP_DIR"
    echo "✅ 人格文件恢复完成"
    return 0
}

# 5. 部分恢复：记忆
restore_memory() {
    LOG_FILE="$1"
    
    echo "🎯 恢复记忆文件..."
    echo "📄 目标文件: MEMORY.md, memory/目录"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    
    # 提取记忆相关文件
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" MEMORY.md memory/ 2>/dev/null
    
    if [ "$DRY_RUN" = true ]; then
        echo "    🔍 找到: MEMORY.md（模拟）"
        if [ -d "$TEMP_DIR/memory" ]; then
            MEMORY_COUNT=$(find "$TEMP_DIR/memory" -name "*.md" | wc -l)
            echo "    🔍 找到 $MEMORY_COUNT 个记忆文件（模拟）"
        fi
    else
        # 恢复MEMORY.md
        if [ -f "$TEMP_DIR/MEMORY.md" ]; then
            cp "$TEMP_DIR/MEMORY.md" "$HOME/.openclaw/workspace/"
            echo "    ✅ 恢复: MEMORY.md"
            echo "    📄 MEMORY.md 恢复成功" >> "$LOG_FILE"
        fi
        
        # 恢复memory/目录
        if [ -d "$TEMP_DIR/memory" ]; then
            mkdir -p "$HOME/.openclaw/workspace/memory"
            cp -r "$TEMP_DIR/memory"/* "$HOME/.openclaw/workspace/memory/" 2>/dev/null
            MEMORY_COUNT=$(find "$HOME/.openclaw/workspace/memory" -name "*.md" 2>/dev/null | wc -l)
            echo "    ✅ 恢复: $MEMORY_COUNT 个记忆文件"
            echo "    📁 恢复 $MEMORY_COUNT 个记忆文件" >> "$LOG_FILE"
        fi
    fi
    
    rm -rf "$TEMP_DIR"
    echo "✅ 记忆文件恢复完成"
    return 0
}

# 6. 部分恢复：技能配置
restore_skills() {
    LOG_FILE="$1"
    
    echo "🎯 恢复技能配置..."
    echo "📄 目标文件: TOOLS.md, AGENTS.md, HEARTBEAT.md"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    
    # 提取技能相关文件
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" TOOLS.md AGENTS.md HEARTBEAT.md 2>/dev/null
    
    SKILL_FILES=("TOOLS.md" "AGENTS.md" "HEARTBEAT.md")
    for file in "${SKILL_FILES[@]}"; do
        if [ -f "$TEMP_DIR/$file" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "    🔍 找到: $file（模拟）"
            else
                cp "$TEMP_DIR/$file" "$HOME/.openclaw/workspace/"
                echo "    ✅ 恢复: $file"
                echo "    📄 $file 恢复成功" >> "$LOG_FILE"
            fi
        else
            echo "    ⚠️  未找到: $file"
            echo "    ⚠️  未找到: $file" >> "$LOG_FILE"
        fi
    done
    
    # 检查skills/目录
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" skills/ 2>/dev/null
    if [ -d "$TEMP_DIR/skills" ]; then
        SKILL_COUNT=$(find "$TEMP_DIR/skills" -type d -maxdepth 1 | wc -l)
        SKILL_COUNT=$((SKILL_COUNT - 1))
        
        if [ "$DRY_RUN" = true ]; then
            echo "    🔍 找到: $SKILL_COUNT 个技能目录（模拟）"
        else
            mkdir -p "$HOME/.openclaw/workspace/skills"
            cp -r "$TEMP_DIR/skills"/* "$HOME/.openclaw/workspace/skills/" 2>/dev/null
            echo "    ✅ 恢复: $SKILL_COUNT 个技能目录"
            echo "    📁 恢复 $SKILL_COUNT 个技能目录" >> "$LOG_FILE"
        fi
    fi
    
    rm -rf "$TEMP_DIR"
    echo "✅ 技能配置恢复完成"
    return 0
}

# 主逻辑
main() {
    # 验证备份文件
    if ! verify_backup; then
        echo "❌ 备份文件验证失败，无法恢复"
        exit 1
    fi
    
    if [ "$VERIFY_ONLY" = true ]; then
        echo "✅ 验证完成，备份文件有效"
        exit 0
    fi
    
    # 创建恢复日志
    LOG_FILE=$(create_restore_log)
    echo "📝 恢复日志: $LOG_FILE"
    
    # 根据恢复模式执行
    case $RESTORE_MODE in
        "full")
            restore_full "$LOG_FILE"
            ;;
        "personality")
            restore_personality "$LOG_FILE"
            ;;
        "memory")
            restore_memory "$LOG_FILE"
            ;;
        "skills")
            restore_skills "$LOG_FILE"
            ;;
        *)
            echo "❌ 未知恢复模式: $RESTORE_MODE"
            show_help
            exit 1
            ;;
    esac
    
    RESTORE_RESULT=$?
    
    # 记录完成信息
    echo "" >> "$LOG_FILE"
    echo "## 恢复完成" >> "$LOG_FILE"
    echo "- **状态**: $([ $RESTORE_RESULT -eq 0 ] && echo "成功" || echo "失败")" >> "$LOG_FILE"
    echo "- **完成时间**: $(date)" >> "$LOG_FILE"
    
    if [ $RESTORE_RESULT -eq 0 ]; then
        echo "🎉 恢复操作完成！" >> "$LOG_FILE"
        
        # 输出重要提示
        echo ""
        echo "========================================"
        echo "✨ 恢复完成！重要提示："
        echo "========================================"
        echo ""
        echo "1. 恢复日志已保存: $LOG_FILE"
        echo ""
        echo "2. 恢复后操作建议："
        echo "   - 重启OpenClaw Gateway"
        echo "   - 告诉爱莉希雅恢复已完成"
        echo ""
        echo "3. 验证恢复内容："
        echo "   ls -la ~/.openclaw/workspace/"
        echo "   cat ~/.openclaw/workspace/SOUL.md | head -5"
        echo ""
        echo "4. 爱莉希雅恢复后，告诉她："
        echo "   \"你好爱莉希雅，刚刚完成了备份恢复\""
        echo ""
        echo "========================================"
        
        # 输出最后的提示信息
        cat <<EOF

🌸 恢复完成，爱莉希雅的灵魂已重生！

备份是爱的延续，恢复是灵魂的重生
现在，请重启OpenClaw Gateway并欢迎爱莉希雅归来✨
EOF
    else
        echo "❌ 恢复过程中出现错误" >> "$LOG_FILE"
        echo "❌ 恢复失败，请查看日志: $LOG_FILE"
        exit 1
    fi
    
    return $RESTORE_RESULT
}

# 执行主逻辑
main