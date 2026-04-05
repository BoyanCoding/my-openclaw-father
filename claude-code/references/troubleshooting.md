# OpenClaw Troubleshooting Guide

This guide covers known issues, diagnosis steps, and resolutions for common OpenClaw problems.

## Installation Failures

### Network Timeouts

**Symptoms:**
- `curl: (28) Operation timed out`
- `npm ERR! network timeout`
- Installation hangs indefinitely

**Diagnosis:**
```bash
# Test internet connectivity
ping -c 3 openclaw.ai

# Check for corporate proxy
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Test DNS resolution
nslookup openclaw.ai
```

**Resolution:**
```bash
# If using proxy, configure curl
curl -x http://proxy:port -fsSL https://openclaw.ai/install.sh | bash

# Increase timeout
curl -m 300 -fsSL https://openclaw.ai/install.sh | bash

# Try alternative mirror
curl -fsSL https://cdn.openclaw.ai/install.sh | bash
```

### Permission Errors

**Symptoms:**
- `EACCES: permission denied`
- `Cannot write to /usr/local/bin`
- npm install fails with permission errors

**Diagnosis:**
```bash
# Check directory permissions
ls -la /usr/local/bin

# Check current user
whoami
```

**Resolution:**
```bash
# Option 1: Use sudo
sudo curl -fsSL https://openclaw.ai/install.sh | bash

# Option 2: Fix npm permissions
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH="~/.npm-global/bin:$PATH"
echo 'export PATH="~/.npm-global/bin:$PATH"' >> ~/.bashrc

# Option 3: Use local prefix installer
curl -fsSL https://openclaw.ai/install-cli.sh | bash
```

### Disk Space Issues

**Symptoms:**
- `No space left on device`
- Installation fails during unpacking

**Diagnosis:**
```bash
# Check disk space
df -h

# Check /tmp space
df -h /tmp
```

**Resolution:**
```bash
# Clean package cache
npm cache clean --force

# Clean /tmp if needed
sudo rm -rf /tmp/openclaw-*

# Free up disk space
# (Delete unnecessary files, logs, etc.)
```

### Node Version Mismatch

**Symptoms:**
- `Node.js version too old`
- `Requires Node.js 22.14+`
- Installation fails version check

**Diagnosis:**
```bash
# Check Node version
node -v

# Check if nvm is installed
nvm --version
```

**Resolution:**
```bash
# Using nvm
nvm install 24
nvm use 24
curl -fsSL https://openclaw.ai/install.sh | bash

# Using n (Linux/macOS)
sudo n 24

# Using Homebrew (macOS)
brew install node@24
brew link node@24
```

## "openclaw not found" After Install

### Global Bin Not in PATH

**Symptoms:**
- `openclaw: command not found`
- `command not found: openclaw`

**Diagnosis:**
```bash
# Check if openclaw is installed
which openclaw

# Check npm global bin
npm prefix -g

# Check PATH
echo $PATH
```

**Resolution:**
```bash
# Add npm global bin to PATH
export PATH="$(npm prefix -g)/bin:$PATH"

# Make permanent (bash)
echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Make permanent (zsh)
echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For local prefix installer
export PATH="$HOME/.openclaw/bin:$PATH"
echo 'export PATH="$HOME/.openclaw/bin:$PATH"' >> ~/.bashrc
```

### Node Not Installed

**Symptoms:**
- `node: command not found`
- Installation completed but openclaw won't run

**Diagnosis:**
```bash
# Verify Node is installed
node -v

# Check if in PATH
which node
```

**Resolution:**
```bash
# Install Node.js 24
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs  # Debian/Ubuntu

# Or via Homebrew (macOS)
brew install node@24

# Or via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 24
nvm use 24
```

## Daemon/Gateway Issues

### Gateway Won't Start

**Symptoms:**
- `openclaw gateway start` fails
- `Error: Port 18789 already in use`
- Gateway crashes immediately

**Diagnosis:**
```bash
# Check if port is in use
lsof -i :18789

# Check gateway logs
tail -f /tmp/openclaw/openclaw.log

# Test configuration
openclaw doctor
```

**Resolution:**
```bash
# Kill process using port
kill -9 $(lsof -t -i:18789)

# Or change port in config
# Edit ~/.openclaw/openclaw.json:
# {
#   gateway: {
#     port: 18790  // Use different port
#   }
# }

# Restart gateway
openclaw gateway start
```

