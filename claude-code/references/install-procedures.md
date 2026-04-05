# OpenClaw Installation Procedures

This guide covers all installation methods for OpenClaw, from quick one-liners to advanced Docker setups.

## Prerequisites

### System Requirements
- **Operating Systems**: macOS, Linux, Windows (WSL2 recommended), native Windows support
- **Node.js**: 
  - **Recommended**: Node.js 24.x
  - **Minimum**: Node.js 22.14+
  - **Auto-installation**: Method 1 (curl) will install Node if needed
- **Disk Space**: ~500MB for OpenClaw + workspace storage
- **Network**: Internet connection for model provider APIs

### Verify Node.js Version
```bash
node -v  # Should show v24.x.x or v22.14.0+
npm -v   # Should show compatible npm version
```

## Installation Methods

### Method 1: curl One-Liner (Recommended)

**Fastest method** - Auto-detects your OS, installs Node if needed, configures everything.

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**What it does:**
- Detects OS (macOS/Linux/WSL2)
- Checks for Node.js 22.14+, installs if missing
- Downloads latest OpenClaw release
- Installs to `/usr/local/bin` or `~/.local/bin`
- Adds to PATH if needed
- Sets up daemon configuration directory

**Post-install:**
```bash
openclaw --version
openclaw doctor
```

**Troubleshooting:**
- **Permission denied**: Prefix with `sudo` (Linux/macOS)
- **Corporate proxy**: Use `curl -x http://proxy:port -fsSL https://openclaw.ai/install.sh | bash`
- **Network timeout**: Check firewall, try alternative mirror

### Method 2: npm Global Install

**For users who manage Node themselves** - Assumes you have Node.js 22.14+ already.

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

**What it does:**
- Installs OpenClaw globally via npm registry
- Onboarding wizard configures model provider and gateway
- Installs and starts the daemon service

**Alternative package managers:**

**pnpm:**
```bash
pnpm add -g openclaw@latest
openclaw onboard --install-daemon
```

**bun:**
```bash
bun add -g openclaw@latest
openclaw onboard --install-daemon
```

**Troubleshooting:**
- **'openclaw' not found**: Add npm global bin to PATH:
  ```bash
  export PATH="$(npm prefix -g)/bin:$PATH"
  echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.bashrc  # or ~/.zshrc
  ```
- **EACCES permission error**: Use `sudo` or fix npm permissions:
  ```bash
  mkdir -p ~/.npm-global
  npm config set prefix '~/.npm-global'
  export PATH="~/.npm-global/bin:$PATH"
  ```

### Method 3: Docker

**For isolated deployments** - Runs OpenClaw in containers with gateway.

#### Quick Start (Single Container)
```bash
docker pull openclaw/openclaw:latest
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  -v ~/.openclaw:/app/.openclaw \
  -v ~/openclaw-workspace:/workspace \
  openclaw/openclaw:latest
```

#### Docker Compose (Production Setup)
```yaml
# docker-compose.yml
version: '3.8'
services:
  openclaw:
    image: openclaw/openclaw:latest
    container_name: openclaw-gateway
    ports:
      - "18789:18789"
    volumes:
      - ~/.openclaw:/app/.openclaw:ro
      - ~/openclaw-workspace:/workspace:rw
      - openclaw-logs:/tmp/openclaw
    environment:
      - NODE_ENV=production
      - OPENCLAW_HOME=/app/.openclaw
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  openclaw-logs:
```

```bash
docker compose up -d
docker compose logs -f  # View logs
```

**Troubleshooting:**
- **Volume mount errors**: Ensure host directories exist, check permissions
- **Port conflicts**: Change port mapping (`-p 18790:18789`)
- **Permission errors**: Run with `--user $(id -u):$(id -g)`

### Method 4: From Source

**For developers** - Build from repository.

```bash
# Clone repository
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Install dependencies
pnpm install

# Build
pnpm build

# Link globally
pnpm link --global

# Verify
openclaw --version
```

**Development mode:**
```bash
pnpm dev  # Runs with hot-reload
```

**Troubleshooting:**
- **Build failures**: Ensure Node.js 24.x, clear cache: `rm -rf node_modules pnpm-lock.yaml && pnpm install`
- **Link errors**: Use `sudo` for global link, or add `node_modules/.bin` to PATH

### Method 5: Local Prefix Installer

**For user-space only installation** - No sudo required.

```bash
curl -fsSL https://openclaw.ai/install-cli.sh | bash
```

