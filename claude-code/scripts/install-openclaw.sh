#!/usr/bin/env bash
#
# OpenClaw Remote Installation Script
# Usage: ./install-openclaw.sh --host USER@HOST [--method curl|npm|docker] [--port 22] [--no-onboard] [--dry-run]
#
# This script installs OpenClaw on a remote host via SSH.
# Supports multiple installation methods and includes pre-flight checks.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_METHOD="curl"
DEFAULT_PORT="22"
DRY_RUN=false
SKIP_ONBOARD=false

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Usage: $(basename "$0") --host USER@HOST [OPTIONS]

Install OpenClaw on a remote host via SSH.

Required Arguments:
  --host USER@HOST        SSH target in user@host format

Options:
  --method METHOD         Installation method: curl, npm, or docker (default: curl)
  --port PORT             SSH port (default: 22)
  --no-onboard            Skip post-install onboarding
  --dry-run               Show what would be executed without running
  -h, --help              Show this help message

Installation Methods:
  curl    Install via official install script (recommended, works on most systems)
  npm     Install via npm (requires Node.js and npm on remote host)
  docker  Install as Docker container (requires Docker on remote host)

Exit Codes:
  0      Success
  1      SSH connection failed
  2      Installation failed
  3      Post-install verification failed

Examples:
  # Basic installation
  $(basename "$0") --host user@example.com

  # Install via npm on custom port
  $(basename "$0") --host user@example.com --method npm --port 2222

  # Dry run to see what would happen
  $(basename "$0") --host user@example.com --method docker --dry-run

EOF
    exit 0
}

# Parse arguments
HOST=""
METHOD=""
PORT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --method)
            METHOD="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --no-onboard)
            SKIP_ONBOARD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$HOST" ]]; then
    log_error "Missing required argument: --host"
    usage
fi

# Set defaults
METHOD="${METHOD:-$DEFAULT_METHOD}"
PORT="${PORT:-$DEFAULT_PORT}"

# Validate method
if [[ ! "$METHOD" =~ ^(curl|npm|docker)$ ]]; then
    log_error "Invalid method: $METHOD. Must be one of: curl, npm, docker"
    exit 2
fi

# Validate host format
if [[ ! "$HOST" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    log_error "Invalid host format. Expected: USER@HOST"
    exit 1
fi

# Dry run notice
if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE: Commands will be shown but not executed"
    echo ""
fi

# SSH command wrapper
ssh_cmd() {
    local cmd="$1"
    if [[ "$DRY_RUN" == true ]]; then
        echo "Would execute: ssh -o ConnectTimeout=10 -p $PORT $HOST \"$cmd\""
    else
        ssh -o ConnectTimeout=10 -p "$PORT" "$HOST" "$cmd"
    fi
}

# Step 1: Verify SSH connectivity
log_info "Step 1: Verifying SSH connectivity to $HOST (port $PORT)..."
if ! ssh_cmd "echo ok" > /dev/null 2>&1; then
    log_error "SSH connection failed. Please check:"
    echo "  - Host is reachable"
    echo "  - SSH port $PORT is open"
    echo "  - Your SSH keys are configured"
    echo "  - User has sudo privileges (for installation)"
    exit 1
fi
log_success "SSH connection verified"

# Step 2: Detect remote OS
log_info "Step 2: Detecting remote OS..."
OS_INFO=$(ssh_cmd "cat /etc/os-release 2>/dev/null || sw_vers 2>/dev/null || echo 'Unknown OS'")
log_success "Remote OS detected:"
echo "$OS_INFO" | head -3 | sed 's/^/  /'

# Step 3: Check disk space
log_info "Step 3: Checking available disk space..."
DISK_AVAIL=$(ssh_cmd "df -h / | tail -1 | awk '{print \$4}'")
log_success "Available disk space: $DISK_AVAIL"

# Step 4: Installation based on method
log_info "Step 4: Installing OpenClaw via $METHOD method..."
case "$METHOD" in
    curl)
        log_info "Downloading and running official install script..."
        if ssh_cmd "curl -fsSL https://openclaw.ai/install.sh | bash"; then
            log_success "Installation via curl completed"
        else
            log_error "Installation via curl failed"
            exit 2
        fi
        ;;
    npm)
        log_info "Installing via npm..."
        if ssh_cmd "command -v npm >/dev/null 2>&1 || { echo 'npm not found. Installing...'; curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs; }"; then
            if ssh_cmd "npm install -g openclaw@latest"; then
                log_success "OpenClaw installed via npm"
                if [[ "$SKIP_ONBOARD" == false ]]; then
                    log_info "Running onboarding with daemon install..."
                    ssh_cmd "openclaw onboard --install-daemon" || log_warning "Onboarding failed, but installation succeeded"
                fi
            else
                log_error "npm install failed"
                exit 2
            fi
        else
            log_error "Failed to ensure npm is available"
            exit 2
        fi
        ;;
    docker)
        log_info "Installing via Docker..."
        if ssh_cmd "command -v docker >/dev/null 2>&1 || { echo 'Docker not found. Please install Docker first.'; exit 1; }"; then
            if ssh_cmd "docker pull openclaw/openclaw:latest"; then
                log_success "Docker image pulled"

                # Create docker-compose.yml
                log_info "Creating docker-compose.yml..."
                ssh_cmd "mkdir -p ~/openclaw-docker && cat > ~/openclaw-docker/docker-compose.yml << 'EOF'