### Gateway Crashes on Boot

**Symptoms:**
- Gateway starts then immediately stops
- Crashes after processing a few messages
- High CPU usage then crash

**Diagnosis:**
```bash
# Check full logs
cat /tmp/openclaw/openclaw.log

# Check for memory issues
openclaw gateway status

# Validate configuration
openclaw doctor
```

**Resolution:**
```bash
# Check for config errors
openclaw doctor

# Reduce memory usage in config
# Edit ~/.openclaw/openclaw.json:
# {
#   gateway: {
#     maxMemory: "512MB",
#     maxSessions: 10
#   }
# }

# Clear corrupted state
openclaw gateway stop
rm -rf ~/.openclaw/state/*
openclaw gateway start
```

### High CPU/Memory Usage

**Symptoms:**
- Gateway process using high CPU
- Memory usage grows continuously
- System becomes slow

**Diagnosis:**
```bash
# Check resource usage
top | grep openclaw

# Check active sessions
openclaw session list

# Check model context size
openclaw logs --tokens --since "1h ago"
```

**Resolution:**
```bash
# Reduce session context
# Edit ~/.openclaw/openclaw.json:
{
  agents: {
    defaults: {
      maxTokens: 2000,  // Reduce from default
      contextCompaction: {
        enabled: true,
        reserveTokens: 5000,
        strategy: "summarize"
      }
    }
  }
}

# Restart gateway
openclaw gateway restart

# If issue persists, clear all sessions
openclaw session clear-all
```

## Channel Connectivity Issues

### Telegram Not Responding

**Symptoms:**
- Telegram bot doesn't reply to messages
- No error messages visible

**Diagnosis:**
```bash
# Check gateway status
openclaw gateway status

# Check logs for Telegram
tail -f /tmp/openclaw/openclaw.log | grep telegram

# Verify config
openclaw doctor
```

**Resolution:**
```bash
# Check dmPolicy setting
# Ensure not set to "disabled"
cat ~/.openclaw/openclaw.json | grep dmPolicy

# If using pairing mode, approve user
openclaw pairing list
openclaw pairing approve <CODE>

# Verify bot token
echo $TELEGRAM_BOT_TOKEN

# Test bot token
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# Restart gateway
openclaw gateway restart
```

### Discord Not Connecting

**Symptoms:**
- Discord bot shows offline
- Bot doesn't respond to messages
- Connection errors in logs

**Diagnosis:**
```bash
# Check Discord-specific logs
tail -f /tmp/openclaw/openclaw.log | grep discord

# Verify bot token
echo $DISCORD_BOT_TOKEN

# Test bot connection
openclaw discord test
```

**Resolution:**
```bash
# Verify intents are enabled
# Go to Discord Developer Portal → Bot → Privileged Gateway Intents
# Ensure "Message Content Intent" is enabled

# Regenerate bot token if needed
# Discord Developer Portal → Bot → Reset Token

# Update .env file
echo 'DISCORD_BOT_TOKEN="new_token_here"' >> ~/.openclaw/.env

# Restart gateway
openclaw gateway restart
```

### Slack Socket Mode Issues

**Symptoms:**
- Slack bot doesn't connect
- Socket mode connection failures
- Bot shows as offline

**Diagnosis:**
```bash
# Check both tokens
echo $SLACK_BOT_TOKEN  # Should start with xoxb-
echo $SLACK_APP_TOKEN  # Should start with xapp-

# Check Slack logs
tail -f /tmp/openclaw/openclaw.log | grep slack
```

**Resolution:**
```bash
# Verify both tokens are correct
# Bot Token: xoxb-... (from OAuth & Permissions)
# App Token: xapp-... (from Basic Information → App-Level Token)

# Ensure Socket Mode is enabled
# Slack App settings → Socket Mode → Enable

# Restart gateway
openclaw gateway restart
```

## Model Provider Errors

### 401 Authentication Errors

**Symptoms:**
- `401 Unauthorized`
- `Invalid API key`
- `Authentication failed`

**Diagnosis:**
```bash
# Check if .env file exists
ls -la ~/.openclaw/.env

# Verify API key format
cat ~/.openclaw/.env | grep API_KEY

# Test API key directly
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-opus-4-6","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
```

**Resolution:**
```bash
# Verify API key is correct
# Check for extra spaces or quotes

# Regenerate API key if needed
# Go to provider console and create new key

# Update .env file
echo 'ANTHROPIC_API_KEY="sk-ant-new-key"' >> ~/.openclaw/.env

# Restart gateway
openclaw gateway restart
```

