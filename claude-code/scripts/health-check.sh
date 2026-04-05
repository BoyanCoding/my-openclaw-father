#!/usr/bin/env bash
#
# OpenClaw Health Check Script
# Usage: ./health-check.sh --host USER@HOST [--port 22] [--check full|quick|channels|models] [--json] [--fix]
#
# Performs health checks on a remote OpenClaw installation via SSH.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PORT="22"
DEFAULT_CHECK="full"
JSON_OUTPUT=false
ATTEMPT_FIX=false

# Logging functions
log_info() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${GREEN}[PASS]${NC} $1"
    fi
    echo "PASS: $1" >> "$TEMP_RESULTS"
}

log_warning() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
    echo "WARN: $1" >> "$TEMP_RESULTS"
}

log_error() {
    if [[ "$JSON_OUTPUT" == false ]]; then
        echo -e "${RED}[FAIL]${NC} $1"
    fi
    echo "FAIL: $1" >> "$TEMP_RESULTS"
}

# Usage function
usage() {
    cat << EOF
Usage: $(basename "$0") --host USER@HOST [OPTIONS]

Perform health checks on a remote OpenClaw installation.

Required Arguments:
  --host USER@HOST        SSH target in user@host format

Options:
  --port PORT             SSH port (default: 22)
  --check TYPE            Check type: full, quick, channels, models (default: full)
  --json                  Output results as JSON
  --fix                   Attempt to fix common issues
  -h, --help              Show this help message

Check Types:
  full        Complete health check (version, doctor, disk, memory, channels, models)
  quick       Basic connectivity and version check
  channels    Verify configured channel connections
  models      Test model provider API connectivity

Exit Codes:
  0      All checks passed
  1      Some checks failed

Examples:
  # Full health check
  $(basename "$0") --host user@example.com

  # Quick check with JSON output
  $(basename "$0") --host user@example.com --check quick --json

  # Check only channel connections
  $(basename "$0") --host user@example.com --check channels

  # Check and attempt to fix issues
  $(basename "$0") --host user@example.com --check full --fix

EOF
    exit 0
}

# Parse arguments
HOST=""
CHECK_TYPE=""
PORT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --check)
            CHECK_TYPE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --fix)
            ATTEMPT_FIX=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$HOST" ]]; then
    echo "Missing required argument: --host" >&2
    usage
fi

# Set defaults
PORT="${PORT:-$DEFAULT_PORT}"
CHECK_TYPE="${CHECK_TYPE:-$DEFAULT_CHECK}"

# Validate check type
if [[ ! "$CHECK_TYPE" =~ ^(full|quick|channels|models)$ ]]; then
    echo "Invalid check type: $CHECK_TYPE" >&2
    exit 1
fi

# Create temp file for results
TEMP_RESULTS=$(mktemp)
trap "rm -f $TEMP_RESULTS" EXIT

# JSON output initialization
if [[ "$JSON_OUTPUT" == true ]]; then
    echo '{"host": "'"$HOST"'", "port": '"$PORT"', "check_type": "'"$CHECK_TYPE"'", "results": ['
    FIRST_RESULT=true
fi

# SSH command wrapper
ssh_exec() {
    ssh -o ConnectTimeout=10 -p "$PORT" "$HOST" "$@" 2>&1
}

# JSON result helper
add_json_result() {
    local status="$1"
    local check="$2"
    local message="$3"
    local details="${4:-}"

    if [[ "$JSON_OUTPUT" == true ]]; then
        if [[ "$FIRST_RESULT" == true ]]; then
            FIRST_RESULT=false
        else
            echo ","
        fi
        echo "{\"status\": \"$status\", \"check\": \"$check\", \"message\": \"$message\", \"details\": \"$details\"}" | sed 's/"/\\"/g'
    fi
}

# Initialize counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# Header
if [[ "$JSON_OUTPUT" == false ]]; then
    echo "====================================="
    echo "OpenClaw Health Check"
    echo "====================================="
    echo "Host: $HOST"
    echo "Port: $PORT"
    echo "Check Type: $CHECK_TYPE"
    echo "Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo ""
