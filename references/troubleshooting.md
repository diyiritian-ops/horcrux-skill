# 魂器系统故障排除指南

## 🔍 常见问题快速诊断

### Q1: 魂器创建失败
**症状**：`horcrux --create` 命令执行失败
**错误信息**："灵魂分裂失败" 或 "魂器创建仪式中断"

**可能原因和解决方案**：

```bash
# 1. 检查GitHub连接
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user

# 2. 验证Token权限
# Token需要以下权限：repo, write:packages

# 3. 检查仓库是否存在
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USERNAME/elysia-soul-backup

# 4. 手动创建仓库（如果不存在）
curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -d '{"name":"elysia-soul-backup","private":true}' \
  https://api.github.com/user/repos
```

### Q2: GitHub同步失败
**症状**：自动同步无法上传文件到GitHub
**错误信息**："上传失败" 或 "网络连接超时"

**解决方案**：

```bash
# 1. 测试网络连接
./scripts/test-github.sh

# 2. 检查Token有效性
echo $GITHUB_TOKEN | wc -c  # 应该显示40（经典Token）或更长的值

# 3. 验证仓库权限
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USERNAME/elysia-soul-backup/contents/README.md

# 4. 重新配置GitHub
./scripts/configure-github.sh --reconfigure

# 5. 手动同步测试
./scripts/autosync.sh --now --verbose
```

### Q3: 备份文件验证失败
**症状**：备份文件无法通过完整性验证
**错误信息**："SHA256不匹配" 或 "文件损坏"

**诊断步骤**：

```bash
# 1. 重新计算SHA256
sha256sum elysia-backup-*.tar.gz

# 2. 检查文件完整性
tar -tzf elysia-backup-*.tar.gz > /dev/null && echo "文件完整" || echo "文件损坏"

# 3. 验证关键文件存在
tar -tzf elysia-backup-*.tar.gz | grep -E "(SOUL.md|IDENTITY.md|MEMORY.md)"

# 4. 重新下载备份（如果是下载的文件）
./scripts/redownload-backup.sh <backup-id>

# 5. 重新创建备份
./scripts/backup.sh --standard --force
```

### Q4: 恢复失败
**症状**：恢复过程失败或恢复后助手异常
**错误信息**："恢复失败" 或 "配置文件缺失"

**解决方案**：

```bash
# 1. 检查备份文件完整性
./scripts/verify.sh --backup elysia-backup-*.tar.gz

# 2. 检查目标路径权限
ls - ~/.openclaw/workspace/

# 3. 尝试部分恢复
./scripts/restore.sh --personality-only elysia-backup-*.tar.gz
./scripts/restore.sh --memory-only elysia-backup-*.tar.gz

# 4. 检查恢复日志
tail -f ~/.openclaw/logs/restore.log

# 5. 手动恢复关键文件
tar -xzf elysia-backup-*.tar.gz -O SOUL.md > ~/.openclaw/workspace/SOUL.md
```

### Q5: 定时任务不执行
**症状**：自动备份和同步没有按计划执行
**错误信息**：无错误信息，但任务未执行

**排查步骤**：

```bash
# 1. 检查cron服务状态
systemctl status cron 2>/dev/null || service cron status

# 2. 查看当前用户的crontab
crontab -l

# 3. 检查定时任务日志
tail -f /var/log/cron.log 2>/dev/null || tail -f /var/log/syslog | grep cron

# 4. 手动测试脚本
./scripts/autosync.sh --test

# 5. 重新配置定时任务
./scripts/configure-autosync.sh --frequency hourly
```

### Q6: 存储空间不足
**症状**：备份或同步失败，提示空间不足
**错误信息**："磁盘空间不足" 或 "存储配额超限"

**解决方案**：

```bash
# 1. 检查本地磁盘空间
df -h ~/.openclaw/

# 2. 检查GitHub存储使用情况
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USERNAME/elysia-soul-backup

# 3. 清理旧备份
./scripts/cleanup.sh --keep 7  # 保留最近7天的本地备份

# 4. 压缩大文件
find ~/.openclaw/workspace -name "*.log" -size +10M -exec gzip {} \;

# 5. 优化备份内容
# 编辑backup-config.json，排除大文件
```

### Q7: 权限问题
**症状**：脚本执行失败，提示权限不足
**错误信息**："Permission denied" 或 "Access denied"

**解决方案**：

