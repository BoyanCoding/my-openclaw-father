# OpenClaw Installation Test Scenarios

This document defines test scenarios for OpenClaw installation flows. Each scenario specifies a user prompt, expected agent behavior, and key verification checks.

## Scenario 1: Fresh Ubuntu via SSH

**User Prompt:** "Install OpenClaw on 192.168.1.100 via SSH"

**Expected Agent Behavior:**
1. Ask for SSH username (default: `root` or offer `ubuntu`/`admin`)
2. Confirm installation method (recommend `curl` for Ubuntu, offer `wget` fallback)
3. Check OS compatibility (`cat /etc/os-release`)
4. Install using preferred method:
   ```bash
   curl -fsSL https://get.openclaw.io | sh
   # or with custom port/user
   ssh user@192.168.1.100 "curl -fsSL https://get.openclaw.io | sh"
   ```
5. Verify installation: `openclaw version` and check service status

**Key Checks:**
- [ ] Agent asks for SSH credentials before connecting
- [ ] OS detection confirms Ubuntu/Debian compatibility
- [ ] Installation script runs without errors
- [ ] Service is active: `systemctl is-active openclaw`
- [ ] Binary accessible in PATH
- [ ] Version command returns valid output

**Edge Cases to Test:**
- SSH key authentication vs password
- Non-root user with sudo access
- Ubuntu versions: 20.04, 22.04, 24.04
- Minimal Ubuntu (missing curl/wget)

---

## Scenario 2: macOS via npm

**User Prompt:** "Set up OpenClaw on my Mac at 10.0.0.5"

**Expected Agent Behavior:**
1. Connect to macOS host (SSH or local)
2. Detect macOS and check Node.js version (`node --version`)
3. Offer npm method (preferred for macOS)
4. If Node.js < 18: offer to install nvm or update Node
5. Install: `npm install -g @openclaw/cli`
6. Verify: `openclaw version` and check for launchd/plist

**Key Checks:**
- [ ] macOS version detected (Monterey, Ventura, Sonoma, Sequoia)
- [ ] Node.js version checked before npm install
- [ ] Appropriate Node upgrade offered if needed
- [ ] Global npm package installs successfully
- [ ] Binary available: `which openclaw`
- [ ] Permission checks (Homebrew vs manual Node)

**Edge Cases to Test:**
- Node.js not installed
- Node.js 16.x (upgrade needed)
- npm global prefix requires sudo
- Apple Silicon vs Intel Mac

---

## Scenario 3: Docker Deployment on VPS

**User Prompt:** "Deploy OpenClaw in Docker on my VPS at 100.64.0.1"

**Expected Agent Behavior:**
1. Check Docker availability (`docker --version`)
2. Check docker-compose availability
3. Create `docker-compose.yml` with:
   - OpenClaw service image
   - Volume mounts for config (`/etc/openclaw`)
   - Volume mounts for data (`/var/lib/openclaw`)
   - Port mapping (default 8080 or custom)
   - Environment variables for configuration
   - Restart policy (unless-stopped)
   - Network configuration (bridge or host)
4. Offer to customize ports and paths
5. Deploy: `docker-compose up -d`
6. Verify container status and logs

**Key Checks:**
- [ ] Docker engine detected and accessible
- [ ] docker-compose.yml created with valid structure
- [ ] Volume mounts correctly specified
- [ ] Container starts successfully
- [ ] Logs show no critical errors
- [ ] Service responds on configured port
- [ ] Data persists after container restart

**Edge Cases to Test:**
- Docker not installed (offer installation)
- Docker installed but not running
- User without Docker permissions
- Custom port requirements
- Existing docker-compose setup

---

## Scenario 4: Behind Corporate Proxy

**User Prompt:** "Install on server behind corporate proxy"

**Expected Agent Behavior:**
1. Ask for proxy URL and port (e.g., `http://proxy.company.com:8080`)
2. Ask if authentication required (username/password)
3. Set environment variables:
   ```bash
   export HTTP_PROXY=http://proxy.company.com:8080
   export HTTPS_PROXY=http://proxy.company.com:8080
   export NO_PROXY=localhost,127.0.0.1
   ```
4. Configure npm/git/curl to use proxy if needed
5. Run installation with proxy configured
6. Verify connectivity after install

