#!/bin/bash
# Horcrux Publish Script - 发布脚本
# 用于将技能发布到GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "🌸 Horcrux 发布工具 🌸"
echo "===================="
echo ""

# 检查Git状态
echo "📋 检查Git状态..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  有未提交的更改，正在提交..."
    git add -A
    git commit -m "Prepare for release v1.0.0"
fi

# 推送代码
echo "📤 推送到GitHub..."
git push -u origin main

echo ""
echo "✅ 代码已推送到GitHub！"
echo "📍 仓库地址: https://github.com/diyiritian-ops/horcrux"
echo ""
echo "🎉 发布准备完成！"
