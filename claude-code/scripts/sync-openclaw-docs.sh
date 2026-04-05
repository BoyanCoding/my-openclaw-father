#!/usr/bin/env bash
#
# OpenClaw Documentation Sync Script
# Usage: ./sync-openclaw-docs.sh [--dry-run] [--force] [--section install|channels|security|models|troubleshooting]
#
# Fetches latest documentation from docs.openclaw.ai and updates local knowledge files.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KNOWLEDGE_DIR="$PROJECT_ROOT/knowledge"
VERSION_TRACKER="$KNOWLEDGE_DIR/version-tracker.json"

# Default values
DRY_RUN=false
FORCE=false
SPECIFIC_SECTION=""

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

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Fetch and sync latest OpenClaw documentation from docs.openclaw.ai

Options:
  --dry-run              Show changes without writing files
  --force                Skip confirmation prompts
  --section SECTION      Sync specific section only (default: all)
                         Valid sections: install, channels, security, models, troubleshooting
  -h, --help             Show this help message

Sections:
  install           Installation guides and setup
  channels          Channel configuration (Telegram, Discord, etc.)
  security          Security best practices
  models            Model provider configuration
  troubleshooting   Troubleshooting and reference

Examples:
  # Sync all sections with confirmation
  $(basename "$0")

  # Dry run to see what would change
  $(basename "$0") --dry-run

  # Sync only installation docs
  $(basename "$0") --section install --force

  # Full sync without prompts
  $(basename "$0") --force

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --section)
            SPECIFIC_SECTION="$2"
            shift 2
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

# Validate section if specified
if [[ -n "$SPECIFIC_SECTION" ]]; then
    VALID_SECTIONS="install channels security models troubleshooting"
    if [[ ! " $VALID_SECTIONS " =~ " $SPECIFIC_SECTION " ]]; then
        log_error "Invalid section: $SPECIFIC_SECTION"
        log_info "Valid sections: $VALID_SECTIONS"
        exit 1
    fi
fi

# Create knowledge directory if it doesn't exist
if [[ ! -d "$KNOWLEDGE_DIR" ]]; then
    mkdir -p "$KNOWLEDGE_DIR"
    log_info "Created knowledge directory: $KNOWLEDGE_DIR"
fi

# Section definitions
declare -A SECTION_URLS
SECTION_URLS[install]="https://docs.openclaw.ai/install"
SECTION_URLS[channels]="https://docs.openclaw.ai/channels"
SECTION_URLS[security]="https://docs.openclaw.ai/security"
SECTION_URLS[models]="https://docs.openclaw.ai/models"
SECTION_URLS[troubleshooting]="https://docs.openclaw.ai/reference"

declare -A SECTION_FILES
SECTION_FILES[install]="$KNOWLEDGE_DIR/install.md"
SECTION_FILES[channels]="$KNOWLEDGE_DIR/channels.md"
SECTION_FILES[security]="$KNOWLEDGE_DIR/security.md"
SECTION_FILES[models]="$KNOWLEDGE_DIR/models.md"
SECTION_FILES[troubleshooting]="$KNOWLEDGE_DIR/troubleshooting.md"

# Fetch content from URL
fetch_content() {
    local url="$1"
    local timeout=20

    log_info "Fetching: $url"

    # Try curl first
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --max-time "$timeout" "$url" 2>/dev/null || return 1
    # Fallback to wget
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout="$timeout" "$url" 2>/dev/null || return 1
    else
        log_error "Neither curl nor wget available"
        return 1
    fi
}

# Convert HTML to Markdown
html_to_markdown() {
    local html="$1"

    # Check for pandoc
    if command -v pandoc >/dev/null 2>&1; then
        echo "$html" | pandoc -f html -t markdown -s --wrap=none 2>/dev/null && return 0
    fi

    # Fallback: basic HTML to text conversion using sed
    echo "$html" | sed -e 's/<[^>]*>//g' \
                      -e 's/&lt;/</g' \
                      -e 's/&gt;/>/g' \
                      -e 's/&amp;/\&/g' \
                      -e 's/&quot;/"/g' \
                      -e 's/&nbsp;/ /g' \
                      -e 's/^\s*$//' \
                      -e '/^$/d' | \
        sed -e 's/##\+/&\n/g' | \
        fmt -w 80
}

# Calculate content hash
calculate_hash() {
    local content="$1"
    echo "$content" | md5sum | cut -d' ' -f1
}

# Fetch latest OpenClaw version from GitHub
fetch_latest_version() {
    log_info "Fetching latest OpenClaw version..."

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --max-time 10 "https://api.github.com/repos/openclaw/openclaw/releases/latest" 2>/dev/null | \
            grep '"tag_name"' | \
            sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || \
            echo "unknown"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout=10 "https://api.github.com/repos/openclaw/openclaw/releases/latest" 2>/dev/null | \
            grep '"tag_name"' | \
            sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || \
            echo "unknown"
    else
        echo "unknown"
    fi
}

