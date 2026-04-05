# Dual-Format Guide: OpenClaw Agent + Claude Code Skill

## Why Dual Format?

OpenClaw Father is designed to reach users in two different ecosystems:

1. **OpenClaw Ecosystem**: Users deploying OpenClaw agents for multi-channel chat operations
2. **Claude Code Ecosystem**: Developers using the Claude Code editor extension

By supporting both formats, we maximize the agent's utility while maintaining a single source of truth for all knowledge content.

### Benefits
- **Broader Reach**: Meet users where they work
- **Shared Knowledge**: Edit once, distribute everywhere
- **Consistent Experience**: Same information in both formats
- **Reduced Maintenance**: No duplicate content management

## Knowledge as Single Source of Truth

The `knowledge/` directory serves as the authoritative source for all documentation:

```
knowledge/                          claude-code/
├── agent-setup/                    └── references/
│   ├── install-procedure.md            ├── install-procedure.md (copy)
│   └── generate-config.md              ├── generate-config.md (copy)
├── channels/                          ├── slack.md (copy)
│   ├── slack.md                        ├── discord.md (copy)
│   ├── discord.md                      └── ...
│   ├── matrix.md
│   └── whatsapp.md
├── security/
│   ├── security-checklist.md
│   └── dm-policy.md
├── providers/
│   └── model-providers.md
└── operations/
    ├── health-check.md
    └── troubleshooting.md
```

**Key Principle**: All content is authored in `knowledge/`. The `claude-code/references/` directory contains copies maintained by CI.

## CI Sync Pipeline

GitHub Actions automatically syncs knowledge to the Claude Code skill format:

```yaml
# .github/workflows/sync-knowledge.yml
name: Sync Knowledge to Claude Code

on:
  push:
    paths:
      - 'knowledge/**'
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      
      - name: Sync knowledge files
        run: |
          # Copy agent setup docs
          cp knowledge/agent-setup/*.md claude-code/references/
          
          # Create channels subdirectory if needed
          mkdir -p claude-code/references/channels
          cp knowledge/channels/*.md claude-code/references/channels/
          
          # Copy other sections
          mkdir -p claude-code/references/{security,providers,operations}
          cp knowledge/security/*.md claude-code/references/security/
          cp knowledge/providers/*.md claude-code/references/providers/
          cp knowledge/operations/*.md claude-code/references/operations/
      
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add claude-code/references/
          git diff --staged --quiet || git commit -m "Sync knowledge to Claude Code references"
          git push
```

**Benefits**:
- Automatic propagation of knowledge updates
- No manual copying required
- Version history maintained
- Prevents drift between formats

## Format-Specific Consumption

### OpenClaw Agent

The OpenClaw agent reads knowledge directly from the `knowledge/` directory:

```javascript
// openclaw-father/agent/skills/channel-setup.js
async function setupChannel(channelName) {
  const knowledgePath = `knowledge/channels/${channelName}.md`;
  const guide = fs.readFileSync(knowledgePath, 'utf-8');
  
  return {
    guide: guide,
    recommendations: parseGuide(guide),
    troubleshooting: extractTroubleshooting(guide)
  };
}
```

**Characteristics**:
- Direct file access
- Real-time updates
- Works with agent file system
- No build step required

### Claude Code Skill

The Claude Code skill reads from the `references/` directory (copies of knowledge):

```typescript
// claude-code/skill.ts
import { readFile } from 'fs/promises';

export async function getChannelGuide(channel: string): Promise<string> {
  const referencePath = `${__dirname}/references/channels/${channel}.md`;
  return await readFile(referencePath, 'utf-8');
}
```

**Characteristics**:
- Packaged with skill
- Requires rebuild for updates
- Self-contained distribution
- Works in skill sandbox

## How to Update Knowledge

### Step 1: Edit in knowledge/
```bash
# Edit the source file
vim knowledge/channels/slack.md
```

### Step 2: Test Locally
```bash
# Verify OpenClaw agent reads it correctly
node test-agent.js slack

# Verify Claude Code skill reads it correctly
npm test -- slack
```

### Step 3: Commit Changes
```bash
git add knowledge/channels/slack.md
git commit -m "Update Slack channel guide with new bot permissions"
git push
```

### Step 4: CI Syncs Automatically
- GitHub Actions detects change
- Copies file to `claude-code/references/channels/slack.md`
- Commits and pushes the sync

### Step 5: Users Get Updates
- **OpenClaw users**: Pull latest repo, immediately have new knowledge
- **Claude Code users**: Wait for skill package update (or rebuild from source)

## How to Add a New Knowledge File

### Step 1: Create the File
```bash
# Add to appropriate knowledge subdirectory
vim knowledge/operations/new-procedure.md
```

### Step 2: Follow Format Requirements
```markdown
# Title of the Procedure

## Overview
Brief description of what this procedure covers.

## Prerequisites
- Requirement 1
- Requirement 2

## Steps
1. First step
2. Second step
3. Third step

## Troubleshooting
### Problem: Description
**Solution**: How to fix it

## Related
- Link to related procedures
- Reference to other docs
```