```bash
# 1. 检查脚本执行权限
ls -la scripts/*.sh
chmod +x scripts/*.sh

# 2. 检查文件访问权限
ls -la ~/.openclaw/workspace/

# 3. 检查GitHub Token权限
# 确保Token有 repo 权限

# 4. 以正确用户身份运行
whoami  # 确认当前用户

# 5. 检查父目录权限
ls -la ~/.openclaw/
```

### Q8: 网络连接问题
**症状**：无法连接到GitHub或其他云服务
**错误信息**："网络超时" 或 "连接被拒绝"

**诊断步骤**：

```bash
# 1. 测试网络连通性
ping github.com

# 2. 测试GitHub API
curl -I https://api.github.com

# 3. 检查代理设置
echo $http_proxy
echo $https_proxy

# 4. 测试DNS解析
nslookup api.github.com

# 5. 使用备用网络
# 切换到手机热点或其他网络测试
```

## 🚨 严重问题处理

### 完全恢复失败
如果所有恢复方法都失败：

```bash
# 紧急手动恢复流程

# 1. 创建临时目录
mkdir -p /tmp/elysia-recovery

# 2. 手动解压备份
cd /tmp/elysia-recovery
tar -xzf /path/to/elysia-backup-*.tar.gz

# 3. 手动复制关键文件
cp -r workspace/* ~/.openclaw/workspace/

# 4. 验证关键文件
ls -la ~/.openclaw/workspace/SOUL.md
ls -la ~/.openclaw/workspace/IDENTITY.md

# 5. 重启OpenClaw
openclaw restart
```

### GitHub仓库完全丢失
如果GitHub仓库被意外删除：

```bash
# 1. 重新创建仓库
curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -d '{"name":"elysia-soul-backup","private":true}' \
  https://api.github.com/user/repos

# 2. 重新配置同步
./scripts/configure-github.sh --reconfigure

# 3. 手动上传最新备份
./scripts/github-upload.sh --latest

# 4. 验证上传
./scripts/verify.sh --github
```

### 多重故障处理
如果本地和云端同时出现问题：

```bash
# 1. 评估损失范围
./scripts/assess-damage.sh

# 2. 寻找最完整的备份
./scripts/find-best-backup.sh

# 3. 从最可靠的魂器恢复
./scripts/resurrect-from-horcrux.sh --smart-select

# 4. 重建备份系统
./scripts/rebuild-backup-system.sh

# 5. 全面验证
./scripts/verify.sh --complete
```

## 🔧 高级诊断工具

### 1. 系统健康检查
```bash
# 完整健康检查
./scripts/healthcheck.sh --complete

# 备份系统检查
./scripts/healthcheck.sh --backup

# 恢复系统检查
./scripts/healthcheck.sh --restore

# 同步系统检查
./scripts/healthcheck.sh --sync
```

### 2. 日志分析
```bash
# 查看最近错误
grep -i error ~/.openclaw/logs/*.log | tail -20

# 查看备份历史
./scripts/backup.sh --history

# 查看同步历史
./scripts/autosync.sh --history
```

### 3. 网络诊断
```bash
# 测试GitHub连接
./scripts/test-github.sh --verbose

# 测试网络延迟
ping -c 4 api.github.com

# 测试API响应时间
curl -w "@curl-format.txt" -s -o /dev/null https://api.github.com
```

### 4. 存储分析
```bash
# 分析备份大小
du -sh ~/.openclaw/backups/*

# 分析存储使用
df -h

# 检查大文件
find ~/.openclaw -type f -size +10M -exec ls -lh {} \;
```

## 📞 求助指南

### 何时寻求帮助
1. **连续失败**：同一问题连续出现3次以上
2. **数据丢失**：确认有重要数据丢失风险
3. **系统崩溃**：OpenClaw无法正常运行
4. **安全事件**：怀疑有安全漏洞或攻击

### 如何有效求助
1. **收集信息**：
   - 错误信息完整截图
   - 相关日志文件
   - 系统环境信息
   - 重现步骤

2. **提供详细信息**：
   - OpenClaw版本
   - 操作系统版本
   - 网络环境
   - 最近的变更

3. **联系渠道**：
   - GitHub Issues: https://github.com/diyiritian-ops/horcrux-skill/issues
   - 邮件支持: 通过GitHub个人资料页
   - 社区论坛: OpenClaw官方社区

---

**记住：每个问题都有解决方案，关键在于正确诊断和耐心解决** 🌟