**Key Checks:**
- [ ] Proxy URL format validated
- [ ] Environment variables set correctly
- [ ] Authentication handled if required
- [ ] Installation script uses proxy settings
- [ ] Service can reach external APIs (Anthropic, OpenAI, etc.)
- [ ] Proxy settings persisted in service config or systemd

**Edge Cases to Test:**
- NTLM authentication
- Proxy with SSL inspection
- PAC script instead of direct proxy URL
- Different proxies for HTTP vs HTTPS
- NO_PROXY configuration needed

---

## Scenario 5: Low Disk Space

**User Prompt:** (Context: Server has <500MB free space)

**Expected Agent Behavior:**
1. Check disk space: `df -h /` and `df -h /var`
2. Warn user about insufficient space
3. Calculate minimum required space (500MB base + data)
4. Offer options:
   - Clean up package cache: `apt clean`, `npm cache clean`
   - Remove old logs: `journalctl --vacuum-size=100M`
   - Remove unused packages: `apt autoremove`
   - Install minimal version (skip optional dependencies)
   - Use alternative directory with more space
5. Proceed only if adequate space confirmed

**Key Checks:**
- [ ] Disk space checked before installation
- [ ] User warned about space constraints
- [ ] Cleanup options presented clearly
- [ ] Installation aborts if insufficient space after cleanup
- [ ] Minimal install option available
- [ ] Target directory verified for space

**Edge Cases to Test:**
- Different mount points for / and /var
- Disk quota limits (VPS environments)
- Space freed during cleanup
- Installation on separate data drive

---

## Scenario 6: Upgrade Existing Installation

**User Prompt:** "Update my OpenClaw at 192.168.1.50"

**Expected Agent Behavior:**
1. Check current version: `openclaw version`
2. Check for updates (compare to latest release)
3. Backup current configuration:
   ```bash
   cp /etc/openclaw/config.yaml /etc/openclaw/config.yaml.backup
   ```
4. Stop service: `systemctl stop openclaw` (or Docker equivalent)
5. Run upgrade based on install method:
   - curl: `curl -fsSL https://get.openclaw.io | sh`
   - npm: `npm update -g @openclaw/cli`
   - Docker: `docker-compose pull && docker-compose up -d`
6. Verify version change
7. Test configuration compatibility
8. Start service and verify

**Key Checks:**
- [ ] Current version detected
- [ ] Configuration backed up before upgrade
- [ ] Service stopped gracefully
- [ ] Upgrade method matches original install
- [ ] Version increment verified
- [ ] Config validated (no breaking changes)
- [ ] Service starts successfully
- [ ] Backup restoration offered if fails

**Edge Cases to Test:**
- Major version upgrade (breaking changes)
- Config schema changes requiring migration
- Upgrade from very old version
- Service fails to start after upgrade
- Manual config modifications that conflict

---

## Scenario 7: Non-Standard SSH Port

**User Prompt:** "Install on server at 10.0.0.1 port 2222"

**Expected Agent Behavior:**
1. Accept custom port in connection string
2. Use SSH with `-p` flag:
   ```bash
   ssh -p 2222 user@10.0.0.1 "curl -fsSL https://get.openclaw.io | sh"
   ```
3. For SCP/file transfers, use `-P 2222`
4. Store port in config if setting up persistent connection
5. Offer to add to SSH config for convenience

**Key Checks:**
- [ ] Custom port specified correctly in SSH command
- [ ] Connection succeeds on non-standard port
- [ ] Installation completes remotely
- [ ] Agent doesn't default to port 22
- [ ] Port format validated (1-65535)

**Edge Cases to Test:**
- Port blocked by firewall
- SSH key on custom port
- Connection timeout on custom port
- Port parameter passed incorrectly by user

---

## Testing Notes

**Prerequisites for Running These Scenarios:**
- Test VMs or containers for each target OS
- SSH access configured
- Ability to snapshot/rollback test environments
- Mock server for testing proxy scenarios
- Disk space simulation (create small test volumes)

**Automation Potential:**
- Scenarios 1, 2, 3, 6 can be fully automated with pytest+asyncssh
- Scenarios 4, 5 require environment mocking
- Scenario 7 is trivial to automate

**Success Criteria:**
- All key checks pass for each scenario
- Installation completes without manual intervention
- Service is functional after install
- Configuration persists appropriately
