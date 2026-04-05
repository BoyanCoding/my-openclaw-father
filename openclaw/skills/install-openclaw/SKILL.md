---
name: install-openclaw
description: Install OpenClaw on a remote server via SSH. Covers curl, npm, and Docker methods. Use when the user wants to set up a new OpenClaw instance.
---

# Installing OpenClaw

Welcome! Let's get OpenClaw installed on your server. I'll guide you through this step-by-step.

## Prerequisites Check

Before we begin, let's verify your server is ready:

1. **SSH Access**: Ensure you can connect to your server via SSH
   ```bash
   ssh user@your-server
   ```

2. **Operating System**: Check your OS
   ```bash
   cat /etc/os-release
   ```

3. **Disk Space**: Verify you have at least 500MB free
   ```bash
   df -h /
   ```

Please run these commands and confirm your server meets the requirements before proceeding.

## Choose Your Installation Method

OpenClaw can be installed three ways. Here's a comparison:

| Method | Speed | Flexibility | Isolation | Best For |
|--------|-------|-------------|-----------|----------|
| **curl** | ⚡ Fastest | Medium | ❌ None | Quick setups, VPS, direct control |
| **npm** | 🐢 Moderate | High | ❌ None | Node.js environments, custom plugins |
| **Docker** | 🚀 Fast | Low | ✅ Yes | Contained deployments, easy updates |

Which installation method would you like to use? I'll walk you through the specific steps for your choice.

## Before We Proceed

I'll always fetch the latest installation documentation to ensure you're getting the most up-to-date instructions. Let me check docs.openclaw.ai/install now.

*(Fetch and review latest docs before proceeding with installation)*

## Installation Steps

### Method 1: curl (Recommended for most users)

This is the fastest way to get OpenClaw running:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**What this does:**
- Downloads the latest OpenClaw binary
- Installs to `/usr/local/bin` (or adds to PATH)
- Sets up the base configuration directory

**After running:**
```bash
# Verify installation
openclaw --version

# Check gateway status
openclaw gateway status
```

### Method 2: npm (For Node.js environments)

Best if you already use Node.js and want plugin flexibility:

```bash
# Install globally
npm install -g openclaw@latest

# Initialize and install daemon
openclaw onboard --install-daemon
```

**What this does:**
- Installs OpenClaw via npm registry
- Runs the onboard wizard to set up basic config
- Installs the system daemon (systemd on Linux, LaunchAgent on macOS)

### Method 3: Docker (For isolated deployments)

Best for production or when you want easy updates:

```bash
# Pull the latest image
docker pull openclaw/openclaw:latest

# Create a docker-compose.yml file
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  openclaw:
    image: openclaw/openclaw:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - openclaw-data:/root/.openclaw
      - openclaw-workspaces:/openclaw/workspaces
    environment:
      - OPENCLAW_MODE=production
EOF

# Start the gateway
docker-compose up -d
```

**What this does:**
- Pulls the official OpenClaw image
- Creates a persistent volume for configuration
- Exposes the gateway on port 18789
- Runs in production mode with auto-restart

## Post-Installation Verification

After installation, let's verify everything is working:

```bash
# Check version
openclaw --version

# Check gateway status
openclaw gateway status

# Run diagnostics
openclaw doctor
```

All commands should complete without errors. If you see any issues, let me know!

## Error Handling

### Network Issues
If the download fails:
```bash
# Check internet connectivity
curl -I https://openclaw.ai

# Try with explicit proxy settings (if needed)
export https_proxy=your-proxy-url
curl -fsSL https://openclaw.ai/install.sh | bash
```

### Permission Issues
If you get "Permission denied" errors:
```bash
# Install to user directory instead
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --prefix=$HOME/.local

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Disk Space Issues
If you're low on disk space:
```bash
# Clean package cache (if using npm)
npm cache clean --force

# Remove old Docker images (if using Docker)
docker system prune -a
```

## Next Steps

Congratulations! Once OpenClaw is installed and verified, we should configure it for your needs.

**Recommended next step:** Use the `configure-server` skill to set up your model provider, agent configuration, and gateway settings.

Would you like to proceed with configuration now?