# Show diff summary
show_diff_summary() {
    local old_file="$1"
    local new_content="$2"

    if [[ ! -f "$old_file" ]]; then
        log_info "New file will be created"
        return 0
    fi

    local old_content=$(cat "$old_file")
    local old_lines=$(echo "$old_content" | wc -l)
    local new_lines=$(echo "$new_content" | wc -l)

    # Create temp file for diff
    local temp_new=$(mktemp)
    echo "$new_content" > "$temp_new"

    if command -v diff >/dev/null 2>&1; then
        local diff_output=$(diff -u "$old_file" "$temp_new" 2>/dev/null || true)
        local additions=$(echo "$diff_output" | grep -c "^+" || echo 0)
        local deletions=$(echo "$diff_output" | grep -c "^-" || echo 0)

        log_info "Changes detected:"
        echo "  Lines: $old_lines -> $new_lines"
        echo "  Additions: ~$additions"
        echo "  Deletions: ~$deletions"
    else
        log_info "Changes detected: $old_lines -> $new_lines lines"
    fi

    rm -f "$temp_new"
}

# Process a single section
process_section() {
    local section="$1"
    local url="${SECTION_URLS[$section]}"
    local output_file="${SECTION_FILES[$section]}"

    log_step "Processing section: $section"
    echo ""

    # Fetch content
    local html_content
    html_content=$(fetch_content "$url")

    if [[ -z "$html_content" ]]; then
        log_error "Failed to fetch content from $url"
        return 1
    fi

    # Check for error pages
    if echo "$html_content" | grep -qi "404\|not found\|error 404"; then
        log_warning "Page not found (404) for $section"
        return 1
    fi

    # Convert to markdown
    local markdown_content
    markdown_content=$(html_to_markdown "$html_content")

    if [[ -z "$markdown_content" ]]; then
        log_error "Failed to convert content to markdown"
        return 1
    fi

    # Add header
    local final_content="# OpenClaw Documentation: ${section^}\n\n"
    final_content+="> Source: $url\n"
    final_content+="> Last synced: $(date -u +"%Y-%m-%d %H:%M:%S UTC")\n\n---\n\n"
    final_content+="$markdown_content"

    # Calculate hash
    local new_hash
    new_hash=$(calculate_hash "$final_content")

    # Check if file exists and compare hashes
    local old_hash=""
    if [[ -f "$output_file" ]]; then
        old_hash=$(calculate_hash "$(cat "$output_file")")
    fi

    if [[ "$new_hash" == "$old_hash" ]]; then
        log_info "No changes detected for $section"
        return 0
    fi

    # Show diff summary
    show_diff_summary "$output_file" "$final_content"
    echo ""

    # Write file
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would update $output_file"
        return 0
    fi

    # Confirm unless --force
    if [[ "$FORCE" == false ]]; then
        read -rp "Update $output_file? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Skipped $section"
            return 0
        fi
    fi

    # Write the file
    echo "$final_content" > "$output_file"
    log_success "Updated: $output_file"

    return 0
}

# Update version tracker
update_version_tracker() {
    local version="$1"

    log_step "Updating version tracker..."

    local tracker_content
    tracker_content=$(cat << EOF
{
  "lastSync": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "openclawVersion": "$version",
  "sections": {
EOF
    )

    local first=true
    for section in "${!SECTION_URLS[@]}"; do
        if [[ -n "$SPECIFIC_SECTION" ]] && [[ "$section" != "$SPECIFIC_SECTION" ]]; then
            continue
        fi

        local file="${SECTION_FILES[$section]}"
        local hash=""
        local size="0"

        if [[ -f "$file" ]]; then
            hash=$(calculate_hash "$(cat "$file")")
            size=$(wc -c < "$file" | tr -d ' ')
        fi

        if [[ "$first" == true ]]; then
            first=false
        else
            tracker_content+=","
        fi

        tracker_content+="
    \"${section}\": {
      \"file\": \"$(basename "${file}")\",
      \"hash\": \"${hash}\",
      \"size\": ${size}
    }"
    done

    tracker_content+="
  }
}"


    if [[ "$DRY_RUN" == false ]]; then
        echo "$tracker_content" > "$VERSION_TRACKER"
        log_success "Version tracker updated: $VERSION_TRACKER"
    else
        log_info "Would write version tracker to: $VERSION_TRACKER"
    fi
}

# Main execution
main() {
    echo "====================================="
    echo "OpenClaw Documentation Sync"
    echo "====================================="
    echo "Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE: No files will be modified"
        echo ""
    fi

    # Determine which sections to process
    local sections_to_process=()
    if [[ -n "$SPECIFIC_SECTION" ]]; then
        sections_to_process=("$SPECIFIC_SECTION")
    else
        for section in "${!SECTION_URLS[@]}"; do
            sections_to_process+=("$section")
        done
    fi

    # Process each section
    local success_count=0
    local fail_count=0

    for section in "${sections_to_process[@]}"; do
        if process_section "$section"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done

    # Fetch latest version and update tracker
    LATEST_VERSION=$(fetch_latest_version)
    log_info "Latest OpenClaw version: $LATEST_VERSION"
    echo ""

    update_version_tracker "$LATEST_VERSION"

    # Final summary
    echo "====================================="
    echo "Sync Summary"
    echo "====================================="
    echo "Completed: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "Sections processed: ${#sections_to_process[@]}"
    echo "  Successful: $success_count"
    echo "  Failed: $fail_count"
    echo ""

    if [[ "$fail_count" -gt 0 ]]; then
        log_warning "Some sections failed to sync"
        exit 1
    else
        log_success "Documentation sync completed!"
        exit 0
    fi
}

# Run main
main "$@"