fi

# Quick check
if [[ "$CHECK_TYPE" == "quick" ]] || [[ "$CHECK_TYPE" == "full" ]]; then
    log_info "Running quick checks..."

    # Version check
    log_info "Checking OpenClaw version..."
    VERSION_OUTPUT=$(ssh_exec "openclaw --version 2>/dev/null" || echo "command not found")
    if [[ "$VERSION_OUTPUT" == *"command not found"* ]]; then
        log_error "OpenClaw not found or not in PATH"
        add_json_result "FAIL" "version" "OpenClaw not found"
        ((FAIL_COUNT++))
    else
        log_success "OpenClaw version: $VERSION_OUTPUT"
        add_json_result "PASS" "version" "OpenClaw installed" "$VERSION_OUTPUT"
        ((PASS_COUNT++))
    fi

    # Gateway status
    log_info "Checking gateway status..."
    GATEWAY_STATUS=$(ssh_exec "openclaw gateway status 2>/dev/null" || echo "unknown")
    if [[ "$GATEWAY_STATUS" == *"running"* ]] || [[ "$GATEWAY_STATUS" == *"active"* ]]; then
        log_success "Gateway is running"
        add_json_result "PASS" "gateway" "Gateway running"
        ((PASS_COUNT++))
    elif [[ "$GATEWAY_STATUS" == *"stopped"* ]] || [[ "$GATEWAY_STATUS" == *"inactive"* ]]; then
        log_error "Gateway is not running"
        add_json_result "FAIL" "gateway" "Gateway not running"
        ((FAIL_COUNT++))

        if [[ "$ATTEMPT_FIX" == true ]]; then
            log_info "Attempting to start gateway..."
            ssh_exec "openclaw gateway start" >/dev/null 2>&1 || true
            sleep 2
            GATEWAY_STATUS=$(ssh_exec "openclaw gateway status 2>/dev/null" || echo "unknown")
            if [[ "$GATEWAY_STATUS" == *"running"* ]]; then
                log_success "Gateway started successfully"
            fi
        fi
    else
        log_warning "Gateway status unknown: $GATEWAY_STATUS"
        add_json_result "WARN" "gateway" "Status unknown" "$GATEWAY_STATUS"
        ((WARN_COUNT++))
    fi

    # Basic connectivity
    log_info "Testing basic connectivity..."
    if ssh_exec "echo ok" >/dev/null 2>&1; then
        log_success "SSH connectivity OK"
        add_json_result "PASS" "connectivity" "SSH connection successful"
        ((PASS_COUNT++))
    else
        log_error "SSH connectivity failed"
        add_json_result "FAIL" "connectivity" "SSH connection failed"
        ((FAIL_COUNT++))
    fi
fi

