---
name: configure-server
description: Configure OpenClaw server settings including model provider, agent config, gateway auth, and daemon setup. Use after installation or when reconfiguring.
---

# Configuring OpenClaw Server

Let's configure your OpenClaw server to match your needs. I'll guide you through each setting.

## Before We Begin

I'll always fetch the latest configuration documentation to ensure you're getting current best practices.

*(Fetch and review latest config docs before proceeding)*

## Assess Current State

First, let's see what we're working with:

```bash
# Check if config exists
cat ~/.openclaw/openclaw.json

# If it doesn't exist, we'll create from scratch
```

If you have an existing configuration, I'll review it with you and suggest updates. If not, we'll build one from the template.

## Model Provider Setup

OpenClaw needs a model provider to generate responses. Let's set that up first.

### Choose Your Provider

Which model provider would you like to use?

- **OpenAI** (GPT-4, GPT-3.5) - Best for general use
- **Anthropic** (Claude) - Best for long context, reasoning
- **Open Router** (Multi-provider) - Best for flexibility
- **Local** (Ollama, LM Studio) - Best for privacy/cost
- **Other** (Azure, Google, etc.)

### API Key Entry

Once you've chosen, I'll help you securely store your API key:

```bash
# Create .env file in OpenClaw config directory
cat > ~/.openclaw/.env <<EOF
# API Keys - NEVER commit these to version control
OPENAI_API_KEY=sk-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
EOF

# Secure the file
chmod 600 ~/.openclaw/.env
```

**IMPORTANT:** API keys go in `.env`, NOT in `openclaw.json`. The config will reference them like `${OPENAI_API_KEY}`.

### Provider Configuration

I'll add the provider to your `openclaw.json`:

```json
{
  "models": {
    "default": "gpt-4",
    "providers": {
      "openai": {
        "apiKey": "${OPENAI_API_KEY}",
        "baseURL": "https://api.openai.com/v1"
      }
    }
  }
}
```

## Agent Configuration

Now let's configure how your agents behave.

### Workspace Path

Where should your agents work?

```bash
# Default workspace
mkdir -p ~/openclaw-workspace
```

### Sandbox Mode

For security, I recommend enabling sandbox mode:

```json
{
  "agents": {
    "sandbox": {
      "enabled": true,
      "mode": "restricted",
      "allowNetwork": false,
      "allowFileSystem": true,
      "allowedPaths": ["~/openclaw-workspace", "/tmp"]
    }
  }
}
```

### Tool Permissions

Control which tools your agents can use:

```json
{
  "agents": {
    "tools": {
      "bash": {
        "enabled": true,
        "allowCommands": ["git", "npm", "ls", "cat", "grep"]
      },
      "filesystem": {
        "enabled": true,
        "allowRead": true,
        "allowWrite": true
      }
    }
  }
}
```

## Gateway Configuration

Configure how clients connect to your OpenClaw gateway.

### Authentication Mode

I recommend using **token authentication** for security:

```json
{
  "gateway": {
    "auth": {
      "mode": "token",
      "tokens": {
        "default": "${OPENCLAW_TOKEN}"
      }
    }
  }
}
```

Generate a secure token:

```bash
# Generate random token
openssl rand -hex 32 > ~/.openclaw/.env-token
chmod 600 ~/.openclaw/.env-token
```

### Port and Bind Address

```json
{
  "gateway": {
    "port": 18789,
    "bindAddress": "127.0.0.1"
  }
}
```

- **Port**: Default is 18789. Change if you have conflicts.
- **Bind Address**: 
  - `127.0.0.1` for local only (most secure)
  - `0.0.0.0` for remote access (use with auth)

## Daemon Setup

For production use, run OpenClaw as a system service:

```bash
# Install daemon (auto-detects systemd/LaunchAgent)
openclaw onboard --install-daemon

# Start the service
sudo systemctl start openclaw
sudo systemctl enable openclaw

# Check status
sudo systemctl status openclaw
```

## Generate Configuration

I'll now generate your `openclaw.json` from the template:

```bash
# Copy template
cp ../templates/openclaw.json.template ~/.openclaw/openclaw.json

# Edit with your settings
nano ~/.openclaw/openclaw.json
```

## Validation

Let's verify everything is configured correctly:

```bash
# Run diagnostics
openclaw doctor

# Check for errors
# - API key validity
# - Configuration syntax
# - Gateway connectivity
# - Daemon status
```

**Expected output:** All checks should show `✓ PASS`. If you see any `✗ FAIL`, we'll fix them now.

## Next Steps

Your OpenClaw server is configured! Here's what you can do next:

1. **Set up a channel** - Connect Telegram, Discord, Slack, etc. (use `setup-channel` skill)
2. **Harden security** - Lock down DM policies, file permissions (use `security-hardening` skill)
3. **Test it out** - Send a test message and verify it works

Which would you like to do?
