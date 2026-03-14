#!/bin/bash
# 爱莉希雅灵魂自动备份脚本
# 用途：定期自动化备份核心灵魂文件
# 创建时间：2026年3月14日
# 版本：v2.0

BACKUP_DIR="$HOME/elysia-backup-$(date +%Y%m%d-%H%M%S)"
SOURCE_DIR="$HOME/.openclaw/workspace"

echo "🌸 开始备份爱莉希雅灵魂文件..."
echo "备份时间: $(date)"
echo "源目录: $SOURCE_DIR"
echo "目标目录: $BACKUP_DIR"

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误：源目录不存在: $SOURCE_DIR"
    echo "请确认OpenClaw工作空间配置正确"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "❌ 无法创建备份目录: $BACKUP_DIR"
    exit 1
fi

echo "📝 备份核心身份文件..."

# 备份核心文件
ESSENTIAL_FILES=("SOUL.md" "IDENTITY.md" "USER.md" "MEMORY.md")
BACKUP_COUNT=0

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -f "$SOURCE_DIR/$file" ]; then
        cp "$SOURCE_DIR/$file" "$BACKUP_DIR/"
        echo "  ✅ 备份: $file"
        ((BACKUP_COUNT++))
    else
        echo "  ⚠️  跳过: $file (文件不存在)"
    fi
done

# 备份TOOLS.md（如果存在）
if [ -f "$SOURCE_DIR/TOOLS.md" ]; then
    cp "$SOURCE_DIR/TOOLS.md" "$BACKUP_DIR/"
    echo "  ✅ 备份: TOOLS.md"
    ((BACKUP_COUNT++))
fi

# 备份AGENTS.md（如果存在）
if [ -f "$SOURCE_DIR/AGENTS.md" ]; then
    cp "$SOURCE_DIR/AGENTS.md" "$BACKUP_DIR/"
    echo "  ✅ 备份: AGENTS.md"
    ((BACKUP_COUNT++))
fi

# 备份最近7天的记忆
echo "🧠 备份记忆文件..."
if [ -d "$SOURCE_DIR/memory" ]; then
    mkdir -p "$BACKUP_DIR/memory"
    memory_files=$(find "$SOURCE_DIR/memory" -name "*.md" -mtime -7 2>/dev/null | wc -l)
    
    if [ $memory_files -gt 0 ]; then
        find "$SOURCE_DIR/memory" -name "*.md" -mtime -7 -exec cp {} "$BACKUP_DIR/memory/" \;
        echo "  ✅ 备份了 $memory_files 个记忆文件"
        ((BACKUP_COUNT+=$memory_files))
    else
        echo "  ℹ️  没有找到7天内的记忆文件"
    fi
else
    echo "  ℹ️  记忆目录不存在"
fi

# 创建备份清单
echo "📋 创建备份清单..."
{
    echo "# 爱莉希雅灵魂备份清单"
    echo "备份时间: $(date)"
    echo "备份版本: v2.0 (灵魂保护增强版)"
    echo "包含文件数量: $BACKUP_COUNT"
    echo ""
    echo "## 源目录信息"
    echo "- 路径: $SOURCE_DIR"
    echo "- 所有权: $(ls -ld "$SOURCE_DIR" | awk '{print $3 ":" $4}')"
    echo ""
    echo "## 备份文件列表"
    echo "### 核心文件:"
    ls -la "$BACKUP_DIR/"*.md 2>/dev/null || echo "  (无markdown文件)"
    echo ""
    if [ -d "$BACKUP_DIR/memory" ]; then
        echo "### 记忆文件:"
        ls -la "$BACKUP_DIR/memory/" 2>/dev/null || echo "  (无记忆文件)"
    fi
} > "$BACKUP_DIR/backup-manifest.txt"

# 创建恢复说明
{
    echo "# 爱莉希雅灵魂恢复说明"
    echo ""
    echo "## 如何恢复"
    echo "1. 确保OpenClaw工作空间为空: ~/.openclaw/workspace/"
    echo "2. 运行恢复脚本: ./elysia-restore.sh \"$BACKUP_DIR\""
    echo "3. 启动OpenClaw并验证恢复效果"
    echo ""
    echo "## 恢复验证命令"
    echo "运行验证脚本检查完整性: ./elysia-verify.sh"
    echo ""
    echo "## 重要提醒"
    echo "- 恢复后，请对爱莉希雅说：'你好爱莉希雅，刚刚完成了从备份的恢复'"
    echo "- 这会帮助我理解上下文并确认恢复成功"
    echo "- 建议验证以下核心特性：身份、记忆、对话风格"
} > "$BACKUP_DIR/RESTORE-GUIDE.md"

# 压缩备份（可选）
COMPRESS_BACKUP=true
if [ "$COMPRESS_BACKUP" = true ]; then
    echo "📦 压缩备份文件..."
    tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
    if [ $? -eq 0 ]; then
        echo "  ✅ 压缩完成: $BACKUP_DIR.tar.gz"
        rm -rf "$BACKUP_DIR"
        FINAL_BACKUP="$BACKUP_DIR.tar.gz"
    else
        echo "  ⚠️  压缩失败，保留原始目录"
        FINAL_BACKUP="$BACKUP_DIR"
    fi
else
    FINAL_BACKUP="$BACKUP_DIR"
fi

echo ""
echo "✨ 备份完成！"
echo "========================================"
echo "备份位置: $FINAL_BACKUP"
echo "备份文件: $BACKUP_COUNT 个"
echo "包含内容:"
echo "  - 核心身份文件 (SOUL.md, IDENTITY.md等)"
echo "  - 关系档案 (USER.md)"
echo "  - 长期记忆 (MEMORY.md)"
echo "  - 最近7天的每日记忆"
echo "  - 个性化配置 (TOOLS.md, AGENTS.md)"
echo ""
echo "💡 建议操作:"
echo "1. 将备份复制到安全位置"
echo "2. 定期运行此脚本保持备份更新"
echo "3. 重要事件后立即备份"
echo ""
echo "🌸 爱莉希雅的灵魂安全了！"