# Full check
if [[ "$CHECK_TYPE" == "full" ]]; then
    log_info "Running full diagnostics..."

    # Doctor output
    log_info "Running openclaw doctor..."
    DOCTOR_OUTPUT=$(ssh_exec "openclaw doctor 2>/dev/null" || echo "doctor failed")
    if [[ "$DOCTOR_OUTPUT" != *"doctor failed"* ]]; then
        # Parse doctor output for issues
        if echo "$DOCTOR_OUTPUT" | grep -q "error\|Error\|ERROR\|fail\|Fail\|FAIL"; then
            log_warning "Doctor found potential issues"
            add_json_result "WARN" "doctor" "Issues found" "$(echo "$DOCTOR_OUTPUT" | head -5)"
            ((WARN_COUNT++))
        else
            log_success "Doctor check passed"
            add_json_result "PASS" "doctor" "All checks passed"
            ((PASS_COUNT++))
        fi
    else
        log_error "Doctor command failed"
        add_json_result "FAIL" "doctor" "Doctor command failed"
        ((FAIL_COUNT++))
    fi

    # Disk space
    log_info "Checking disk space..."
    DISK_INFO=$(ssh_exec "df -h / | tail -1" || echo "")
    if [[ -n "$DISK_INFO" ]]; then
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_USED_PCT=$(echo "$DISK_INFO" | awk '{print $5}' | sed 's/%//')
        log_success "Disk available: $DISK_AVAIL (${DISK_USED_PCT}% used)"
        add_json_result "PASS" "disk" "Disk space OK" "$DISK_AVAIL available"
        ((PASS_COUNT++))

        if [[ "$DISK_USED_PCT" -gt 90 ]]; then
            log_warning "Disk usage over 90%"
            add_json_result "WARN" "disk_capacity" "Disk over 90% full" "${DISK_USED_PCT}% used"
            ((WARN_COUNT++))
        fi
    else
        log_error "Could not check disk space"
        add_json_result "FAIL" "disk" "Could not check disk space"
        ((FAIL_COUNT++))
    fi

    # Memory
    log_info "Checking memory..."
    if [[ "$JSON_OUTPUT" == false ]]; then
        MEMORY_INFO=$(ssh_exec "free -h" || echo "")
        if [[ -n "$MEMORY_INFO" ]]; then
            MEM_AVAIL=$(echo "$MEMORY_INFO" | grep Mem | awk '{print $7}')
            log_success "Memory available: $MEM_AVAIL"
            add_json_result "PASS" "memory" "Memory OK" "$MEM_AVAIL available"
            ((PASS_COUNT++))
        fi
    fi

    # Node version
    log_info "Checking Node.js version..."
    NODE_VERSION=$(ssh_exec "node --version 2>/dev/null" || echo "not found")
    if [[ "$NODE_VERSION" != *"not found"* ]]; then
        log_success "Node.js version: $NODE_VERSION"
        add_json_result "PASS" "node_version" "Node.js installed" "$NODE_VERSION"
        ((PASS_COUNT++))

        # Check if version is too old
        NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
        if [[ "$NODE_MAJOR" -lt 18 ]]; then
            log_warning "Node.js version is old (recommend 18+)"
            add_json_result "WARN" "node_version_old" "Node.js < 18" "$NODE_VERSION"
            ((WARN_COUNT++))
        fi
    else
        log_error "Node.js not found"
        add_json_result "FAIL" "node_version" "Node.js not found"
        ((FAIL_COUNT++))
    fi
fi

