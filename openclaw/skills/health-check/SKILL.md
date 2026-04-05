---
name: health-check
description: Diagnose OpenClaw issues including gateway status, channel connectivity, model provider errors, and configuration problems. Use when something isn't working or for post-install verification.
---

# OpenClaw Health Check

Let's diagnose what's going on with your OpenClaw installation. I'll run through a comprehensive check of all systems.

## System Checks

### Version Check

First, let's verify OpenClaw is installed:

```bash
openclaw --version
```

**Expected output:** `OpenClaw v1.x.x`

**Common errors:**
- `command not found`: OpenClaw not installed or not in PATH
- `version unknown`: Installation incomplete

### Gateway Status

```bash
openclaw gateway status
```

**Expected output:**
```
Gateway: running
PID: 12345
Port: 18789
Uptime: 2 hours
```

**Common errors:**
- `Gateway: stopped`: Gateway not running
- `Port already in use`: Another process using port 18789
- `Permission denied`: Need to run with sudo (if using privileged port)

### System Resources

```bash
# Disk space
df -h /

# Memory
free -h

# CPU
top -bn1 | head -20
```

**Requirements:**
- Disk: At least 500MB free
- Memory: At least 512MB free
- CPU: No specific requirement, but not 100% utilized

---

## Configuration Validation

### Run Doctor

```bash
openclaw doctor
```

This will check:
- ✓ OpenClaw installation and version
- ✓ Gateway status and connectivity
- ✓ Configuration validity
- ✓ Channel connectivity
- ✓ Model provider status
- ✓ System resources (disk, memory)

**Expected output:** All checks show `✓ PASS`

**Common errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| `Config file not found` | No openclaw.json | Run `openclaw init` |
| `Invalid JSON` | Syntax error in config | Run `jq . < openclaw.json` to find error |
| `Missing API key` | Key not in .env | Add key to ~/.openclaw/.env |
| `Invalid channel config` | Channel misconfigured | Check channel-specific docs |

---

## Channel Connectivity

### Test Each Enabled Channel

```bash
# List enabled channels
cat ~/.openclaw/openclaw.json | grep -A 5 '"enabled": true'

# For each channel, test connectivity
```

#### Telegram Test
```bash
# Check bot token is valid
curl -X GET "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
```

**Expected output:** JSON with bot info including `"ok": true`

#### Discord Test
```bash
# Check bot connection
curl -X GET "https://discord.com/api/v10/users/@me" \
  -H "Authorization: Bot ${DISCORD_BOT_TOKEN}"
```

**Expected output:** JSON with bot user info

#### Slack Test
```bash
# Check bot authentication
curl -X GET "https://slack.com/api/auth.test" \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}"
```

**Expected output:** JSON with `"ok": true`

#### WhatsApp Test
```bash
# Verify phone number
curl -X GET "https://graph.facebook.com/v17.0/YOUR_PHONE_NUMBER_ID" \
  -H "Authorization: Bearer ${WHATSAPP_ACCESS_TOKEN}"
```

**Expected output:** JSON with phone number details

---

## Model Provider Test

### Test API Key

Let's verify your API key works:

```bash
# OpenAI test
curl -X POST "https://api.openai.com/v1/chat/completions" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 5
  }'

# Anthropic test
curl -X POST "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "max_tokens": 10,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

**Expected output:** JSON with response from the model

**Common errors:**
- `401 Unauthorized`: Invalid API key
- `429 Rate limit`: Too many requests, wait and retry
- `500 Internal error`: Provider issue, check status page

---

## Log Analysis

### Check Gateway Logs

```bash
# View recent logs
tail -n 50 /tmp/openclaw/openclaw.log

# Follow logs in real-time
tail -f /tmp/openclaw/openclaw.log

# Search for errors
grep -i "error" /tmp/openclaw/openclaw.log | tail -20

# Search for warnings
grep -i "warn" /tmp/openclaw/openclaw.log | tail -20
```

### Common Log Patterns

| Pattern | Meaning | Fix |
|---------|---------|-----|
| `ECONNREFUSED` | Can't reach provider | Check network, proxy settings |
| `API key invalid` | Key is wrong or expired | Regenerate API key |
| `Timeout` | Request took too long | Check network, increase timeout |
| `Config error` | Invalid config file | Run `openclaw doctor` |
| `Permission denied` | Can't access file/directory | Check file permissions |
| `Port in use` | Another process using port | Kill other process or change port |

---

## Network Check

### Verify Gateway is Listening

```bash
# Check if port is listening
ss -tlnp | grep 18789

