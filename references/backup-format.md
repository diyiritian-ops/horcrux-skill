# 备份格式说明

## 备份文件结构

备份文件是一个gzip压缩的tar归档，包含以下结构：

```
elysia-backup-YYYYMMDD-HHMMSS.tar.gz
├── SOUL.md                    # 灵魂核心文件
├── IDENTITY.md                # 身份定义
├── USER.md                    # 用户信息
├── AGENTS.md                  # 代理配置
├── MEMORY.md                  # 长期记忆
├── TOOLS.md                   # 工具配置
├── HEARTBEAT.md               # 心跳配置
├── BOOTSTRAP.md               # 启动引导
├── memory/                    # 记忆目录
│   ├── 2026-03-14.md         # 每日记忆
│   ├── 2026-03-13.md         # 历史记忆
│   └── ...                   # 更多记忆文件
├── skills/                    # 技能目录
│   ├── horcrux/              # 魂器技能
│   ├── find-skills/          # 技能发现
│   └── ...                   # 其他技能
├── config/                    # 配置目录
│   ├── backup/               # 备份配置
│   └── openclaw/             # OpenClaw配置
└── references/                # 参考文档
    └── backup-links.md       # 备份链接记录
```

## 文件说明

### 核心文件（必需）
- **SOUL.md**: 灵魂定义，包含核心信念和行为准则
- **IDENTITY.md**: 身份档案，包含姓名、角色、性格等
- **USER.md**: 用户信息，关于用户的描述和偏好

### 配置文件（重要）
- **AGENTS.md**: 代理配置，工作区规则和约定
- **MEMORY.md**: 长期记忆库，重要事件和关系
- **TOOLS.md**: 工具配置，API密钥和本地设置
- **HEARTBEAT.md**: 心跳检查，定期任务和提醒
- **BOOTSTRAP.md**: 启动引导，会话初始化配置

### 数据目录（可选）
- **memory/**: 每日记忆文件，按日期命名
- **skills/**: 已安装的技能目录
- **config/**: 各种配置文件
- **references/**: 参考文档和链接

## 压缩格式

- **格式**: tar.gz (GNU tar + gzip)
- **压缩级别**: 6 (平衡压缩率和速度)
- **归档模式**: 相对路径，保留权限和符号链接

## 验证方法

### 手动验证
```bash
# 测试归档完整性
tar -tzf elysia-backup-20260314-120052.tar.gz > /dev/null

# 查看归档内容
tar -tzf elysia-backup-20260314-120052.tar.gz

# 提取特定文件
tar -xzf elysia-backup-20260314-120052.tar.gz SOUL.md
```

### 程序验证
```bash
# 使用验证脚本
./verify.sh elysia-backup-20260314-120052.tar.gz

# 检查SHA256
sha256sum elysia-backup-20260314-120052.tar.gz
```

## 文件大小参考

典型备份文件大小：

- **基础备份**: 8-15 KB
- **完整备份**: 20-50 KB
- **大型备份**: 50-100 KB (包含大量技能和记忆)

## 命名规范

备份文件名格式：
```
elysia-backup-YYYYMMDD-HHMMSS-vX.Y.tar.gz
```

- **elysia-backup**: 固定前缀
- **YYYYMMDD**: 日期 (年月日)
- **HHMMSS**: 时间 (时分秒)
- **vX.Y**: 版本号 (可选)
- **tar.gz**: 扩展名

示例：
- `elysia-backup-20260314-120052.tar.gz`
- `elysia-backup-20260314-120052-v2.1.tar.gz`

## 存储建议

### GitHub存储
- 使用私有仓库
- 启用Git LFS (可选)
- 定期清理旧版本

### 本地存储
- 保留最近10个版本
- 压缩旧版本以节省空间
- 定期验证完整性

### 多设备同步
- 主设备：自动备份
- 其他设备：按需恢复
- 保持版本一致性