**What it does:**
- Installs to `~/.openclaw/bin`
- Adds to PATH via `~/.bashrc` or `~/.zshrc`
- Does not install daemon or system services

**Post-install:**
```bash
# Reload shell or:
export PATH="$HOME/.openclaw/bin:$PATH"
openclaw --version
```

## Post-Installation

### Verification
```bash
# Check version
openclaw --version

# Run diagnostics
openclaw doctor

# Check gateway status
openclaw gateway status
```

### Onboarding Wizard
```bash
openclaw onboard --install-daemon
```

**The wizard guides you through:**
1. Model provider selection (Anthropic, OpenAI, Google, etc.)
2. API key entry and validation
3. Gateway configuration (port, authentication)
4. Channel setup (Telegram, Discord, Slack)
5. Daemon installation and startup

**Manual daemon start:**
```bash
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
```

## Environment Variables

Configure OpenClaw behavior via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_HOME` | `~/.openclaw` | Configuration directory |
| `OPENCLAW_STATE_DIR` | `$OPENCLAW_HOME/state` | Runtime state directory |
| `OPENCLAW_CONFIG_PATH` | `$OPENCLAW_HOME/openclaw.json` | Main config file path |
| `OPENCLAW_LOG_DIR` | `/tmp/openclaw` | Log directory |
| `OPENCLAW_WORKSPACE` | `~/openclaw-workspace` | Agent workspace directory |

**Example:**
```bash
export OPENCLAW_HOME=/opt/openclaw
export OPENCLAW_WORKSPACE=/data/workspace
openclaw gateway start
```

## Installation Method Comparison

| Method | Speed | Isolation | Updates | Prerequisites | Best For |
|--------|-------|-----------|---------|---------------|----------|
| **curl (Method 1)** | ⚡ Fastest | System | Manual re-run | None | Quick start, most users |
| **npm (Method 2)** | 🚀 Fast | System | `npm update -g` | Node.js 22.14+ | Node.js users, developers |
| **Docker (Method 3)** | 🐳 Medium | Container | `docker pull` | Docker | Production, isolated deployments |
| **Source (Method 4)** | 🐌 Slowest | System | `git pull` | Node.js, pnpm, Git | Contributors, custom builds |
| **Local Prefix (Method 5)** | ⚡ Fast | User-space | Manual re-run | None | Multi-user systems, no sudo |

## Upgrading

### Using curl
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

### Using npm
```bash
npm update -g openclaw@latest
```

### Using Docker
```bash
docker pull openclaw/openclaw:latest
docker compose up -d  # Recreates container with new image
```

### From Source
```bash
git pull origin main
pnpm install
pnpm build
pnpm link --global
```

## Uninstallation

### Remove CLI
```bash
# If installed via curl
sudo rm -f /usr/local/bin/openclaw

# If installed via npm
npm uninstall -g openclaw

# If installed via pnpm
pnpm remove -g openclaw
```

### Remove Data and Config
```bash
# Stop daemon first
openclaw gateway stop

# Remove configuration and state
rm -rf ~/.openclaw
rm -rf ~/openclaw-workspace
rm -rf /tmp/openclaw

# Optional: Remove Docker data
docker rm -f openclaw
docker volume rm openclaw-logs
```

## Next Steps

After installation:
1. Complete onboarding: `openclaw onboard --install-daemon`
2. Configure model providers (see [model-providers.md](./model-providers.md))
3. Set up channels (see [channel-setup-guides.md](./channel-setup-guides.md))
4. Review security checklist (see [security-checklist.md](./security-checklist.md))
5. Test with a simple agent task

## Troubleshooting Installation

### Permission Denied
```bash
# Solution: Use sudo for system-wide install
sudo curl -fsSL https://openclaw.ai/install.sh | bash
```

### Network Timeout
```bash
# Solution: Use proxy or mirror
curl -x http://proxy:port -fsSL https://openclaw.ai/install.sh | bash
```

### Node Version Mismatch
```bash
# Solution: Install correct Node version using nvm
nvm install 24
nvm use 24
curl -fsSL https://openclaw.ai/install.sh | bash
```

### Disk Space Issues
```bash
# Check available space
df -h

# Clean npm cache if using npm install
npm cache clean --force
```

### Daemon Won't Start
```bash
# Check logs
tail -f /tmp/openclaw/openclaw.log

# Verify configuration
openclaw doctor

# Check port availability
lsof -i :18789
```

For additional help, see [troubleshooting.md](./troubleshooting.md).
