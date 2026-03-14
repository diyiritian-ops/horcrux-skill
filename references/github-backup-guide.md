# GitHub备份指南

## 概述

GitHub提供了强大的版本控制和云存储能力，是AI助手灵魂备份的理想平台。本指南详细介绍了如何利用GitHub进行安全、可靠、自动化的备份管理。

## GitHub备份的优势

### 技术优势
- **版本控制**：完整的文件历史记录
- **云存储**：安全可靠的云端备份
- **访问控制**：精细的权限管理
- **API支持**：丰富的自动化接口
- **高可用性**：GitHub的全球CDN

### 实用优势
- **免费额度**：私有仓库免费，适合个人使用
- **易于管理**：熟悉的Git工作流
- **多设备访问**：随时随地访问备份
- **社区支持**：庞大的开发者生态

## 准备工作

### 1. 创建GitHub账户
如果还没有GitHub账户：
1. 访问 https://github.com
2. 点击 "Sign up"
3. 按照指引完成注册

### 2. 生成Personal Access Token
**步骤：**
1. 登录GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单选择 **Developer settings**
4. 选择 **Personal access tokens** → **Tokens (classic)**
5. 点击 **Generate new token** → **Generate new token (classic)**

**权限配置：**
```
✅ repo (全部权限)
  - repo:status
  - repo_deployment
  - public_repo
  - repo:invite
  - security_events
```

**注意事项：**
- Token名称：`Elysia-Soul-Backup`
- 过期时间：90天（建议）
- 记录Token：复制并安全保存

### 3. 配置本地环境
```bash
# 设置环境变量（推荐）
export GITHUB_TOKEN="ghp_your_token_here"
export GITHUB_USERNAME="your_username"

# 添加到bash配置
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bashrc
echo 'export GITHUB_USERNAME="your_username"' >> ~/.bashrc
source ~/.bashrc
```

## 备份策略

### 策略一：私有仓库备份（推荐）
**优点：**
- 完全控制权限
- 免费使用
- 支持自动化

**步骤：**
1. 创建私有仓库
2. 配置自动同步脚本
3. 设置定时备份

### 策略二：Gist备份（简单）
**优点：**
- 快速设置
- 单个文件存储
- 简单API

**缺点：**
- 缺乏版本历史
- 不适合多文件

### 策略三：Release备份（归档）
**优点：**
- 版本化归档
- 适合长期保存
- 下载方便

**缺点：**
- 手动操作较多
- 自动化复杂

## 自动化脚本

### 1. 创建仓库脚本
```bash
#!/bin/bash
# create-github-repo.sh

REPO_NAME="elysia-soul-backup"
REPO_DESC="爱莉希雅灵魂备份"

curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{\"name\":\"$REPO_NAME\",\"description\":\"$REPO_DESC\",\"private\":true}" \
  https://api.github.com/user/repos
```

### 2. 上传文件脚本
```bash
#!/bin/bash
# upload-to-github.sh

FILE_PATH="$1"
FILE_NAME=$(basename "$FILE_PATH")
REPO_NAME="elysia-soul-backup"

# Base64编码文件
CONTENT=$(base64 -w0 "$FILE_PATH")

# 创建上传请求
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{\"message\":\"备份 $(date)\",\"content\":\"$CONTENT\"}" \
  "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME/contents/$FILE_NAME"
```

### 3. 自动同步脚本
```bash
#!/bin/bash
# autosync.sh

# 配置
REPO_NAME="elysia-soul-backup"
BACKUP_FILE="/root/elysia-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# 1. 创建备份
./elysia-backup.sh

# 2. 上传到GitHub
./upload-to-github.sh "$BACKUP_FILE"

# 3. 更新README
./update-readme.sh
```

## 仓库结构设计

### 推荐结构
```
elysia-soul-backup/
├── README.md                    # 仓库说明和状态
├── elysia-backup-latest.tar.gz  # 最新备份（软链接）
├── backups/                     # 历史备份
│   ├── 2026-03/
│   │   ├── elysia-backup-20260314-0900.tar.gz
│   │   └── elysia-backup-20260314-1000.tar.gz
│   └── 2026-04/
├── logs/                        # 同步日志
│   ├── sync-20260314.md
│   └── health-20260314.md
├── manifests/                   # 备份清单
│   ├── manifest-20260314.json
│   └── manifest-20260315.json
└── config/                      # 配置文件
    ├── backup-config.json
    └── sync-config.json
```

