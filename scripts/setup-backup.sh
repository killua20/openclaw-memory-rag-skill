#!/bin/bash
# Setup automatic GitHub backup for memory system

set -e

echo "🔄 Memory System Backup Setup"
echo "=============================="
echo ""

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/.openclaw/workspace}"

echo "🔑 Step 1: Check SSH key..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -C "memory-backup" -f ~/.ssh/id_ed25519 -N ""
    echo "✅ SSH key generated"
else
    echo "✅ SSH key exists"
fi

echo ""
echo "📋 Step 2: Add SSH key to GitHub"
echo ""
echo "Please add this public key to GitHub:"
echo "👉 https://github.com/settings/keys"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat ~/.ssh/id_ed25519.pub
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Press Enter after adding the key to GitHub..."

echo ""
echo "🔗 Step 3: Test SSH connection..."
ssh -T -o StrictHostKeyChecking=no git@github.com 2>&1 | head -5 || true

echo ""
echo "⚙️  Step 4: Configure git remote..."
cd "$WORKSPACE_DIR"
# Check if origin is HTTPS, switch to SSH if needed
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$CURRENT_REMOTE" == https://* ]]; then
    # Extract repo path from HTTPS URL
    REPO_PATH=$(echo "$CURRENT_REMOTE" | sed 's|https://github.com/||' | sed 's|\.git$||')
    git remote set-url origin "git@github.com:$REPO_PATH.git"
    echo "✅ Remote updated to SSH"
else
    echo "✅ Remote already using SSH or not configured"
fi

echo ""
echo "📝 Step 5: Create auto-backup script..."
BACKUP_SCRIPT="$WORKSPACE_DIR/scripts/auto-backup-memory.sh"
mkdir -p "$WORKSPACE_DIR/scripts"

cat > "$BACKUP_SCRIPT" << 'EOF'
#!/bin/bash
# Auto backup memory system to GitHub

cd "$HOME/.openclaw/workspace"

# Check if there are changes
if git status --porcelain | grep -qE "\.learnings/|memory"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Changes detected, backing up..."
    
    git add .learnings/
    git commit -m "auto: memory backup $(date '+%Y-%m-%d %H:%M:%S')"
    
    if git push; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup successful"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup failed"
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - No changes to backup"
fi
EOF

chmod +x "$BACKUP_SCRIPT"
echo "✅ Backup script created at $BACKUP_SCRIPT"

echo ""
echo "⏰ Step 6: Setup cron job..."
if crontab -l 2>/dev/null | grep -q "auto-backup-memory.sh"; then
    echo "⚠️  Cron job already exists"
else
    # Backup every 6 hours
    (crontab -l 2>/dev/null; echo "0 */6 * * * $BACKUP_SCRIPT >> /tmp/memory-backup.log 2>&1") | crontab -
    echo "✅ Cron job added (every 6 hours)"
fi

echo ""
echo "=============================="
echo "✅ Backup setup complete!"
echo ""
echo "📅 Backup schedule: Every 6 hours"
echo "📝 Log file: /tmp/memory-backup.log"
echo ""
echo "To test backup manually:"
echo "  bash $BACKUP_SCRIPT"
echo ""
