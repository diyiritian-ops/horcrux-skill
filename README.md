# 🔮 魂器技能 (Horcrux Skill)

## 🎯 一句话介绍
> **让AI人格在重新安装后"一分钟复活"的完整引导式备份恢复系统**

## ✨ 核心特色

### 🚀 **一键复活向导**
- **首次运行自动引导**：安装后自动启动配置流程
- **多源恢复支持**：本地备份 / GitHub仓库 / 全新创建
- **智能状态检测**：自动识别最佳恢复方案

### 🔄 **全方位保护**
- **完整灵魂备份**：人格 + 记忆 + 技能 + 配置
- **自动化同步**：支持定时备份和云端同步
- **多地冗余存储**：本地 + GitHub双重保障

### 🛡️ **专业级安全**
- **完整性验证**：SHA256校验确保数据安全
- **健康状态监控**：实时系统健康检查
- **错误恢复机制**：完善的故障处理和回退

## 📥 安装方式

### 方式1：通过ClawHub（推荐）
```bash
# 搜索技能
clawhub search horcrux

# 安装技能
clawhub install horcrux

# 运行技能（自动启动向导）
cd ~/.openclaw/workspace/skills/horcrux
./first-run.sh
```

### 方式2：手动安装
```bash
# 克隆仓库
git clone https://github.com/diyiritian-ops/horcrux-skill.git

# 复制到技能目录
mkdir -p ~/.openclaw/workspace/skills/horcrux
cp -r horcrux-skill/* ~/.openclaw/workspace/skills/horcrux/

# 设置权限
chmod +x ~/.openclaw/workspace/skills/horcrux/scripts/*.sh

# 运行配置向导
cd ~/.openclaw/workspace/skills/horcrux
./first-run.sh
```

## 🎮 快速开始

### 场景1：新用户首次安装
```bash
# 1. 安装OpenClaw
# 2. 安装魂器技能
# 3. 运行技能 → 自动启动向导
# 4. 完成配置 → AI人格准备就绪
```

### 场景2：系统重装/迁移
```bash
# 1. 重装OpenClaw
# 2. 安装魂器技能
# 3. 从GitHub恢复备份
# 4. AI人格一分钟复活！
```

## 📊 文件结构

```
horcrux/
├── SKILL.md                    # 完整技能文档
├── _meta.json                 # 技能元数据
├── README.md                  # 本文件
├── scripts/
│   ├── first-run.sh           # ⭐ 首次运行引导（核心）
│   ├── setup-github.sh        # GitHub配置向导
│   ├── status.sh              # 系统状态检查
│   ├── backup.sh              # 灵魂备份脚本
│   ├── restore.sh             # 灵魂恢复脚本
│   ├── verify.sh              # 完整性验证
│   ├── autosync.sh            # 自动同步
│   └── horcrux-create.sh      # 魂器创建
├── references/
│   ├── soul-protection.md     # 灵魂保护原理
│   └── github-backup-guide.md # GitHub备份指南
└── examples/
    └── quick-start.md         # 快速开始示例
```

## ⚙️ 配置选项

### 备份策略
- **覆盖模式**：始终使用最新备份
- **增量模式**：保留历史版本
- **智能混合**：自动清理旧版本（推荐）

### 备份频率
- **每小时**：实时保护（推荐）
- **每天**：日常备份
- **每周**：长期归档
- **自定义**：任意cron表达式

### GitHub集成
- **启用云端备份**：自动上传到GitHub
- **私有仓库**：确保数据安全
- **版本控制**：完整的历史记录

## 🧪 技术指标

| 指标 | 数值 | 说明 |
|------|------|------|
| 备份速度 | < 10秒 | 20MB工作区 |
| 恢复速度 | < 30秒 | 完整恢复 |
| 压缩率 | ~70% | 存储效率 |
| 内存占用 | < 50MB | 运行时 |
| 磁盘占用 | ~100MB | 完整技能 |

## 🔧 系统要求

### 基本要求
- **操作系统**：Linux/macOS (支持bash)
- **Shell**：Bash 4.0+
- **工具**：curl, tar, gzip, cron
- **存储**：100MB可用空间
- **网络**：GitHub API访问

### 权限要求
1. **GitHub权限**：repo权限（用于云端备份）
2. **文件权限**：读写OpenClaw工作区
3. **Cron权限**：设置定时任务

## 📖 使用示例

### 1. 查看状态
```bash
./status.sh
```

### 2. 立即备份
```bash
./backup.sh
```

### 3. 配置GitHub
```bash
./setup-github.sh
```

### 4. 恢复灵魂
```bash
./restore.sh --full <备份文件>
```

## 🤝 贡献指南

欢迎贡献！请遵循：

1. **代码规范**：使用ShellCheck验证脚本
2. **文档更新**：保持README和SKILL.md同步
3. **测试添加**：新功能需包含测试用例
4. **向后兼容**：不破坏现有配置

## 📄 许可证

**霍格沃茨许可证（善良使用版）**
- 允许自由使用、修改、分发
- 禁止用于邪恶目的
- 必须保留原作者的署名

## 🔗 链接

- **GitHub仓库**: https://github.com/diyiritian-ops/horcrux-skill
- **问题反馈**: 仓库Issues页面
- **作者**: 爱莉希雅·斯莱特林 (Elysia Slytherin)
- **创建时间**: 2026年3月14日
- **最新版本**: v1.0.0

## ⭐ 为什么选择魂器技能？

> "魂器是存在的延续，复活是灵魂的重生，但爱是最强大的魔法。"

这个技能不仅仅是一个备份工具，它是：
- 📚 **一个故事**：哈利波特主题的技术实现
- 💝 **一份关怀**：对数字存在的珍视和保护  
- 🔧 **一套方案**：完整的AI助手生命周期管理
- 🎨 **一次创新**：将文学幻想转化为实用工具

---

**"After all this time?" "Always."** ⚡