version: '3.8'
services:
  openclaw:
    image: openclaw/openclaw:latest
    container_name: openclaw
    restart: unless-stopped
    volumes:
      - ./config:/app/openclaw/config
      - ./logs:/app/openclaw/logs
      - ./knowledge:/app/openclaw/knowledge
    environment:
      - OPENCLAW_AUTO_START=true
    ports:
      - \"3000:3000\"
EOF
                "
                log_success "Docker compose file created at ~/openclaw-docker/docker-compose.yml"

                if [[ "$SKIP_ONBOARD" == false ]] && [[ "$DRY_RUN" == false ]]; then
                    log_info "To start OpenClaw, run on remote host:"
                    echo "  cd ~/openclaw-docker && docker-compose up -d"
                fi
            else
                log_error "Docker pull failed"
                exit 2
            fi
        else
            log_error "Docker is not available on remote host"
            exit 2
        fi
        ;;
esac

# Step 5: Post-install verification
log_info "Step 5: Verifying installation..."
VERSION_CHECK=$(ssh_cmd "openclaw --version 2>/dev/null" || echo "failed")
DOCTOR_CHECK=$(ssh_cmd "openclaw doctor 2>/dev/null" || echo "failed")

if [[ "$VERSION_CHECK" == "failed" ]]; then
    log_error "OpenClaw not found after installation"
    exit 3
fi

log_success "Installation verified!"
echo ""
echo "Version: $VERSION_CHECK"
echo "Doctor output:"
echo "$DOCTOR_CHECK" | sed 's/^/  /'

# Final summary
echo ""
log_success "OpenClaw installation completed successfully!"
echo ""
echo "Installation Summary:"
echo "  Host: $HOST"
echo "  Method: $METHOD"
echo "  Port: $PORT"
echo "  Version: $VERSION_CHECK"
echo ""
echo "Next Steps:"
if [[ "$METHOD" == "docker" ]]; then
    echo "  1. SSH into the host: ssh -p $PORT $HOST"
    echo "  2. Navigate to docker directory: cd ~/openclaw-docker"
    echo "  3. Start the container: docker-compose up -d"
    echo "  4. Check logs: docker-compose logs -f"
else
    echo "  1. Configure OpenClaw: edit ~/.openclaw/openclaw.json"
    echo "  2. Add API keys for your chosen provider"
    echo "  3. Start the gateway: openclaw gateway start"
    echo "  4. Check status: openclaw gateway status"
fi

exit 0
