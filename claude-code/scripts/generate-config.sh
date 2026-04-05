#!/usr/bin/env bash
#
# OpenClaw Configuration Generator
# Usage: ./generate-config.sh --provider anthropic --channel telegram [--output /path/to/openclaw.json] [--template base|full]
#
# Generates OpenClaw configuration files from templates with provider and channel settings.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
INTERACTIVE=false
OUTPUT=""
TEMPLATE="base"

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
Usage: $(basename "$0") --provider PROVIDER --channel CHANNEL [OPTIONS]

Generate an OpenClaw configuration file from templates.

Required Arguments:
  --provider PROVIDER      AI provider: anthropic, openai, google, mistral, openrouter, ollama
  --channel CHANNEL        Communication channel: telegram, discord, slack, whatsapp, none

Options:
  --output PATH            Output file path (default: stdout)
  --template TEMPLATE      Template type: base or full (default: base)
  --interactive            Prompt for each value instead of using defaults
  -h, --help               Show this help message

Providers:
  anthropic      Anthropic Claude API (requires ANTHROPIC_API_KEY)
  openai         OpenAI API (requires OPENAI_API_KEY)
  google         Google Gemini API (requires GOOGLE_API_KEY)
  mistral        Mistral AI API (requires MISTRAL_API_KEY)
  openrouter     OpenRouter API (requires OPENROUTER_API_KEY)
  ollama         Local Ollama (no API key needed, uses OLLAMA_HOST)

Channels:
  telegram       Telegram Bot (requires TELEGRAM_BOT_TOKEN)
  discord        Discord Bot (requires DISCORD_BOT_TOKEN)
  slack          Slack App (requires SLACK_BOT_TOKEN)
  whatsapp       WhatsApp Business API (requires WHATSAPP_API_TOKEN)
  none           No channel (gateway-only mode)

Examples:
  # Basic Anthropic + Telegram config to file
  $(basename "$0") --provider anthropic --channel telegram --output ~/.openclaw/openclaw.json

  # Full template with OpenAI and Discord
  $(basename "$0") --provider openai --channel discord --template full

  # Interactive mode
  $(basename "$0") --provider anthropic --channel telegram --interactive

EOF
    exit 0
}

# Parse arguments
PROVIDER=""
CHANNEL=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --provider)
            PROVIDER="$2"
            shift 2
            ;;
        --channel)
            CHANNEL="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --interactive)
            INTERACTIVE=true
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
if [[ -z "$PROVIDER" ]]; then
    log_error "Missing required argument: --provider"
    usage
fi

if [[ -z "$CHANNEL" ]]; then
    log_error "Missing required argument: --channel"
    usage
fi

# Validate provider
VALID_PROVIDERS="anthropic openai google mistral openrouter ollama"
if [[ ! " $VALID_PROVIDERS " =~ " $PROVIDER " ]]; then
    log_error "Invalid provider: $PROVIDER. Must be one of: $VALID_PROVIDERS"
    exit 1
fi

# Validate channel
VALID_CHANNELS="telegram discord slack whatsapp none"
if [[ ! " $VALID_CHANNELS " =~ " $CHANNEL " ]]; then
    log_error "Invalid channel: $CHANNEL. Must be one of: $VALID_CHANNELS"
    exit 1
fi

# Validate template
if [[ ! "$TEMPLATE" =~ ^(base|full)$ ]]; then
    log_error "Invalid template: $TEMPLATE. Must be one of: base, full"
    exit 1
fi

# Template file paths
TEMPLATE_BASE="$PROJECT_ROOT/openclaw/templates/openclaw.json.template"
TEMPLATE_FULL="$PROJECT_ROOT/openclaw/templates/openclaw-full.json.template"

# Use base template if full doesn't exist
if [[ "$TEMPLATE" == "full" ]] && [[ ! -f "$TEMPLATE_FULL" ]]; then
    log_warning "Full template not found, falling back to base template"
    TEMPLATE="base"
fi

TEMPLATE_FILE="$TEMPLATE_BASE"
if [[ "$TEMPLATE" == "full" ]]; then
    TEMPLATE_FILE="$TEMPLATE_FULL"
fi

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template file not found: $TEMPLATE_FILE"
    log_info "Creating default configuration..."
fi

