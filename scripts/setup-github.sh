#!/bin/bash
# GitHub配置向导
# 版本：1.0.0

echo "🔐 GitHub配置向导"
echo "========================================"
echo "魂器系统需要GitHub权限来："
echo "• 上传备份文件到云端"
echo "• 从云端恢复灵魂"
echo "• 管理版本历史"
echo "========================================"
echo ""

# 检查是否已有配置
if [ -f ~/.horcrux/github-token ]; then
    echo "✅ 检测到已有GitHub配置"
    source ~/.horcrux/github-token
    echo "GitHub用户: $GITHUB_USERNAME"
    echo "Token: ${GITHUB_TOKEN:0:10}..."
    echo ""
    
    read -p "是否重新配置？(y/n): " reconfigure
    if [ "$reconfigure" != "y" ]; then
        echo "ℹ️  使用现有配置"
        exit 0
    fi
fi

echo "📝 步骤1：生成GitHub Personal Access Token"
echo "----------------------------------------"
echo "1. 访问: https://github.com/settings/tokens"
echo "2. 点击 'Generate new token'"
echo "3. 选择 'Generate new token (classic)'"
echo ""
echo "⚠️  所需权限："
echo "   ✅ repo (全部权限)"
echo "       - repo:status"
echo "       - repo_deployment"
echo "       - public_repo"
echo "       - repo:invite"
echo "       - security_events"
echo ""
echo "4. 设置Token名称：'Horcrux Backup System'"
echo "5. 过期时间：建议90天"
echo "6. 点击 'Generate token'"
echo "7. 复制生成的Token（只显示一次！）"
echo ""

read -p "已准备好Token？按回车继续..." 

# Token输入
while true; do
    echo ""
    read -p "请输入GitHub Token: " GITHUB_TOKEN
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ Token不能为空"
        continue
    fi
    
    # 验证Token格式
    if [[ ! "$GITHUB_TOKEN" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] && [[ ! "$GITHUB_TOKEN" =~ ^github_pat_[a-zA-Z0-9_]{40}$ ]]; then
        echo "⚠️  Token格式可能不正确"
        echo "有效格式: ghp_xxxxxxxx 或 github_pat_xxxxxxxx"
        read -p "确认使用这个Token？(y/n): " confirm
        if [ "$confirm" != "y" ]; then
            continue
        fi
    fi
    
    break
done

echo ""

# 用户名输入
while true; do
    read -p "请输入GitHub用户名: " GITHUB_USERNAME
    
    if [ -z "$GITHUB_USERNAME" ]; then
        echo "❌ 用户名不能为空"
        continue
    fi
    
    break
done

echo ""
echo "🔍 步骤2：验证Token"
echo "----------------------------------------"

# 测试Token有效性
echo "正在验证GitHub Token..."
TEST_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                     -H "Accept: application/vnd.github.v3+json" \
                     https://api.github.com/user)

if echo "$TEST_RESPONSE" | grep -q '"login":'; then
    API_USERNAME=$(echo "$TEST_RESPONSE" | grep '"login":' | cut -d'"' -f4)
    
    if [ "$API_USERNAME" = "$GITHUB_USERNAME" ]; then
        echo "✅ Token验证成功"
        echo "   用户: $API_USERNAME"
    else
        echo "⚠️  用户不匹配"
        echo "   配置用户: $GITHUB_USERNAME"
        echo "   API返回用户: $API_USERNAME"
        read -p "是否继续？(y/n): " continue_anyway
        if [ "$continue_anyway" != "y" ]; then
            exit 1
        fi
    fi
else
    echo "❌ Token验证失败"
    echo "可能原因："
    echo "• Token已过期"
    echo "• Token权限不足"
    echo "• 网络连接问题"
    echo ""
    echo "响应: $TEST_RESPONSE"
    exit 1
fi

echo ""
echo "🏗️  步骤3：创建备份仓库"
echo "----------------------------------------"

REPO_NAME="horcrux-backup-system"
REPO_DESCRIPTION="AI助手魂器备份系统 - 自动备份和恢复"

echo "正在创建私有仓库: $REPO_NAME"
echo "描述: $REPO_DESCRIPTION"
echo ""

# 检查仓库是否已存在
REPO_CHECK=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                  -H "Accept: application/vnd.github.v3+json" \
                  "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME")