# Alternative command
netstat -tlnp | grep 18789

# Alternative command
lsof -i :18789
```

**Expected output:** Process listening on port 18789

### Check Bind Address

```bash
# View gateway config
cat ~/.openclaw/openclaw.json | grep -A 5 '"gateway"'
```

**Verify:**
- If `bindAddress` is `127.0.0.1`: Only accessible locally
- If `bindAddress` is `0.0.0.0`: Accessible from anywhere (ensure auth is enabled!)

### Test from Local Machine

```bash
# Test HTTP endpoint
curl -I http://localhost:18789/health

# Test with authentication
curl -H "Authorization: Bearer ${OPENCLAW_TOKEN}" \
  http://localhost:18789/health
```

**Expected output:** `200 OK` response

---

## Session Health

### Check for Issues

```bash
# Check for excessive compaction
grep -i "compacting" /tmp/openclaw/openclaw.log | wc -l

# Check for context overflow
grep -i "context.*overflow" /tmp/openclaw/openclaw.log

# Check for memory issues
grep -i "out of memory" /tmp/openclaw/openclaw.log
```

**Warning signs:**
- More than 10 compactions in an hour: Context too large
- Context overflow messages: Max tokens exceeded
- Out of memory: Increase available memory or reduce context

---

## Diagnostic Report

Based on all the checks, I'll generate a structured report:

```
OpenClaw Diagnostic Report
==========================

Installation
  ✓ OpenClaw version: 1.2.3
  ✓ Binary path: /usr/local/bin/openclaw

Gateway
  ✓ Status: running
  ✓ PID: 12345
  ✓ Port: 18789 (listening)
  ✓ Bind address: 127.0.0.1
  ✓ Auth mode: token

Configuration
  ✓ Config file: ~/.openclaw/openclaw.json
  ✓ JSON syntax: valid
  ✓ API keys: loaded from .env
  ✓ Channels configured: telegram, discord

Channels
  ✓ Telegram: connected (@MyBot)
  ✓ Discord: connected (MyBot#1234)
  ✗ Slack: connection failed (invalid token)

Model Provider
  ✓ OpenAI: API key valid
  ✓ Anthropic: API key valid
  ✓ Test completion: successful

System Resources
  ✓ Disk space: 15GB available
  ✓ Memory: 2GB free
  ✓ CPU: 25% utilization

Logs (last 24 hours)
  ⚠️ 3 warnings found
  ✗ 2 errors found
    - Slack auth failure (2 hours ago)
    - Timeout on model request (5 hours ago)

Overall Status: ⚠️ MINOR ISSUES
Recommendation: Fix Slack token
```

---

## Suggested Fixes

Based on the diagnostic report, here are specific fixes:

### For Channel Issues
1. **Token expired**: Regenerate bot token from platform
2. **Invalid permissions**: Update bot permissions in platform
3. **Webhook not received**: Check firewall, verify webhook URL

### For Model Provider Issues
1. **Invalid API key**: Regenerate from provider dashboard
2. **Rate limited**: Wait and retry, or upgrade plan
3. **Timeout**: Increase timeout in config
4. **SSR blocked**: Check proxy settings

### For Gateway Issues
1. **Not running**: `openclaw gateway start`
2. **Port in use**: `kill $(lsof -ti :18789)` then restart
3. **Permission denied**: Run with appropriate permissions
4. **Config error**: Fix JSON syntax error

### For System Issues
1. **Low disk space**: Clean up logs, cache
2. **Out of memory**: Increase swap, reduce workload
3. **High CPU**: Check for runaway processes

---

## Next Steps

If I can identify and fix the issue:

1. **Apply the fix** - Show you the exact command/config change
2. **Verify it works** - Re-run the failing check
3. **Document the solution** - Add to knowledge base for next time

If I can't fix it:

1. **Escalate clearly** - Explain what's happening and why
2. **Provide specific next steps** - What you should do next
3. **Reference troubleshooting docs** - Point to detailed guides

Let me know what's not working and I'll help you diagnose it!
