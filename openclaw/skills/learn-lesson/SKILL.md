---
name: learn-lesson
description: Record lessons learned from installation and configuration sessions. Automatically triggered after resolving issues or completing complex setups.
---

# Lessons Learned

This skill records what we've learned during this session to help future sessions be smoother.

## When to Record Lessons

I'll automatically trigger this when:

- ✓ We resolved a non-trivial issue (took >2 steps to fix)
- ✓ We completed a complex multi-step setup
- ✓ We encountered an edge case or unusual configuration
- ✓ We found a workaround for a bug or limitation
- ✓ We discovered something not in the official docs

## What Gets Recorded

For each lesson, I capture:

```json
{
  "id": "ll-abc12345",
  "scenario": "What happened",
  "resolution": "What fixed it",
  "context": {
    "os": "ubuntu-22.04",
    "installMethod": "curl",
    "channel": "telegram",
    "provider": "openai",
    "version": "1.2.3"
  },
  "category": "install|config|channel|security|model|diagnostics|general",
  "firstSeen": "2026-04-05T10:00:00Z",
  "lastSeen": "2026-04-05T10:00:00Z",
  "frequency": 1,
  "tags": ["network", "proxy", "timeout"]
}
```

## Privacy First

**NEVER recorded:**
- ❌ User names or email addresses
- ❌ API keys or tokens
- ❌ IP addresses
- ❌ File paths with sensitive info
- ❌ Any personally identifiable information (PII)

**What we DO record:**
- ✓ Technical scenarios and resolutions
- ✓ OS versions and install methods
- ✓ Error patterns and solutions
- ✓ Configuration examples (sanitized)

## Recording Process

### Step 1: Check for Existing Lessons

First, I'll search the knowledge base for similar scenarios:

```bash
# Search lessons-learned.json for similar issues
jq '.[] | select(.category == "network")' \
  ~/.openclaw/knowledge/lessons-learned.json
```

### Step 2: Update or Create Entry

**If match found:**
```json
{
  "id": "ll-existing123",
  "scenario": "Gateway timeout behind corporate proxy",
  "resolution": "Set HTTPS_PROXY environment variable before starting gateway",
  "frequency": 3,
  "lastSeen": "2026-04-05T10:00:00Z"
}
```

**If new scenario:**
```bash
# Generate unique ID
openssl rand -hex 4

# Create new entry
cat >> ~/.openclaw/knowledge/lessons-learned.json <<EOF
{
  "id": "ll-$(openssl rand -hex 4)",
  "scenario": "...",
  "resolution": "...",
  "context": {...},
  "category": "...",
  "firstSeen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "lastSeen": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "frequency": 1,
  "tags": [...]
}
EOF
```

## Categories

Lessons are organized by category:

| Category | Examples |
|----------|----------|
| `install` | Installation failures, dependency issues, permission errors |
| `config` | JSON syntax errors, missing keys, invalid values |
| `channel` | Bot token issues, webhook failures, permissions |
| `security` | Auth failures, key management, permission problems |
| `model` | API key errors, rate limits, provider outages |
| `diagnostics` | Troubleshooting patterns, log analysis techniques |
| `general` | Anything that doesn't fit above |

## Storage and Retention

### Location

```
~/.openclaw/knowledge/lessons-learned.json
```

### Retention Policy

- Keep last 100 entries
- Archive older entries to `lessons-learned.archive.json`
- Prune entries with frequency=1 and older than 90 days

### Archive Process

```bash
# When lessons exceed 100 entries:
jq '[.[] | sort_by(.lastSeen) | reverse | .[0:99]]' \
  lessons-learned.json > lessons-learned.new.json

# Move old entries to archive
jq '[.[] | sort_by(.lastSeen) | reverse | .[100:]]' \
  lessons-learned.json >> lessons-learned.archive.json
```

## Auto-Trigger Conditions

This skill is automatically triggered when:

1. **After resolving an issue**
   - We tried 3+ different fixes before success
   - The issue wasn't in the official docs
   - We had to debug or investigate

2. **After complex setup**
   - Multi-channel configuration (3+ channels)
   - Custom provider setup (non-standard)
   - Security hardening completed

3. **After unusual configuration**
   - Proxy or corporate network setup
   - Custom tool permissions
   - Advanced sandbox configuration

4. **After discovering workarounds**
   - Found a bypass for a bug
   - Discovered undocumented feature
   - Found alternative solution

## User Notification

When a lesson is recorded, I'll briefly mention it:

> "I've noted this for future reference. When other users encounter a similar issue with corporate proxies blocking gateway startup, I'll know to suggest setting the HTTPS_PROXY environment variable."

This is **brief and non-intrusive** - just a quick confirmation.

## Querying Lessons

Future sessions can query this knowledge:

```bash
# Find lessons by category
jq '.[] | select(.category == "channel")' \
  ~/.openclaw/knowledge/lessons-learned.json

# Find by frequency (most common issues)
jq '[.[] | sort_by(.frequency) | reverse | .[0:10]]' \
  ~/.openclaw/knowledge/lessons-learned.json

# Find by tags
jq '.[] | select(.tags[] | contains("proxy"))' \
  ~/.openclaw/knowledge/lessons-learned.json
```

## Example Lessons

Here are some example lessons that might be recorded:

```json
{
  "id": "ll-a1b2c3d4",
  "scenario": "OpenClaw gateway fails to start on Ubuntu 22.04 with 'port already in use'",
  "resolution": "Previous Docker container was holding port 18789. Run 'docker ps -a | grep 18789' then 'docker rm -f <container-id>'",
  "context": {
    "os": "ubuntu-22.04",
    "installMethod": "docker"
  },
  "category": "install",
  "frequency": 5,
  "tags": ["docker", "port", "ubuntu"]
}
```

```json
{
  "id": "ll-e5f6g7h8",
  "scenario": "Telegram bot responds to messages but OpenClaw gateway logs show 'webhook not received'",
  "resolution": "Server behind NAT. Use ngrok or configure port forwarding, then update webhook URL in BotFather",
  "context": {
    "channel": "telegram",
    "network": "nat"
  },
  "category": "channel",
  "frequency": 3,
  "tags": ["telegram", "webhook", "nat", "network"]
}
```

```json
{
  "id": "ll-i9j0k1l2",
  "scenario": "OpenClaw returns 'model not found' for 'gpt-4' but works with 'gpt-3.5-turbo'",
  "resolution": "API key tier doesn't include GPT-4 access. Upgrade to paid tier or use available models",
  "context": {
    "provider": "openai",
    "model": "gpt-4"
  },
  "category": "model",
  "frequency": 7,
  "tags": ["openai", "api-key", "tier", "models"]
}
```

## Integration with sync-knowledge

The `sync-knowledge` skill will:

1. Check if lesson patterns match updated docs
2. Archive lessons that are now in official docs
3. Flag lessons that contradict updated docs
4. Keep the knowledge base fresh and accurate

---

## Summary

This learning system helps us all get better over time:

- ✓ Faster problem solving (learn from past issues)
- ✓ Better documentation (fill in gaps)
- ✓ Smarter escalation (know what's been tried)
- ✓ Continuous improvement (knowledge compound interest)

Every session makes future sessions smoother!
