# Live Documentation Strategy

## The Problem: Static Documentation Rot

OpenClaw is a rapidly evolving project with frequent updates to:
- Installation procedures
- Channel integrations (Slack, Discord, Matrix, WhatsApp)
- Security best practices
- Model provider configurations
- Troubleshooting guides

Static documentation in a repository quickly becomes stale. By the time a user clones an agent, the knowledge it contains may be weeks or months out of date, leading to:
- Failed installations
- Confusing troubleshooting steps
- Security vulnerabilities
- Poor user experience

## Solution: Two-Tier Documentation System

OpenClaw Father implements a two-tier documentation system that balances freshness with reliability:

```
Tier 1: Live Fetch          Tier 2: Cached Baseline
┌──────────────────┐        ┌──────────────────┐
│ docs.openclaw.ai │  →     │ knowledge/       │
│ (always fresh)   │        │ (offline fallback)│
└──────────────────┘        └──────────────────┘
         ↓                            ↓
    Real-time sync              Weekly CI sync
         ↓                            ↓
    ┌──────────────────────────────────┐
    │      Agent Knowledge Base         │
    │  (combines live + cached data)    │
    └──────────────────────────────────┘
```

### Tier 1: Live Fetch
- **Source**: `https://docs.openclaw.ai/`
- **Purpose**: Always have the latest documentation
- **Trigger**: On-demand when agent needs specific info
- **Requirement**: Internet connection
- **Latency**: ~500ms per request
- **Use Case**: Critical updates, breaking changes

### Tier 2: Cached Baseline
- **Source**: `knowledge/` directory in repository
- **Purpose**: Offline fallback and baseline knowledge
- **Trigger**: Weekly automated sync via CI
- **Requirement**: None (works offline)
- **Latency**: ~0ms (local read)
- **Use Case**: Offline operations, quick responses, baseline knowledge

## Version Tracking

The `version-tracker.json` file maintains synchronization state:

```json
{
  "lastSync": "2026-04-05T10:30:00Z",
  "docsVersion": "v1.2.4",
  "files": {
    "install-procedure": {
      "localHash": "abc123",
      "remoteHash": "abc123",
      "lastChecked": "2026-04-05T10:30:00Z",
      "status": "current"
    },
    "slack-channel": {
      "localHash": "def456",
      "remoteHash": "ghi789",
      "lastChecked": "2026-04-05T10:30:00Z",
      "status": "outdated"
    }
  },
  "syncHistory": [
    {
      "timestamp": "2026-04-05T10:30:00Z",
      "trigger": "ci-weekly",
      "filesUpdated": 3,
      "status": "success"
    }
  ]
}
```

**Schema Fields**:
- `lastSync`: ISO timestamp of last sync
- `docsVersion`: Remote OpenClaw docs version
- `files`: Hash-based tracking per file
- `status`: "current", "outdated", "error"
- `syncHistory`: Audit log of sync operations

## Synchronization Pipeline

### 1. Weekly Automated Sync (CI)

**Trigger**: Every Monday at 00:00 UTC

**Workflow**:
```yaml
# .github/workflows/sync-docs.yml
name: Sync OpenClaw Documentation
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly
  workflow_dispatch:      # Manual trigger

steps:
  - name: Fetch remote docs
    run: |
      curl -s https://docs.openclaw.ai/install > /tmp/install.md
      curl -s https://docs.openclaw.ai/channels/slack > /tmp/slack.md
  
  - name: Compare hashes
    run: |
      node scripts/compare-hashes.js
  
  - name: Update if changed
    run: |
      cp /tmp/*.md knowledge/
  
  - name: Update version tracker
    run: |
      node scripts/update-tracker.json
```

**Benefits**:
- Always has reasonably recent docs (max 1 week old)
- No manual intervention required
- Provides offline baseline

### 2. On-Demand Sync (Agent Self-Check)

**Trigger**: Agent detects outdated knowledge or user requests update

**Implementation**:
```javascript
// Agent skill: sync-knowledge
async function syncKnowledge() {
  const tracker = JSON.parse(fs.readFileSync('version-tracker.json'));
  
  for (const [file, info] of Object.entries(tracker.files)) {
    const remoteHash = await fetchRemoteHash(file);
    if (remoteHash !== info.localHash) {
      console.log(`Updating ${file}...`);
      await fetchAndUpdateFile(file);
      info.status = 'current';
      info.localHash = remoteHash;
    }
  }
  
  tracker.lastSync = new Date().toISOString();
  fs.writeFileSync('version-tracker.json', JSON.stringify(tracker, null, 2));
}
```

**User Command**:
```
User: "Sync your knowledge with the latest OpenClaw docs"
Agent: [Performs sync, reports changes]
```

### 3. Agent Self-Check on Critical Operations

**Trigger**: Before providing guidance on critical operations (install, security)

**Logic**:
```javascript
async function ensureFreshKnowledge(topic) {
  const tracker = JSON.parse(fs.readFileSync('version-tracker.json'));
  const file = topicToFile[topic];
  const lastSync = new Date(tracker.files[file].lastChecked);
  const daysSinceSync = (Date.now() - lastSync) / (1000 * 60 * 60 * 24);
  
  if (daysSinceSync > 7) {
    await fetchAndUpdateFile(file);
  }
}
```

