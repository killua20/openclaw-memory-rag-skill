# Memory RAG System

基于 PageIndex 的 RAG 记忆系统，为 AI Agent 提供持久化记忆能力。

## 特性

- ⚡ **毫秒级检索** - 1-3ms 查询速度
- 🧠 **语义搜索** - 基于内容相似度而非关键词
- 🔄 **自动索引** - 文档变更后自动重建索引
- 💾 **GitHub 备份** - 自动备份到 GitHub 防止数据丢失
- 🛡️ **任务前检查** - 执行任务前自动查询相关记忆，避免重复踩坑

## 快速开始

### 1. 安装

```bash
bash ~/.openclaw/skills/memory-rag-system/scripts/setup.sh
```

### 2. 配置备份（可选但推荐）

```bash
bash ~/.openclaw/skills/memory-rag-system/scripts/setup-backup.sh
```

### 3. 使用

```bash
# 查询记忆
python3 ~/.openclaw/workspace/.learnings/memory_query.py "飞书配置"

# 任务前检查
~/.openclaw/workspace/.learnings/memory_helper.sh --before-task "配置 Telegram Bot"

# 重新索引
~/.openclaw/workspace/.learnings/memory_helper.sh --reindex
```

## 文件结构

```
.learnings/
├── LEARNINGS.md          # 学习记录
├── ERRORS.md             # 错误记录
├── memory_index.json     # 索引元数据
├── memory_query.py       # 查询引擎
└── memory_helper.sh      # 便捷脚本

PageIndex/results/
├── LEARNINGS_structure.json   # 学习记录树索引
└── ERRORS_structure.json      # 错误记录树索引
```

## 添加到学习记录

使用以下格式：

```markdown
## [LRN-YYYYMMDD-NNN] title

**Logged**: ISO timestamp
**Priority**: high/medium/low
**Status**: completed/in-progress
**Area**: category
**Source**: URL or context

### Summary
Brief summary

### Details
Detailed content

### Metadata
- Source: source_name
- Tags: tag1, tag2
```

## 自动备份

备份脚本会每 6 小时自动检查并提交变更到 GitHub。

手动触发备份：
```bash
bash ~/.openclaw/workspace/scripts/auto-backup-memory.sh
```

查看备份日志：
```bash
tail -f /tmp/memory-backup.log
```

## License

MIT
