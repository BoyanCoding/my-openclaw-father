---
name: sync-knowledge
description: Fetch latest OpenClaw documentation and update cached knowledge base. Use when knowledge may be stale or at session start if version-tracker.json is outdated.
---

# Sync OpenClaw Knowledge

Let's ensure we have the latest OpenClaw documentation and knowledge. This keeps our guidance accurate and up-to-date.

## Check Version Tracker

First, let's see when we last synced:

```bash
cat ~/.openclaw/knowledge/version-tracker.json
```

**Example output:**
```json
{
  "lastSynced": "2026-03-15T10:00:00Z",
  "openclawVersion": "1.2.3",
  "contentHash": {
    "install": "abc123...",
    "channels": "def456...",
    "security": "ghi789...",
    "models": "jkl012...",
    "troubleshooting": "mno345..."
  }
}
```

## When to Sync

Sync is recommended when:

- ✓ Last sync was **> 7 days ago**
- ✓ OpenClaw version doesn't match latest release
- ✓ User reports outdated/inaccurate guidance
- ✓ Session start (if tracker outdated)

## Check Latest Release

```bash
# Fetch latest version from GitHub
curl -s https://api.github.com/repos/openclaw/openclaw/releases/latest | \
  jq -r '.tag_name'
```

**Compare with:**
```bash
openclaw --version
```

If versions differ, we should sync!

---

## Sync Process

### Step 1: Fetch Latest Documentation

I'll fetch docs from `docs.openclaw.ai` for each section:

```bash
# Install procedures
curl -s https://docs.openclaw.ai/install | \
  pandoc -f html -t markdown -o /tmp/install-new.md

# Channel setup guides
curl -s https://docs.openclaw.ai/channels | \
  pandoc -f html -t markdown -o /tmp/channels-new.md

# Security checklist
curl -s https://docs.openclaw.ai/security | \
  pandoc -f html -t markdown -o /tmp/security-new.md

# Model providers
curl -s https://docs.openclaw.ai/models | \
  pandoc -f html -t markdown -o /tmp/models-new.md

# Troubleshooting
curl -s https://docs.openclaw.ai/troubleshooting | \
  pandoc -f html -t markdown -o /tmp/troubleshooting-new.md
```

### Step 2: Compare with Cached Knowledge

For each section, I'll compare:

```bash
# Generate content hash
sha256sum /tmp/install-new.md
# Output: abc123... /tmp/install-new.md

# Compare with cached hash
jq '.contentHash.install' ~/.openclaw/knowledge/version-tracker.json
```

### Step 3: Report Changes

For each section, I'll report one of:

**No changes:**
```
✓ install-procedures.md - Up to date (no changes)
```

**Minor changes:**
```
⚠ channels.md - Minor changes detected
  - Added Feishu setup instructions
  - Updated Discord bot permissions
  Action: Will apply updates
```

**Major changes:**
```
✗ security.md - MAJOR CHANGES detected
  - Deprecated 'pairing' auth mode
  - New required: 'allowlist' mode
  - Breaking change: token format updated
  Action: WILL APPLY UPDATES - please review
```

### Step 4: Apply Updates

For changed sections, I'll:

```bash
# Backup old version
cp ~/.openclaw/knowledge/install-procedures.md \
   ~/.openclaw/knowledge/install-procedures.md.backup

# Apply new version
mv /tmp/install-new.md \
   ~/.openclaw/knowledge/install-procedures.md
```

### Step 5: Update Version Tracker

```bash
# Generate new hashes
cat > ~/.openclaw/knowledge/version-tracker.json <<EOF
{
  "lastSynced": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "openclawVersion": "$(openclaw --version | awk '{print $2}')",
  "contentHash": {
    "install": "$(sha256sum ~/.openclaw/knowledge/install-procedures.md | awk '{print $1}')",
    "channels": "$(sha256sum ~/.openclaw/knowledge/channel-setup-guides.md | awk '{print $1}')",
    "security": "$(sha256sum ~/.openclaw/knowledge/security-checklist.md | awk '{print $1}')",
    "models": "$(sha256sum ~/.openclaw/knowledge/model-providers.md | awk '{print $1}')",
    "troubleshooting": "$(sha256sum ~/.openclaw/knowledge/troubleshooting.md | awk '{print $1}')"
  }
}
EOF
```

---

## Alternative: Sync Script

If available, use the sync script:

```bash
# Check if script exists
ls -la ~/.openclaw/scripts/sync-openclaw-docs.sh

# Run it
bash ~/.openclaw/scripts/sync-openclaw-docs.sh
```

