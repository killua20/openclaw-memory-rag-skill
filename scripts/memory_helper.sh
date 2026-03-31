#!/bin/bash
# Memory Helper - 记忆检索助手
# 在执行任务前查询相关记忆，避免重复踩坑
#
# Usage:
#   memory_helper.sh <query>          # 查询记忆
#   memory_helper.sh --before-task    # 在执行任务前自动查询
#   memory_helper.sh --reindex        # 重新索引记忆文档

# 自动检测工作目录
if [ -d "$HOME/.openclaw/workspace/.learnings" ]; then
    MEMORY_DIR="$HOME/.openclaw/workspace/.learnings"
    PAGEINDEX_DIR="$HOME/.openclaw/workspace/PageIndex"
elif [ -d "$WORKSPACE_DIR/.learnings" ]; then
    MEMORY_DIR="$WORKSPACE_DIR/.learnings"
    PAGEINDEX_DIR="$WORKSPACE_DIR/PageIndex"
else
    # 默认路径
    MEMORY_DIR="${WORKSPACE_DIR:-$HOME/.openclaw/workspace}/.learnings"
    PAGEINDEX_DIR="${WORKSPACE_DIR:-$HOME/.openclaw/workspace}/PageIndex"
fi

cd "$MEMORY_DIR" || exit 1

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助
show_help() {
    cat << EOF
Memory Helper - 记忆检索助手

Usage:
  memory_helper.sh <query> [options]
  memory_helper.sh --reindex
  memory_helper.sh --stats
  memory_helper.sh --before-task "<task description>"

Options:
  --top-k N       返回前 N 个结果 (默认: 3)
  --reindex       重新生成记忆文档的树索引
  --stats         显示记忆库统计
  --before-task   在执行任务前查询相关记忆
  -h, --help      显示帮助

Examples:
  memory_helper.sh "飞书配置"
  memory_helper.sh "Telegram 报错" --top-k 5
  memory_helper.sh --before-task "配置飞书 webhook"
  memory_helper.sh --reindex

EOF
}

# 重新索引
reindex() {
    echo -e "${BLUE}🔄 重新索引记忆文档...${NC}"
    cd "$PAGEINDEX_DIR" || exit 1
    source venv/bin/activate
    
    # 索引 LEARNINGS.md
    echo -e "${BLUE}  📄 索引 LEARNINGS.md${NC}"
    python3 run_pageindex.py --md_path "$MEMORY_DIR/LEARNINGS.md" > /dev/null 2>&1
    
    # 索引 ERRORS.md
    echo -e "${BLUE}  📄 索引 ERRORS.md${NC}"
    python3 run_pageindex.py --md_path "$MEMORY_DIR/ERRORS.md" > /dev/null 2>&1
    
    # 更新索引时间
    python3 -c "
import json
from datetime import datetime
with open('$MEMORY_DIR/memory_index.json', 'r') as f:
    data = json.load(f)
data['last_updated'] = datetime.now().isoformat()
with open('$MEMORY_DIR/memory_index.json', 'w') as f:
    json.dump(data, f, indent=2)
"
    
    echo -e "${GREEN}✅ 索引完成${NC}"
}

# 查询记忆
query_memory() {
    local query="$1"
    shift
    local top_k="3"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --top-k)
                top_k="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    echo -e "${BLUE}🔍 查询记忆: \"$query\"${NC}"
    python3 "$MEMORY_DIR/memory_query.py" "$query" --top-k "$top_k"
}

# 任务前检查
before_task() {
    local task="$1"
    
    echo -e "${YELLOW}⚠️  执行任务前检查记忆库...${NC}"
    echo -e "${BLUE}📝 任务描述: $task${NC}"
    echo ""
    
    # 提取关键词并查询
    query_memory "$task" --top-k 3
    
    echo ""
    echo -e "${GREEN}✅ 记忆检查完成。如果上方有相关记录，建议先查看避免重复踩坑。${NC}"
}

# 主逻辑
case "${1:-}" in
    -h|--help)
        show_help
        ;;
    --reindex)
        reindex
        ;;
    --stats)
        python3 "$MEMORY_DIR/memory_query.py" --stats
        ;;
    --before-task)
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}❌ 请提供任务描述${NC}"
            exit 1
        fi
        before_task "$2"
        ;;
    "")
        show_help
        exit 1
        ;;
    *)
        query_memory "$@"
        ;;
esac