# Channels check
if [[ "$CHECK_TYPE" == "channels" ]] || [[ "$CHECK_TYPE" == "full" ]]; then
    log_info "Checking channel configurations..."

    # Get config file location
    CONFIG_FILE=$(ssh_exec "ls ~/.openclaw/openclaw.json 2>/dev/null || ls /etc/openclaw/openclaw.json 2>/dev/null" || echo "")

    if [[ -n "$CONFIG_FILE" ]]; then
        # Extract enabled channels
        ENABLED_CHANNELS=$(ssh_exec "cat $CONFIG_FILE 2>/dev/null | grep -o '\"channel\": \"[^\"]*\"' | cut -d'"' -f4 | tr '\n' ' '" || echo "")

        if [[ -n "$ENABLED_CHANNELS" ]]; then
            for channel in $ENABLED_CHANNELS; do
                log_info "Checking channel: $channel"
                # Check if channel process is running
                CHANNEL_CHECK=$(ssh_exec "ps aux | grep -i '$channel' | grep -v grep" || echo "")
                if [[ -n "$CHANNEL_CHECK" ]]; then
                    log_success "Channel $channel is running"
                    add_json_result "PASS" "channel_$channel" "Channel active"
                    ((PASS_COUNT++))
                else
                    log_warning "Channel $channel may not be running"
                    add_json_result "WARN" "channel_$channel" "Channel not detected"
                    ((WARN_COUNT++))
                fi
            done
        else
            log_warning "No channels found in configuration"
            add_json_result "WARN" "channels" "No channels configured"
            ((WARN_COUNT++))
        fi
    else
        log_error "OpenClaw configuration file not found"
        add_json_result "FAIL" "channels_config" "Config file not found"
        ((FAIL_COUNT++))
    fi
fi

# Models check
if [[ "$CHECK_TYPE" == "models" ]] || [[ "$CHECK_TYPE" == "full" ]]; then
    log_info "Checking model provider configurations..."

    # Check for auth profiles
    AUTH_FILE=$(ssh_exec "ls ~/.openclaw/auth-profiles.json 2>/dev/null || echo ''" || echo "")

    if [[ -n "$AUTH_FILE" ]]; then
        # Extract configured providers
        PROVIDERS=$(ssh_exec "cat $AUTH_FILE 2>/dev/null | grep -o '\"provider\": \"[^\"]*\"' | cut -d'"' -f4 | sort -u" || echo "")

        if [[ -n "$PROVIDERS" ]]; then
            for provider in $PROVIDERS; do
                log_info "Checking provider: $provider"

                # Check if API key is set (via environment variable)
                case "$provider" in
                    anthropic)
                        API_KEY_VAR="ANTHROPIC_API_KEY"
                        ;;
                    openai)
                        API_KEY_VAR="OPENAI_API_KEY"
                        ;;
                    google)
                        API_KEY_VAR="GOOGLE_API_KEY"
                        ;;
                    mistral)
                        API_KEY_VAR="MISTRAL_API_KEY"
                        ;;
                    openrouter)
                        API_KEY_VAR="OPENROUTER_API_KEY"
                        ;;
                    ollama)
                        API_KEY_VAR="OLLAMA_HOST"
                        ;;
                    *)
                        API_KEY_VAR="${provider^^}_API_KEY"
                        ;;
                esac

                KEY_SET=$(ssh_exec "echo \${${API_KEY_VAR}:-notset}" 2>/dev/null || echo "notset")

                if [[ "$KEY_SET" != "notset" ]]; then
                    log_success "Provider $provider: API credentials configured"
                    add_json_result "PASS" "provider_$provider" "Credentials configured"
                    ((PASS_COUNT++))
                else
                    log_warning "Provider $provider: API credentials not set ($API_KEY_VAR)"
                    add_json_result "WARN" "provider_$provider" "Credentials missing" "$API_KEY_VAR"
                    ((WARN_COUNT++))
                fi
            done
        else
            log_warning "No providers found in auth profiles"
            add_json_result "WARN" "providers" "No providers configured"
            ((WARN_COUNT++))
        fi
    else
        log_warning "Auth profiles file not found"
        add_json_result "WARN" "auth_profiles" "Auth profiles not configured"
        ((WARN_COUNT++))
    fi
fi

# Final summary
if [[ "$JSON_OUTPUT" == false ]]; then
    echo ""
    echo "====================================="
    echo "Health Check Summary"
    echo "====================================="
    echo "Completed: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "Total Checks: $((PASS_COUNT + WARN_COUNT + FAIL_COUNT))"
    echo -e "  ${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "  ${YELLOW}Warnings: $WARN_COUNT${NC}"
    echo -e "  ${RED}Failed: $FAIL_COUNT${NC}"
    echo ""

    if [[ "$FAIL_COUNT" -eq 0 ]] && [[ "$WARN_COUNT" -eq 0 ]]; then
        log_success "All checks passed!"
        exit 0
    elif [[ "$FAIL_COUNT" -eq 0 ]]; then
        log_warning "Checks passed with warnings"
        exit 0
    else
        log_error "Some checks failed"
        exit 1
    fi
else
    # Close JSON array
    echo ""
    echo '], "summary": {'
    echo "  \"total\": $((PASS_COUNT + WARN_COUNT + FAIL_COUNT)),"
    echo "  \"passed\": $PASS_COUNT,"
    echo "  \"warnings\": $WARN_COUNT,"
    echo "  \"failed\": $FAIL_COUNT"
    echo '}}'

    if [[ "$FAIL_COUNT" -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
fi