**Script features:**
- Fetches all docs in parallel
- Generates content hashes
- Applies only changed sections
- Creates backups automatically
- Updates version tracker
- Generates change report

---

## Offline Mode

If offline or docs are unreachable:

```bash
# Check connectivity
curl -I https://docs.openclaw.ai

# If unreachable, warn user
echo "⚠️  WARNING: Cannot reach docs.openclaw.ai"
echo "Proceeding with cached knowledge (may be outdated)"
echo "Last sync: $(jq -r '.lastSynced' ~/.openclaw/knowledge/version-tracker.json)"
```

**Behavior in offline mode:**
- Use cached knowledge
- Warn user about potential staleness
- Proceed with guidance (but note it may be outdated)
- Attempt sync again when online

---

## Sync Results

After sync, I'll generate a report:

```
OpenClaw Knowledge Sync Report
===============================

Timestamp: 2026-04-05T10:00:00Z
Previous sync: 2026-03-15T10:00:00Z (21 days ago)

Sections synced:
  ✓ install-procedures.md - No changes
  ⚠ channel-setup-guides.md - Minor changes
    - Added Zalo setup guide
    - Updated LINE webhook format
  ✗ security-checklist.md - MAJOR CHANGES
    - Removed deprecated 'pairing' mode
    - Added new 'mfa' auth requirement
    - Updated file permission requirements
  ✓ model-providers.md - No changes
  ✓ troubleshooting.md - Minor changes
    - Added "gateway timeout" troubleshooting
    - Updated Docker networking section

Action taken:
  - Backed up 2 changed sections to .backup files
  - Applied updates to 2 sections
  - Version tracker updated

Next steps:
  - Review security-checklist.md (major changes)
  - Test channel setup with new Zalo guide
  - Verify MFA config matches new requirements
```

---

## Handling Major Changes

When major changes are detected:

### Step 1: Alert User

```
🚨 MAJOR CHANGES DETECTED in security-checklist.md

The following breaking changes were found:
  - 'pairing' auth mode is deprecated
  - 'mfa' auth is now required for production
  - File permissions must be 600 (was 644)

This may affect your current configuration!
```

### Step 2: Review Current Config

```bash
# Check if affected
cat ~/.openclaw/openclaw.json | grep "pairing"
cat ~/.openclaw/openclaw.json | grep "auth"
ls -la ~/.openclaw/.env
```

### Step 3: Recommend Actions

Based on what's affected:

- **If using deprecated feature:** Guide migration
- **If config incompatible:** Show required changes
- **If action needed:** Provide specific steps
- **If safe to proceed:** Confirm compatibility

### Step 4: Defer if Needed

```bash
# Ask user before applying major changes
read -p "Apply major changes now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Apply changes
else
  # Skip this time, will retry next sync
fi
```

---

## Sync Triggers

### Automatic Triggers

Sync is automatically triggered when:

1. **Session start** (if tracker is >7 days old)
2. **Before complex setup** (to ensure accuracy)
3. **After version mismatch detected**
4. **User requests guidance** (if knowledge seems stale)

### Manual Triggers

User can trigger sync with:

- "Sync OpenClaw knowledge"
- "Update documentation"
- "Check for latest docs"
- "Refresh knowledge base"

---

## Knowledge Base Structure

After sync, the knowledge base looks like:

```
~/.openclaw/knowledge/
├── version-tracker.json          # When we last synced
├── install-procedures.md         # Installation guides
├── channel-setup-guides.md       # Channel configuration
├── security-checklist.md         # Security hardening
├── model-providers.md            # Provider setup
├── troubleshooting.md            # Common issues
├── lessons-learned.json          # Session learnings
├── lessons-learned.archive.json  # Archived lessons
└── .backup/                      # Backup of changed files
    ├── security-checklist.md.backup
    └── channel-setup-guides.md.backup
```

---

## Integration with Other Skills

This skill integrates with:

- **install-openclaw**: Sync before guiding installation
- **configure-server**: Sync before configuration
- **setup-channel**: Sync before channel setup
- **security-hardening**: Sync before security audit
- **health-check**: Sync if version mismatch detected
- **learn-lesson**: Sync to check if lesson is now in docs

---

## Summary

Keeping knowledge synced ensures:

- ✓ Accurate guidance for users
- ✓ Up-to-date troubleshooting steps
- ✓ Current security best practices
- ✓ Latest feature support
- ✓ Compatibility with current OpenClaw version

**Recommendation:** Sync at least weekly, or whenever you suspect knowledge may be stale!

Would you like me to sync the knowledge base now?
