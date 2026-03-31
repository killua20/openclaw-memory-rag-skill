#!/bin/bash
# Memory RAG System Setup Script
# 初始化记忆系统

set -e

echo "🧠 Memory RAG System Setup"
echo "=========================="
echo ""

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
LEARNINGS_DIR="$WORKSPACE_DIR/.learnings"
PAGEINDEX_DIR="$WORKSPACE_DIR/PageIndex"

echo "📁 Step 1: Creating directory structure..."
mkdir -p "$LEARNINGS_DIR"
mkdir -p "$PAGEINDEX_DIR/results"
echo "✅ Directories created"
echo ""

# Create LEARNINGS.md template if not exists
echo "📝 Step 2: Initializing memory documents..."
if [ ! -f "$LEARNINGS_DIR/LEARNINGS.md" ]; then
    cat > "$LEARNINGS_DIR/LEARNINGS.md" << 'EOF'
# 学习记录 (Learnings)

持续改进的学习记录。

> 📌 **快速导航**：详见 [.learnings/MASTER_INDEX.md](./MASTER_INDEX.md) - 所有学习资料统一索引
> 
> 🧠 **记忆系统**: 使用 PageIndex RAG 快速检索，无需加载完整 MD 文件

---

EOF
    echo "✅ LEARNINGS.md created"
else
    echo "⚠️  LEARNINGS.md already exists, skipping"
fi

# Create ERRORS.md template if not exists
if [ ! -f "$LEARNINGS_DIR/ERRORS.md" ]; then
    cat > "$LEARNINGS_DIR/ERRORS.md" << 'EOF'
# 错误记录 (Errors)

记录踩过的坑和解决方案。

---

EOF
    echo "✅ ERRORS.md created"
else
    echo "⚠️  ERRORS.md already exists, skipping"
fi

# Create memory_index.json if not exists
echo "📇 Step 3: Initializing index..."
if [ ! -f "$LEARNINGS_DIR/memory_index.json" ]; then
    cat > "$LEARNINGS_DIR/memory_index.json" << 'EOF'
{
  "version": "1.0",
  "created_at": "",
  "last_updated": "",
  "documents": [
    {
      "name": "LEARNINGS.md",
      "path": ".learnings/LEARNINGS.md",
      "indexed": false,
      "last_modified": ""
    },
    {
      "name": "ERRORS.md",
      "path": ".learnings/ERRORS.md",
      "indexed": false,
      "last_modified": ""
    }
  ]
}
EOF
    echo "✅ memory_index.json created"
else
    echo "⚠️  memory_index.json already exists, skipping"
fi

echo ""
echo "=========================="
echo "✅ Memory RAG System initialized!"
echo ""
echo "📍 Location: $LEARNINGS_DIR"
echo ""
echo "Next steps:"
echo "  1. Run indexing: ~/.openclaw/workspace/.learnings/memory_helper.sh --reindex"
echo "  2. Query memory: python3 ~/.openclaw/workspace/.learnings/memory_query.py 'your query'"
echo "  3. Setup backup: bash ~/.openclaw/workspace/skills/memory-rag-system/scripts/setup-backup.sh"
echo ""