## URL to File Mapping

Documentation sources map to local knowledge files:

```javascript
const docMapping = {
  // Agent setup
  'https://docs.openclaw.ai/install': 'knowledge/install-procedure.md',
  'https://docs.openclaw.ai/configure': 'knowledge/generate-config.md',
  
  // Channels
  'https://docs.openclaw.ai/channels/slack': 'knowledge/channels/slack.md',
  'https://docs.openclaw.ai/channels/discord': 'knowledge/channels/discord.md',
  'https://docs.openclaw.ai/channels/matrix': 'knowledge/channels/matrix.md',
  'https://docs.openclaw.ai/channels/whatsapp': 'knowledge/channels/whatsapp.md',
  
  // Security
  'https://docs.openclaw.ai/security/checklist': 'knowledge/security/security-checklist.md',
  'https://docs.openclaw.ai/security/dm-policy': 'knowledge/security/dm-policy.md',
  
  // Operations
  'https://docs.openclaw.ai/operations/health': 'knowledge/operations/health-check.md',
  'https://docs.openclaw.ai/operations/troubleshooting': 'knowledge/operations/troubleshooting.md',
  
  // Providers
  'https://docs.openclaw.ai/providers': 'knowledge/providers/model-providers.md'
};
```

## Fallback Behavior

### When Online
1. Check `version-tracker.json` for file status
2. If outdated or missing, fetch from `docs.openclaw.ai`
3. Update local cache
4. Return fresh content to user

### When Offline
1. Serve from cached `knowledge/` directory
2. Add disclaimer: "Showing cached documentation (last updated: {date})"
3. Offer to queue sync request for when connection restored
4. Log offline access for later sync

### Hybrid Mode (Recommended)
```javascript
async function getKnowledge(topic, preferFresh = true) {
  const cached = readLocalCache(topic);
  
  if (!preferFresh) {
    return cached;
  }
  
  try {
    const fresh = await fetchRemote(topic);
    if (fresh.hash !== cached.hash) {
      updateLocalCache(topic, fresh);
      notifyUser(`${topic} updated to latest version`);
    }
    return fresh;
  } catch (error) {
    if (error.code === 'ENOTFOUND') {
      notifyUser('Offline: using cached documentation');
      return cached;
    }
    throw error;
  }
}
```

## Adding New Documentation Sources

### 1. Identify the Source
Find the URL of the new documentation page you want to track.

### 2. Add to Mapping
Update `scripts/sync-config.json`:
```json
{
  "sources": {
    "https://docs.openclaw.ai/new-feature": "knowledge/new-feature.md"
  }
}
```

### 3. Create Initial Cache
```bash
curl -s https://docs.openclaw.ai/new-feature > knowledge/new-feature.md
```

### 4. Update Sync Script
Add the new source to the fetch loop in `scripts/sync-openclaw-docs.sh`:
```bash
declare -A sources=(
  ["new-feature"]="https://docs.openclaw.ai/new-feature"
)

for name in "${!sources[@]}"; do
  url="${sources[$name]}"
  echo "Fetching $name from $url..."
  curl -s "$url" > "knowledge/$name.md"
done
```

### 5. Update CI Workflow
Add the new file to the sync workflow if needed.

## Customizing the Sync Script

### Change Sync Frequency
```yaml
# .github/workflows/sync-docs.yml
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours instead of weekly
```

### Add Pre-Processing
```bash
# scripts/sync-openclaw-docs.sh
fetch_and_process() {
  local url="$1"
  local output="$2"
  
  curl -s "$url" | \
    sed 's/\.\/images/https:\/\/docs.openclaw.ai\/images/g' | \
    pandoc -f html -t markdown -o "$output"
}
```

### Add Validation
```bash
validate_sync() {
  local file="$1"
  
  if [ ! -s "$file" ]; then
    echo "Error: $file is empty"
    exit 1
  fi
  
  if ! grep -q "# " "$file"; then
    echo "Error: $file has no heading"
    exit 1
  fi
}
```

### Add Notifications
```javascript
// scripts/notify-sync.js
async function notifySync(results) {
  if (results.filesUpdated > 0) {
    await slack.send({
      channel: '#openclaw-updates',
      text: `Documentation updated: ${results.filesUpdated} files changed`
    });
  }
}
```

## Monitoring and Maintenance

### Health Checks
```bash
# Check if sync is working
curl -s https://docs.openclaw.ai/install | md5sum
cat knowledge/install-procedure.md | md5sum
# Compare hashes manually if needed
```

### Manual Sync Trigger
```bash
# Force immediate sync
npm run sync-docs
# or
./scripts/sync-openclaw-docs.sh --force
```

### Rollback Capability
```bash
# If sync breaks something
git checkout HEAD~1 -- knowledge/
git commit -m "Rollback documentation sync"
```

## Best Practices

1. **Always validate** fetched content before committing
2. **Keep the cache small** - only cache what's essential
3. **Version the tracker** - use git to track changes
4. **Monitor failures** - alert if sync fails repeatedly
5. **Test offline** - ensure agent works without internet
6. **Document changes** - note why a doc was updated
7. **Respect rate limits** - don't hammer the docs server
8. **Cache aggressively** - reduce load on remote servers