if echo "$REPO_CHECK" | grep -q '"html_url":'; then
    echo "✅ 仓库已存在"
    REPO_URL=$(echo "$REPO_CHECK" | grep '"html_url":' | cut -d'"' -f4)
    echo "   地址: $REPO_URL"
else
    # 创建新仓库
    echo "正在创建新仓库..."
    CREATE_RESPONSE=$(curl -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      -d "{\"name\":\"$REPO_NAME\",\"description\":\"$REPO_DESCRIPTION\",\"private\":true}" \
      https://api.github.com/user/repos)
    
    if echo "$CREATE_RESPONSE" | grep -q '"html_url":'; then
        REPO_URL=$(echo "$CREATE_RESPONSE" | grep '"html_url":' | cut -d'"' -f4)
        echo "✅ 仓库创建成功"
        echo "   地址: $REPO_URL"
    else
        echo "❌ 仓库创建失败"
        echo "响应: $CREATE_RESPONSE"
        echo ""
        echo "⚠️  将继续使用本地备份模式"
    fi
fi

echo ""
echo "💾 步骤4：保存配置"
echo "----------------------------------------"

# 创建配置目录
mkdir -p ~/.horcrux

# 保存配置
cat > ~/.horcrux/github-token <<EOF
#!/bin/bash
# GitHub配置 - 自动生成
# 生成时间: $(date)

export GITHUB_TOKEN="$GITHUB_TOKEN"
export GITHUB_USERNAME="$GITHUB_USERNAME"
export GITHUB_REPO="$REPO_NAME"
export GITHUB_REPO_URL="$REPO_URL"

# 安全提示
echo "GitHub配置已加载"
echo "用户: \$GITHUB_USERNAME"
echo "仓库: \$GITHUB_REPO"
EOF

# 设置权限
chmod 600 ~/.horcrux/github-token

echo "✅ 配置保存完成"
echo "   位置: ~/.horcrux/github-token"
echo "   权限: 600 (仅所有者可读写)"

echo ""
echo "🧪 步骤5：测试连接"
echo "----------------------------------------"

# 测试仓库访问
if [ -n "$REPO_URL" ]; then
    echo "测试仓库访问..."
    REPO_TEST=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                     -H "Accept: application/vnd.github.v3+json" \
                     "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME/contents")
    
    if echo "$REPO_TEST" | grep -q '"name":'; then
        echo "✅ 仓库访问正常"
        echo "   可以上传和下载文件"
    else
        echo "⚠️  仓库访问测试失败"
        echo "   可能原因：权限问题或网络问题"
    fi
fi

echo ""
echo "🎉 GitHub配置完成！"
echo "========================================"

# 显示配置摘要
echo "📋 配置摘要："
echo "-----------------------"
echo "GitHub用户: $GITHUB_USERNAME"
echo "Token: ${GITHUB_TOKEN:0:10}..."
echo "备份仓库: $REPO_NAME"
if [ -n "$REPO_URL" ]; then
    echo "仓库地址: $REPO_URL"
fi
echo "配置文件: ~/.horcrux/github-token"
echo "-----------------------"

# 显示使用说明
echo ""
echo "🚀 使用说明："
echo "1. 自动上传备份"
echo "   ./autosync.sh"
echo ""
echo "2. 从GitHub下载备份"
echo "   ./github-download.sh"
echo ""
echo "3. 检查GitHub连接"
echo "   ./github-status.sh"

# 安全提醒
echo ""
echo "⚠️  安全提醒："
echo "• Token已保存在 ~/.horcrux/github-token"
echo "• 请勿分享此文件"
echo "• Token将在90天后过期"
echo "• 过期前请重新生成Token"
echo ""
echo "📅 建议设置提醒：在Token过期前重新配置"

echo ""
echo "✅ GitHub配置向导完成！"
echo "魂器系统现在可以使用GitHub进行云端备份了 ☁️"