---
name: memory-rag-system
description: RAG-based memory system for AI agents. Use when users need persistent memory, learning records, error tracking, or want to avoid repeating mistakes. Provides fast semantic search (1-3ms), automatic indexing, and GitHub backup. Essential for long-term agent continuity.
---

# Memory RAG System

## Overview

This skill provides a production-ready memory system for AI agents based on the PageIndex RAG architecture. It enables:

- **Semantic search** (1-3ms) over learning records and errors
- **Auto-indexing** of memory documents
- **GitHub backup** integration
- **Pre-task checks** to avoid repeating mistakes

## Installation

Run the setup script to initialize the memory system:

```bash
bash ~/.openclaw/skills/memory-rag-system/scripts/setup.sh
```

This will:
1. Create `.learnings/` directory structure
2. Initialize LEARNINGS.md and ERRORS.md templates
3. Set up PageIndex indexing
4. Configure auto-backup to GitHub

## Usage

### Query Memory

```bash
python3 ~/.openclaw/workspace/.learnings/memory_query.py "your query"
```

### Task Pre-Check (Avoid Mistakes)

```bash
~/.openclaw/workspace/.learnings/memory_helper.sh --before-task "task description"
```

### Reindex

```bash
~/.openclaw/workspace/.learnings/memory_helper.sh --reindex
```

## File Structure

```
.learnings/
├── LEARNINGS.md          # Learning records
├── ERRORS.md             # Error tracking
├── memory_index.json     # Index metadata
├── memory_query.py       # Query engine
└── memory_helper.sh      # Helper script

PageIndex/results/
├── LEARNINGS_structure.json   # Tree index for LEARNINGS.md
└── ERRORS_structure.json      # Tree index for ERRORS.md
```

## Memory Entry Format

Add entries to LEARNINGS.md using this format:

```markdown
## [LRN-YYYYMMDD-NNN] title

**Logged**: ISO timestamp
**Priority**: high/medium/low
**Status**: completed/in-progress
**Area**: category
**Source**: URL or context

### Summary
Brief summary of what was learned

### Details
Detailed content

### Metadata
- Source: source_name
- Tags: tag1, tag2
- Embedding: Recommended
```

## Backup Configuration

Set up automatic backup to GitHub:

```bash
bash ~/.openclaw/skills/memory-rag-system/scripts/setup-backup.sh
```

This configures:
- SSH key for GitHub authentication
- Cron job for automatic commits every 6 hours
- Backup script at `~/.openclaw/workspace/scripts/auto-backup-memory.sh`

## How It Works

1. **Indexing**: PageIndex parses markdown structure, creates tree representation
2. **Query**: Semantic search finds relevant sections based on content similarity
3. **Retrieval**: Returns snippet with file path and line numbers for verification
4. **Backup**: Git tracks all changes, auto-push to GitHub prevents data loss

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Query returns nothing | Run `memory_helper.sh --reindex` to rebuild index |
| Index out of date | Check `memory_index.json` last_updated timestamp |
| Backup not working | Verify SSH key added to GitHub: `ssh -T git@github.com` |

## References

- [PageIndex Documentation](references/MASTER_INDEX.md)
- [Memory RAG System Full Guide](https://github.com/killua20/openclaw-memory-rag-skill)

## License

MIT