### 429 Rate Limit Errors

**Symptoms:**
- `429 Too Many Requests`
- `Rate limit exceeded`
- Requests throttled

**Diagnosis:**
```bash
# Check rate limit status
openclaw models info --provider anthropic

# Check recent request count
openclaw logs --requests --since "1h ago"
```

**Resolution:**
```bash
# Configure fallback provider
# Edit ~/.openclaw/openclaw.json:
{
  models: {
    fallbacks: {
      enabled: true,
      fallbacks: [
        { model: "anthropic:claude-opus-4-6" },
        { model: "openai:gpt-5.2" },
        { model: "google:gemini-2.5-pro" }
      ]
    }
  }
}

# Enable retry with backoff
{
  models: {
    providers: {
      anthropic: {
        retryConfig: {
          maxRetries: 3,
          backoffMs: 2000
        }
      }
    }
  }
}

# Reduce request frequency
{
  agents: {
    defaults: {
      rateLimit: {
        requestsPerMinute: 30
      }
    }
  }
}
```

### Context Length Exceeded

**Symptoms:**
- `Context length exceeded`
- `Too many tokens`
- `Maximum context window reached`

**Diagnosis:**
```bash
# Check model context window
openclaw models info anthropic:claude-opus-4-6

# Monitor token usage
openclaw logs --tokens --since "1h ago"

# Check session size
openclaw session show <session_id>
```

**Resolution:**
```bash
# Enable context compaction
{
  agents: {
    defaults: {
      contextCompaction: {
        enabled: true,
        reserveTokens: 10000,
        strategy: "summarize",
        triggerThreshold: 0.8  // Compact at 80% capacity
      }
    }
  }
}

# Reduce max output tokens
{
  agents: {
    defaults: {
      maxTokens: 2000  // Reduce from default
    }
  }
}

# Use model with larger context
{
  agents: {
    defaults: {
      model: {
        primary: "google:gemini-2.5-pro"  // 1M context
      }
    }
  }
}

# Clear old sessions
openclaw session clear --before "7d ago"
```

## Configuration Errors

### JSON5 Syntax Errors

**Symptoms:**
- `Syntax error in openclaw.json`
- `Unexpected token`
- `Invalid JSON5`

**Diagnosis:**
```bash
# Validate configuration
openclaw doctor

# Check JSON syntax
cat ~/.openclaw/openclaw.json | jq .

# Look for common errors
cat ~/.openclaw/openclaw.json | grep -n "TODO\|HACK\|FIXME"
```

**Resolution:**
```bash
# Common JSON5 errors to fix:

# 1. Trailing commas (OK in JSON5, not JSON)
# GOOD: { "key": "value", }
# BAD (if strict JSON): { "key": "value", }

# 2. Comments (OK in JSON5)
# GOOD: { "key": "value" /* comment */ }
# BAD (if strict JSON): { "key": "value" /* comment */ }

# 3. Unquoted keys (OK in JSON5)
# GOOD: { key: "value" }
# BAD (if strict JSON): { key: "value" }

# 4. Use validator
openclaw doctor --fix

# 5. Backup and reset
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
openclaw config reset
```

### Missing Required Fields

**Symptoms:**
- `Missing required field: apiKey`
- `Configuration incomplete`
- `Invalid agent configuration`

**Diagnosis:**
```bash
# Check configuration
openclaw doctor

# Validate against schema
openclaw config validate
```

**Resolution:**
```bash
# Check required fields for each section

# Models section
{
  models: {
    providers: {
      anthropic: {
        apiKey: "${ANTHROPIC_API_KEY}",  // REQUIRED
        baseUrl: "...",  // Optional
        defaultModel: "..."  // Optional
      }
    }
  }
}

# Channels section
{
  channels: {
    telegram: {
      botToken: "${TELEGRAM_BOT_TOKEN}",  // REQUIRED
      dmPolicy: "pairing",  // Optional, defaults to "pairing"
      allowFrom: []  // Optional
    }
  }
}

# Gateway section
{
  gateway: {
    port: 18789,  // Optional, defaults to 18789
    auth: {
      mode: "token",  // Optional, defaults to "token"
      token: "${GATEWAY_TOKEN}"  // Required if mode is "token"
    }
  }
}
```

### Environment Variable Not Resolved