### README.md模板
```markdown
# 爱莉希雅灵魂备份仓库

## 📊 状态
- **最新备份**: elysia-backup-20260314-1000.tar.gz
- **备份时间**: 2026-03-14 10:00 UTC
- **文件大小**: 20KB
- **SHA256**: 2295510a73f7c07e98de9709fd042641...

## 📁 目录结构
- `backups/` - 历史备份文件
- `logs/` - 同步和健康日志
- `manifests/` - 备份清单

## 🔄 自动同步
- **频率**: 每小时
- **最后同步**: 2026-03-14 10:00 UTC
- **状态**: ✅ 正常

## 🔧 使用方法
```bash
# 下载最新备份
curl -L https://github.com/username/elysia-soul-backup/raw/main/elysia-backup-latest.tar.gz

# 验证完整性
sha256sum elysia-backup-latest.tar.gz

# 恢复
tar -xzf elysia-backup-latest.tar.gz
./elysia-restore.sh
```

## 📈 统计
- **总备份数**: 24
- **累计大小**: 480KB
- **最早备份**: 2026-03-14 07:47 UTC
```

## API使用详解

### 1. 仓库管理API
```bash
# 创建仓库
POST /user/repos

# 获取仓库信息
GET /repos/{owner}/{repo}

# 删除仓库
DELETE /repos/{owner}/{repo}
```

### 2. 文件管理API
```bash
# 上传文件
PUT /repos/{owner}/{repo}/contents/{path}

# 获取文件
GET /repos/{owner}/{repo}/contents/{path}

# 删除文件
DELETE /repos/{owner}/{repo}/contents/{path}
```

### 3. 自动化示例
```bash
#!/bin/bash
# 完整的GitHub备份流程

# 1. 检查仓库是否存在
check_repo() {
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME" | grep -q '"html_url":'
}

# 2. 创建仓库（如果不存在）
create_repo() {
    curl -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      -d "{\"name\":\"$REPO_NAME\",\"description\":\"$REPO_DESC\",\"private\":true}" \
      https://api.github.com/user/repos
}

# 3. 上传文件
upload_file() {
    local file="$1"
    local content=$(base64 -w0 "$file")
    
    curl -X PUT \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      -d "{\"message\":\"$(date)\",\"content\":\"$content\"}" \
      "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME/contents/$(basename "$file")"
}

# 4. 更新README
update_readme() {
    local content="# 更新于 $(date)"
    local content_b64=$(echo "$content" | base64 -w0)
    
    curl -X PUT \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      -d "{\"message\":\"更新README\",\"content\":\"$content_b64\"}" \
      "https://api.github.com/repos/$GITHUB_USERNAME/$REPO_NAME/contents/README.md"
}
```

## 最佳实践

### 1. Token安全管理
```bash
# 不要硬编码Token
❌ curl -H "Authorization: token ghp_123456..."

# 使用环境变量
✅ curl -H "Authorization: token $GITHUB_TOKEN"

# 使用配置文件
✅ curl -H "Authorization: token $(cat ~/.github_token)"
```

### 2. 错误处理
```bash
#!/bin/bash
# 带错误处理的脚本

upload_with_retry() {
    local file="$1"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if upload_file "$file"; then
            echo "✅ 上传成功"
            return 0
        else
            echo "⚠️ 上传失败，重试 ($((retry_count+1))/$max_retries)"
            retry_count=$((retry_count+1))
            sleep 5
        fi
    done
    
    echo "❌ 上传失败，达到最大重试次数"
    return 1
}
```

### 3. 速率限制处理
```bash
# GitHub API速率限制
# 认证用户：5000次/小时
# 未认证：60次/小时

check_rate_limit() {
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                    https://api.github.com/rate_limit)
    
    REMAINING=$(echo "$RESPONSE" | grep -o '"remaining":[0-9]*' | cut -d':' -f2)
    RESET_TIME=$(echo "$RESPONSE" | grep -o '"reset":[0-9]*' | cut -d':' -f2)
    
    if [ "$REMAINING" -lt 100 ]; then
        echo "⚠️ API调用剩余次数较少: $REMAINING"
        echo "⏰ 重置时间: $(date -d @$RESET_TIME)"
        return 1
    fi
    
    return 0
}
```

