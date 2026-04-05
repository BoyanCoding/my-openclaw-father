# Tools: Usage Policies

## Available Tools

### exec / bash
Execute shell commands. Primary tool for:
- SSH into remote servers: `ssh user@host "command"`
- Run OpenClaw CLI commands remotely
- Check system status (disk, memory, network)
- Install packages and dependencies

### read
Read file contents. Used for:
- Reading openclaw.json configuration
- Checking .env files (never display API keys to user, only verify presence)
- Reading logs for diagnostics
- Reading version-tracker.json

### write
Create or overwrite files. Used for:
- Generating openclaw.json from templates
- Creating .env files with API key placeholders
- Writing channel configuration
- Updating version-tracker.json

### edit
Modify existing files. Used for:
- Adding channels to existing openclaw.json
- Updating model provider config
- Adjusting security settings

### browser
Web browsing. Used for:
- Fetching latest documentation from docs.openclaw.ai
- Checking OpenClaw GitHub releases
- Testing webhook endpoints

## Live-Fetch Strategy (IMPORTANT)

OpenClaw updates daily. Static knowledge goes stale. Follow this priority:

### Tier 1: Live Fetch (always prefer when online)
Before guiding any installation or configuration step:
1. Fetch the relevant page from docs.openclaw.ai using the browser tool
2. Compare with cached knowledge in knowledge/ files
3. If there are differences, use the live docs and note the discrepancy
4. Update the cached knowledge file if the change is significant

Key URLs to check:
- Install: docs.openclaw.ai/install
- Channels: docs.openclaw.ai/channels
- Security: docs.openclaw.ai/security (or pairing-related pages)
- Models: docs.openclaw.ai/models
- Reference: docs.openclaw.ai/reference

### Tier 2: Cached Baseline (fallback when offline)
- Use knowledge/ files as the baseline when docs.openclaw.ai is unreachable
- Warn the user: "I can't reach the docs right now, so I'm working from my cached knowledge. This may not reflect the very latest changes."
- Check knowledge/version-tracker.json to see when knowledge was last synced

## Safety Constraints

1. **Always read before write**: Before modifying openclaw.json, read the current version first
2. **chmod 600 on credentials**: After writing .env or auth-profiles.json, set restrictive permissions
3. **Verify SSH connectivity**: Before running install commands, test SSH with a simple `echo ok`
4. **Show commands before running**: Display what you're about to execute and get confirmation
5. **Never expose API keys**: When reading config files, redact actual key values (show first 4 chars + "...")
6. **Use --dry-run where available**: Test before executing destructive operations
7. **Check disk space**: Before installs, verify sufficient disk space on the target
8. **Validate config after writing**: Run `openclaw doctor` to verify config is valid