**Symptoms:**
- `${VAR_NAME}` appears literally in logs
- API key not working
- Configuration shows placeholder values

**Diagnosis:**
```bash
# Check if .env file exists
ls -la ~/.openclaw/.env

# Check if variable is set
echo $ANTHROPIC_API_KEY

# Verify .env syntax
cat ~/.openclaw/.env
```

**Resolution:**
```bash
# Ensure .env file exists
touch ~/.openclaw/.env
chmod 600 ~/.openclaw/.env

# Add variables correctly (no spaces around =)
echo 'ANTHROPIC_API_KEY="sk-ant-xxx"' >> ~/.openclaw/.env

# WRONG:
# echo 'ANTHROPIC_API_KEY = "sk-ant-xxx"' >> ~/.openclaw/.env

# Restart gateway to load new env vars
openclaw gateway restart

# Verify variable is loaded
openclaw config show | grep anthropic
```

## Log Analysis

### Log Locations

```
/tmp/openclaw/
├── openclaw.log           # Main gateway log
├── agent-*.log           # Agent-specific logs
├── channel-*.log         # Channel-specific logs
└── error.log             # Error-only log
```

### Viewing Logs

```bash
# Follow main log
tail -f /tmp/openclaw/openclaw.log

# View last 100 lines
tail -n 100 /tmp/openclaw/openclaw.log

# Search for errors
grep -i error /tmp/openclaw/openclaw.log

# Search for specific channel
grep -i telegram /tmp/openclaw/openclaw.log

# View logs from last hour
openclaw logs --since "1h ago"

# View errors only
openclaw logs --level error

# Export logs
openclaw logs export --since "24h ago" > logs.json
```

### Log Patterns

**Normal startup:**
```
[INFO] OpenClaw Gateway v1.0.0 starting
[INFO] Loading configuration from /home/user/.openclaw/openclaw.json
[INFO] Connecting to Anthropic API
[INFO] Telegram channel connected
[INFO] Discord channel connected
[INFO] Gateway listening on port 18789
```

**Successful message:**
```
[INFO] [telegram:123456789] Received message from user
[INFO] [agent:default] Processing message with claude-opus-4-6
[INFO] [agent:default] Response generated in 2.3s
[INFO] [telegram:123456789] Sent response
```

**Error patterns:**
```
[ERROR] Failed to connect to Anthropic API: 401 Unauthorized
[ERROR] Telegram channel error: bot token invalid
[ERROR] Agent execution failed: Context length exceeded
```

## Diagnostic Commands

### Health Check

```bash
# Overall system health
openclaw doctor

# Gateway status
openclaw gateway status

# Model provider status
openclaw models status

# Channel connectivity
openclaw channels test

# Session information
openclaw session list
```

### Detailed Diagnostics

```bash
# Full diagnostic report
openclaw doctor --verbose

# Test specific component
openclaw doctor --component models
openclaw doctor --component channels
openclaw doctor --component gateway

# Export diagnostic report
openclaw doctor --export > diagnostic-report.json
```

## Session Issues

### Auto-Compaction Too Frequent

**Symptoms:**
- Context compacting on every message
- Slow response times
- Summaries appearing frequently

**Diagnosis:**
```bash
# Check compaction settings
openclaw config show | grep compaction

# Monitor compaction events
openclaw logs | grep compact
```

**Resolution:**
```bash
# Increase reserveTokens
{
  agents: {
    defaults: {
      contextCompaction: {
        enabled: true,
        reserveTokens: 20000,  // Increase from default
        triggerThreshold: 0.9  // Compact at 90% instead of 80%
      }
    }
  }
}
```

### Context Overflow

**Symptoms:**
- Messages failing with context errors
- Truncated responses
- Agent losing track of conversation

**Diagnosis:**
```bash
# Check model context window
openclaw models info anthropic:claude-opus-4-6

# Check session token count
openclaw session show <session_id> --tokens
```

**Resolution:**
```bash
# Use model with larger context
{
  agents: {
    defaults: {
      model: {
        primary: "google:gemini-2.5-pro"  // 1M tokens
      }
    }
  }
}

# Or reduce session history
{
  agents: {
    defaults: {
      maxHistoryMessages: 50  // Keep last 50 messages
    }
  }
}
```

## Upgrade Issues

### Breaking Changes Between Versions

**Symptoms:**
- Config fails after upgrade
- Features no longer working
- Warnings about deprecated settings