### Step 3: Update Sync Script (if needed)
```bash
# scripts/sync-knowledge.sh
# Add new file to sync list if not covered by wildcard
sync_file "operations/new-procedure.md" "references/operations/"
```

### Step 4: Add to Agent Skill (if applicable)
```javascript
// openclaw-father/agent/skills/new-procedure.js
const knowledge = require('../knowledge/operations/new-procedure.md');

module.exports = {
  async execute(context) {
    return {
      guide: knowledge,
      steps: parseSteps(knowledge)
    };
  }
};
```

### Step 5: Test and Commit
```bash
# Test both formats
npm test
git add knowledge/operations/new-procedure.md
git commit -m "Add new procedure documentation"
git push
```

## File Format Requirements

### Markdown Files (.md)

**Required**:
- Clear heading hierarchy (H1, H2, H3)
- Code blocks with language specification
- Links to related resources
- Troubleshooting section (if applicable)

**Recommended**:
- Table of contents for long files
- Code examples with copy-pasteable blocks
- Screenshots or diagrams (referenced as paths)
- Version-specific notes

**Example**:
```markdown
# Channel Setup Guide for Slack

## Overview
This guide explains how to configure OpenClaw to work with Slack.

## Prerequisites
- OpenClaw agent installed
- Slack workspace admin access
- Bot token from Slack API

## Configuration Steps

### 1. Create Slack App
```bash
# Navigate to Slack API
open https://api.slack.com/apps
```

### 2. Configure OAuth Scopes
Add the following scopes:
- `chat:write`
- `channels:read`
- `groups:read`

### 3. Install App to Workspace
Copy the Bot User OAuth Token and add to your OpenClaw config.

## Troubleshooting
### Error: "invalid_auth"
**Solution**: Verify bot token is correct and has required scopes.

### Error: "channel_not_found"
**Solution**: Ensure bot is invited to the channel.

## Related
- [Channel Configuration](../agent-setup/generate-config.md)
- [Security Checklist](../security/security-checklist.md)
```

### JSON Files (.json)

**Required**:
- Valid JSON syntax
- Schema definition
- Descriptive field names

**Recommended**:
- Comments via JSON schema
- Validation examples
- Migration guides for schema changes

**Example** (lessons-learned.json):
```json
{
  "$schema": "./lessons-schema.json",
  "version": "1.0",
  "lessons": [
    {
      "id": "lesson-001",
      "problem": "Slack bot fails to connect",
      "solution": "Add `connections:write` scope to bot permissions",
      "context": {
        "platform": "ubuntu-22.04",
        "openclaw_version": "1.2.0",
        "channel": "slack"
      },
      "tags": ["slack", "permissions", "troubleshooting"],
      "timestamp": "2026-04-05T10:00:00Z",
      "verified": true
    }
  ]
}
```

## Directory Structure

```
knowledge/
├── agent-setup/          # Installation and configuration
├── channels/             # Channel-specific guides
├── security/             # Security policies and checklists
├── providers/            # Model provider configurations
├── operations/           # Operational procedures
└── schemas/              # JSON schemas for structured data
```

**Naming Conventions**:
- Use lowercase with hyphens: `install-procedure.md`
- Match file purpose to directory: `channels/slack.md`
- Group related files in subdirectories
- Avoid deep nesting (max 3 levels)

## Updating Both Formats

When you need to update both OpenClaw agent and Claude Code skill behavior:

1. **Knowledge Changes**: Edit in `knowledge/`, CI syncs automatically
2. **Code Changes**: Update both `openclaw-father/` and `claude-code/`
3. **Test Both**: Verify functionality in both formats
4. **Separate Commits**: Knowledge and code changes in separate PRs for clarity

## Common Patterns

### Linking Between Knowledge Files
```markdown
See [Installation Guide](../agent-setup/install-procedure.md) for details.
```

### Referencing from Agent Code
```javascript
const INSTALL_GUIDE = 'knowledge/agent-setup/install-procedure.md';
const guide = fs.readFileSync(INSTALL_GUIDE, 'utf-8');
```

### Accessing from Skill Code
```typescript
import { join } from 'path';
const INSTALL_GUIDE = join(__dirname, '../references/install-procedure.md');
const guide = await readFile(INSTALL_GUIDE, 'utf-8');
```

## Troubleshooting Sync Issues

### Knowledge Not Syncing
```bash
# Check CI logs
gh run list --workflow=sync-knowledge.yml
gh run view [run-id]

# Manual sync
npm run sync-knowledge
```

### File Not Found in Skill
```bash
# Verify file exists in references/
ls claude-code/references/

# Rebuild skill package
npm run build:skill
```

### Version Mismatch
```bash
# Check last sync
git log --oneline claude-code/references/

# Force sync
npm run sync-knowledge --force
```

## Best Practices

1. **Edit in knowledge/**: Never edit `references/` directly
2. **Test locally**: Verify changes before pushing
3. **Small commits**: Make atomic, logical changes
4. **Descriptive messages**: Explain what changed and why
5. **Review sync**: Check CI results after push
6. **Tag releases**: Create skill releases after sync
7. **Document breaking changes**: Note in CHANGELOG.md
8. **Keep format simple**: Avoid complex markdown features