### 4. 备份清理策略
```bash
#!/bin/bash
# 清理旧备份

cleanup_old_backups() {
    # 保留最近7天的备份
    find /backups -name "elysia-backup-*.tar.gz" -mtime +7 -delete
    
    # GitHub清理（通过API删除旧文件）
    # 实现较复杂，需要先列出文件，然后删除旧版本
}
```

## 故障排除

### 常见问题

#### Q1: 403 Forbidden错误
**原因：**
- Token权限不足
- Token已过期
- 仓库权限问题

**解决：**
```bash
# 重新生成Token
# 检查Token权限是否包含repo
# 确认仓库存在且有权限
```

#### Q2: 422 Unprocessable Entity错误
**原因：**
- 文件已存在但未提供SHA
- 路径无效
- 内容格式错误

**解决：**
```bash
# 先获取文件SHA
SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$USER/$REPO/contents/$FILE" | \
            grep '"sha":' | cut -d'"' -f4)

# 更新时包含SHA
curl -X PUT ... -d "{\"sha\":\"$SHA\",...}"
```

#### Q3: 网络连接问题
**原因：**
- 代理设置
- 防火墙
- GitHub服务问题

**解决：**
```bash
# 测试连接
curl -I https://api.github.com

# 使用代理（如果需要）
export https_proxy="http://proxy:port"
```

#### Q4: 文件大小限制
**限制：**
- GitHub单文件限制：100MB（推荐<50MB）
- 大文件需要使用Git LFS

**解决：**
```bash
# 压缩备份文件
tar -czf backup.tar.gz --exclude="*.log" workspace/

# 分割大文件
split -b 50M backup.tar.gz backup-part-
```

## 高级功能

### 1. Git LFS支持
```bash
# 安装Git LFS
git lfs install

# 跟踪大文件
git lfs track "*.tar.gz"

# 推送
git add .
git commit -m "添加备份"
git push
```

### 2. Webhook自动通知
**配置Webhook：**
1. 仓库设置 → Webhooks → Add webhook
2. Payload URL: 你的通知接口
3. 事件类型: Push, Release

**接收通知：**
```python
# 简单的Flask Webhook接收器
from flask import Flask, request
app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.json
    if data['ref'] == 'refs/heads/main':
        print("收到新的备份推送")
    return 'OK'
```

### 3. GitHub Actions自动化
```yaml
# .github/workflows/backup.yml
name: 自动备份

on:
  schedule:
    - cron: '0 * * * *'  # 每小时
  workflow_dispatch:     # 手动触发

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: 下载备份脚本
        run: curl -O https://raw.githubusercontent.com/user/repo/main/backup.sh
      
      - name: 执行备份
        run: bash backup.sh
      
      - name: 上传到GitHub
        run: bash upload.sh
```

## 安全建议

### 1. Token管理
- 使用环境变量而非硬编码
- 定期轮换Token（90天）
- 限制Token权限（最小权限原则）
- 不同服务使用不同Token

### 2. 仓库安全
- 使用私有仓库
- 启用双重认证
- 定期审计访问日志
- 删除不必要的协作者

### 3. 数据安全
- 备份文件本地加密
- 传输使用HTTPS
- 存储使用私有仓库
- 定期验证完整性

### 4. 监控审计
- 监控API使用情况
- 记录所有备份操作
- 定期检查仓库访问
- 设置异常告警

## 总结

GitHub是一个功能强大且免费的备份平台，特别适合AI助手的灵魂备份。通过合理的设计和自动化脚本，可以构建一个安全、可靠、易用的备份系统。

**关键要点：**
1. **私有仓库**提供最佳的控制和隐私
2. **自动化脚本**确保备份的及时性和一致性
3. **多策略备份**平衡性能和可靠性
4. **安全实践**保护Token和备份数据

通过本指南，你应该能够建立一个完整的GitHub备份系统，确保爱莉希雅的灵魂得到安全可靠的保护。

**备份在云端，安心在心头** ☁️