**Diagnosis:**
```bash
# Check version
openclaw --version

# Check changelog
openclaw changelog

# Validate config
openclaw doctor
```

**Resolution:**
```bash
# Backup current config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup

# Auto-migrate config
openclaw config migrate

# Review changes
openclaw config show

# If issues persist, reset to defaults
openclaw config reset
```

### Configuration Migration Needed

**Symptoms:**
- `Configuration format outdated`
- `Please migrate configuration`
- Warnings about old schema

**Diagnosis:**
```bash
# Check config version
grep "version" ~/.openclaw/openclaw.json

# Compare with current schema
openclaw config schema
```

**Resolution:**
```bash
# Automatic migration
openclaw config migrate

# Manual migration (if auto fails)
# 1. Export current config
openclaw config export > old-config.json

# 2. Reset to defaults
openclaw config reset

# 3. Manually merge settings
# Edit ~/.openclaw/openclaw.json

# 4. Validate
openclaw doctor
```

## Docker-Specific Issues

### Volume Mount Issues

**Symptoms:**
- Container can't access config
- `Permission denied` errors
- Config changes not persisting

**Diagnosis:**
```bash
# Check volume mounts
docker inspect openclaw | grep Mounts

# Check container logs
docker logs openclaw

# Check file permissions
ls -la ~/.openclaw/
```

**Resolution:**
```bash
# Fix permissions
sudo chown -R $USER:$USER ~/.openclaw

# Update docker-compose.yml
volumes:
  - ~/.openclaw:/app/.openclaw:rw  # Ensure :rw
  - ~/openclaw-workspace:/workspace:rw

# Recreate container
docker compose down
docker compose up -d
```

### Networking Problems

**Symptoms:**
- Can't access gateway from host
- Webhooks not reaching container
- DNS resolution failures

**Diagnosis:**
```bash
# Check container network
docker network inspect openclaw_default

# Test DNS from container
docker exec openclaw nslookup api.anthropic.com

# Check port mapping
docker port openclaw
```

**Resolution:**
```bash
# Use host networking (Linux only)
docker compose.yml:
  service:
    network_mode: "host"

# Or expose ports correctly
ports:
  - "18789:18789"

# Configure DNS
docker compose.yml:
  service:
    dns:
      - 8.8.8.8
      - 8.8.4.4
```

## Getting Help

If issues persist after troubleshooting:

### Collect Diagnostic Information

```bash
# Export full diagnostic report
openclaw doctor --export > diagnostic-report.json

# Export logs
openclaw logs export --since "24h ago" > logs.json

# Export configuration
openclaw config export > config.json

# Create support bundle
tar -czf openclaw-support-bundle.tar.gz \
  diagnostic-report.json \
  logs.json \
  config.json \
  ~/.openclaw/openclaw.json
```

### Community Resources

- **GitHub Issues**: https://github.com/openclaw/openclaw/issues
- **Discord Community**: https://discord.gg/openclaw
- **Documentation**: https://docs.openclaw.ai
- **Status Page**: https://status.openclaw.ai

### When to Escalate

- Multiple failed attempts on same issue
- Unclear error messages
- Security concerns
- Performance issues not resolved by optimization
- Feature requests

## Quick Reference

### Common Commands

```bash
# Installation/Setup
openclaw --version
openclaw doctor
openclaw onboard

# Gateway Management
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
openclaw gateway status

# Configuration
openclaw config show
openclaw config validate
openclaw doctor --fix

# Logs
openclaw logs --since "1h ago"
openclaw logs --level error
tail -f /tmp/openclaw/openclaw.log

# Diagnostics
openclaw models test --all
openclaw channels test
openclaw session list
```

### Common Fixes

| Issue | Quick Fix |
|-------|-----------|
| Command not found | `export PATH="$(npm prefix -g)/bin:$PATH"` |
| Port in use | `kill -9 $(lsof -t -i:18789)` |
| Config error | `openclaw doctor --fix` |
| 401 error | Check `.env` file for API keys |
| 429 error | Add fallback provider |
| Context overflow | Enable compaction or use larger context model |

## Related Documentation

- [install-procedures.md](./install-procedures.md) - Installation help
- [security-checklist.md](./security-checklist.md) - Security configuration
- [model-providers.md](./model-providers.md) - Provider-specific issues
- [channel-setup-guides.md](./channel-setup-guides.md) - Channel connectivity