# Provider configurations
declare -A PROVIDER_CONFIGS
PROVIDER_CONFIGS[anthropic]='{
  "provider": "anthropic",
  "apiKey": "\${ANTHROPIC_API_KEY}",
  "models": {
    "default": "claude-3-5-sonnet-20241022",
    "fast": "claude-3-haiku-20240307",
    "powerful": "claude-3-opus-20240229"
  }
}'

PROVIDER_CONFIGS[openai]='{
  "provider": "openai",
  "apiKey": "\${OPENAI_API_KEY}",
  "models": {
    "default": "gpt-4o",
    "fast": "gpt-4o-mini",
    "powerful": "gpt-4-turbo"
  }
}'

PROVIDER_CONFIGS[google]='{
  "provider": "google",
  "apiKey": "\${GOOGLE_API_KEY}",
  "models": {
    "default": "gemini-1.5-pro",
    "fast": "gemini-1.5-flash",
    "powerful": "gemini-1.5-pro"
  }
}'

PROVIDER_CONFIGS[mistral]='{
  "provider": "mistral",
  "apiKey": "\${MISTRAL_API_KEY}",
  "models": {
    "default": "mistral-large-latest",
    "fast": "mistral-7b",
    "powerful": "mistral-large-latest"
  }
}'

PROVIDER_CONFIGS[openrouter]='{
  "provider": "openrouter",
  "apiKey": "\${OPENROUTER_API_KEY}",
  "models": {
    "default": "anthropic/claude-3.5-sonnet",
    "fast": "anthropic/claude-3-haiku",
    "powerful": "anthropic/claude-3-opus"
  }
}'

PROVIDER_CONFIGS[ollama]='{
  "provider": "ollama",
  "host": "\${OLLAMA_HOST:-localhost:11434}",
  "models": {
    "default": "llama3.2",
    "fast": "llama3.2:1b",
    "powerful": "llama3.2:70b"
  }
}'

# Channel configurations
declare -A CHANNEL_CONFIGS
CHANNEL_CONFIGS[telegram]='{
  "channel": "telegram",
  "enabled": true,
  "config": {
    "botToken": "\${TELEGRAM_BOT_TOKEN}",
    "webhookUrl": "\${TELEGRAM_WEBHOOK_URL:-}"
  }
}'

CHANNEL_CONFIGS[discord]='{
  "channel": "discord",
  "enabled": true,
  "config": {
    "botToken": "\${DISCORD_BOT_TOKEN}",
    "clientId": "\${DISCORD_CLIENT_ID:-}",
    "guildId": "\${DISCORD_GUILD_ID:-}"
  }
}'

CHANNEL_CONFIGS[slack]='{
  "channel": "slack",
  "enabled": true,
  "config": {
    "botToken": "\${SLACK_BOT_TOKEN}",
    "signingSecret": "\${SLACK_SIGNING_SECRET:-}",
    "appToken": "\${SLACK_APP_TOKEN:-}"
  }
}'

CHANNEL_CONFIGS[whatsapp]='{
  "channel": "whatsapp",
  "enabled": true,
  "config": {
    "apiToken": "\${WHATSAPP_API_TOKEN}",
    "phoneNumberId": "\${WHATSAPP_PHONE_NUMBER_ID:-}",
    "businessAccountId": "\${WHATSAPP_BUSINESS_ACCOUNT_ID:-}"
  }
}'

# Interactive prompt function
prompt_value() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="${3:-}"

    if [[ "$INTERACTIVE" == true ]]; then
        if [[ -n "$default_value" ]]; then
            read -rp "$prompt_text [$default_value]: " input
            echo "${input:-$default_value}"
        else
            read -rp "$prompt_text: " input
            echo "$input"
        fi
    else
        echo "$default_value"
    fi
}

# Build configuration
log_info "Generating OpenClaw configuration..."
echo ""

# Start building JSON
cat << 'EOF'
{
  // OpenClaw Configuration File
  // Generated by generate-config.sh
  // See: https://docs.openclaw.ai/configuration

  // Gateway Settings
  "gateway": {
    "host": "${OPENCLAW_HOST:-0.0.0.0}",
    "port": ${OPENCLAW_PORT:-3000},
    "logLevel": "${OPENCLAW_LOG_LEVEL:-info}"
  },

  // Authentication
  "auth": {
    "enabled": true,
    "tokens": {
      "admin": "${OPENCLAW_ADMIN_TOKEN:-$(openssl rand -hex 32)}"
    }
  },

EOF

# Add provider configuration
log_info "Provider: $PROVIDER"
cat << EOF
  // AI Provider: $PROVIDER
  "provider": $(echo "${PROVIDER_CONFIGS[$PROVIDER]}"),

EOF

# Add channel configuration if not "none"
if [[ "$CHANNEL" != "none" ]]; then
    log_info "Channel: $CHANNEL"
    cat << EOF
  // Channel: $CHANNEL
  "channels": [
    $(echo "${CHANNEL_CONFIGS[$CHANNEL]}")
  ],

EOF
else
    log_info "No channel configured (gateway-only mode)"
fi

# Add additional settings
cat << 'EOF'
  // Knowledge Base
  "knowledge": {
    "enabled": true,
    "path": "${OPENCLAW_KNOWLEDGE_PATH:-./knowledge}",
    "maxFiles": ${OPENCLAW_KNOWLEDGE_MAX_FILES:-1000}
  },

  // Security Settings
  "security": {
    "rateLimiting": {
      "enabled": true,
      "maxRequests": ${OPENCLAW_RATE_LIMIT:-100},
      "windowMs": ${OPENCLAW_RATE_WINDOW:-60000}
    },
    "cors": {
      "enabled": true,
      "origins": "${OPENCLAW_CORS_ORIGINS:-*}"
    }
  },

  // Logging
  "logging": {
    "level": "${OPENCLAW_LOG_LEVEL:-info}",
    "file": "${OPENCLAW_LOG_FILE:-./logs/openclaw.log}",
    "maxSize": "${OPENCLAW_LOG_MAX_SIZE:-10M}",
    "maxFiles": ${OPENCLAW_LOG_MAX_FILES:-5}
  }
}
EOF

# Output to file or stdout
CONFIG_OUTPUT=$(cat)

if [[ -n "$OUTPUT" ]]; then
    # Create directory if needed
    OUTPUT_DIR=$(dirname "$OUTPUT")
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        log_info "Created directory: $OUTPUT_DIR"
    fi

    # Write to file
    echo "$CONFIG_OUTPUT" > "$OUTPUT"
    log_success "Configuration written to: $OUTPUT"

    # Set appropriate permissions
    chmod 600 "$OUTPUT"
    log_info "Set permissions to 600 (read/write for owner only)"

    # Basic validation
    log_info "Validating configuration..."

    # Check for required fields
    if ! echo "$CONFIG_OUTPUT" | jq empty 2>/dev/null; then
        if command -v jq >/dev/null 2>&1; then
            log_error "Invalid JSON generated"
            exit 1
        else
            log_warning "jq not found, skipping JSON validation"
        fi
    fi

    # Check for placeholder environment variables
    REQUIRED_VARS=()
    case "$PROVIDER" in
        ollama)
            ;;
        *)
            REQUIRED_VARS+=("${PROVIDER^^}_API_KEY")
            ;;
    esac

    if [[ "$CHANNEL" != "none" ]]; then
        case "$CHANNEL" in
            telegram)
                REQUIRED_VARS+=("TELEGRAM_BOT_TOKEN")
                ;;
            discord)
                REQUIRED_VARS+=("DISCORD_BOT_TOKEN")
                ;;
            slack)
                REQUIRED_VARS+=("SLACK_BOT_TOKEN")
                ;;
            whatsapp)
                REQUIRED_VARS+=("WHATSAPP_API_TOKEN")
                ;;
        esac
    fi

    if [[ ${#REQUIRED_VARS[@]} -gt 0 ]]; then
        echo ""
        log_info "Required environment variables to set:"
        for var in "${REQUIRED_VARS[@]}"; do
            echo "  - $var"
        done
        echo ""
        log_info "Add these to your shell profile (~/.bashrc, ~/.zshrc, etc.) or a .env file:"
        for var in "${REQUIRED_VARS[@]}"; do
            echo "  export $var='your-value-here'"
        done
    fi

else
    # Output to stdout
    echo "$CONFIG_OUTPUT"
fi

echo ""
log_success "Configuration generation complete!"

exit 0
