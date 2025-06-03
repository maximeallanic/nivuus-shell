#!/bin/bash

# =============================================================================
# NIVUUS SHELL - AUTO UPDATE SYSTEM
# =============================================================================

set -euo pipefail

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly REPO_OWNER="maximeallanic"
readonly REPO_NAME="nivuus-shell"
readonly API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
readonly INSTALL_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/master/install.sh"

# Installation paths
readonly USER_INSTALL_DIR="$HOME/.config/nivuus-shell"
readonly SYSTEM_INSTALL_DIR="/etc/nivuus-shell"
readonly VERSION_CHECK_FILE="$HOME/.config/nivuus-shell/.last-update-check"

# Functions
print_step() {
    echo -e "${CYAN}➤ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

get_current_version() {
    local version_file=""
    
    # Check user installation first
    if [[ -f "$USER_INSTALL_DIR/VERSION" ]]; then
        version_file="$USER_INSTALL_DIR/VERSION"
    elif [[ -f "$SYSTEM_INSTALL_DIR/VERSION" ]]; then
        version_file="$SYSTEM_INSTALL_DIR/VERSION"
    else
        echo "unknown"
        return
    fi
    
    cat "$version_file" 2>/dev/null | tr -d '\n' || echo "unknown"
}

get_latest_version() {
    local latest_version
    
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "$API_URL" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/' 2>/dev/null)
    elif command -v wget &> /dev/null; then
        latest_version=$(wget -qO- "$API_URL" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/' 2>/dev/null)
    else
        print_error "Neither curl nor wget found. Cannot check for updates."
        return 1
    fi
    
    if [[ -z "$latest_version" ]]; then
        print_error "Failed to fetch latest version from GitHub"
        return 1
    fi
    
    echo "$latest_version"
}

compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # Convert versions to comparable format
    local v1_major v1_minor v1_patch
    local v2_major v2_minor v2_patch
    
    IFS='.' read -r v1_major v1_minor v1_patch <<< "$version1"
    IFS='.' read -r v2_major v2_minor v2_patch <<< "$version2"
    
    # Convert to integers for comparison
    v1_major=${v1_major:-0}
    v1_minor=${v1_minor:-0}
    v1_patch=${v1_patch:-0}
    v2_major=${v2_major:-0}
    v2_minor=${v2_minor:-0}
    v2_patch=${v2_patch:-0}
    
    if (( v2_major > v1_major )); then
        return 0  # v2 is newer
    elif (( v2_major < v1_major )); then
        return 1  # v1 is newer
    elif (( v2_minor > v1_minor )); then
        return 0  # v2 is newer
    elif (( v2_minor < v1_minor )); then
        return 1  # v1 is newer
    elif (( v2_patch > v1_patch )); then
        return 0  # v2 is newer
    else
        return 1  # v1 is newer or equal
    fi
}

should_check_for_updates() {
    local check_file="$VERSION_CHECK_FILE"
    local current_time
    local last_check_time
    local check_interval=$((24 * 60 * 60))  # 24 hours in seconds
    
    current_time=$(date +%s)
    
    if [[ ! -f "$check_file" ]]; then
        return 0  # Should check
    fi
    
    last_check_time=$(cat "$check_file" 2>/dev/null || echo "0")
    
    if (( current_time - last_check_time > check_interval )); then
        return 0  # Should check
    else
        return 1  # Too soon
    fi
}

update_check_timestamp() {
    local check_file="$VERSION_CHECK_FILE"
    local check_dir
    check_dir=$(dirname "$check_file")
    
    mkdir -p "$check_dir"
    date +%s > "$check_file"
}

prompt_for_update() {
    local current_version="$1"
    local latest_version="$2"
    
    echo
    print_warning "New version available!"
    print_info "Current version: $current_version"
    print_info "Latest version:  $latest_version"
    echo
    
    read -p "Would you like to update now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

perform_update() {
    print_step "Downloading and running latest installer..."
    
    # Determine if we need sudo (system installation)
    local sudo_cmd=""
    if [[ -d "$SYSTEM_INSTALL_DIR" ]]; then
        sudo_cmd="sudo"
    fi
    
    # Download and execute installer
    if command -v curl &> /dev/null; then
        bash <(curl -fsSL "$INSTALL_URL") ${sudo_cmd:+--system}
    elif command -v wget &> /dev/null; then
        bash <(wget -qO- "$INSTALL_URL") ${sudo_cmd:+--system}
    else
        print_error "Neither curl nor wget found. Cannot download installer."
        return 1
    fi
}

check_for_updates() {
    local force_check="$1"
    local auto_update="$2"
    
    # Skip time check if forced
    if [[ "$force_check" != "true" ]] && ! should_check_for_updates; then
        return 0
    fi
    
    print_step "Checking for updates..."
    
    local current_version
    local latest_version
    
    current_version=$(get_current_version)
    
    if [[ "$current_version" == "unknown" ]]; then
        print_warning "Could not determine current version"
        return 1
    fi
    
    latest_version=$(get_latest_version)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Update check timestamp
    update_check_timestamp
    
    if compare_versions "$current_version" "$latest_version"; then
        if [[ "$auto_update" == "true" ]]; then
            print_info "Auto-updating from $current_version to $latest_version..."
            perform_update
        else
            if prompt_for_update "$current_version" "$latest_version"; then
                perform_update
            else
                print_info "Update skipped. You can update later with: nivuus-shell-update"
            fi
        fi
    else
        if [[ "$force_check" == "true" ]]; then
            print_success "You are running the latest version ($current_version)"
        fi
    fi
}

show_usage() {
    echo "Nivuus Shell Update Manager"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --check       Force check for updates"
    echo "  --auto        Automatically update if new version available"
    echo "  --silent      Check silently (no output unless update available)"
    echo "  --help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0              # Check for updates and prompt"
    echo "  $0 --check     # Force check even if recently checked"
    echo "  $0 --auto      # Auto-update without prompting"
    echo "  $0 --silent    # Silent check (for cron jobs)"
}

main() {
    local force_check="false"
    local auto_update="false"
    local silent="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                force_check="true"
                shift
                ;;
            --auto)
                auto_update="true"
                shift
                ;;
            --silent)
                silent="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Redirect output if silent mode
    if [[ "$silent" == "true" ]]; then
        exec 3>&1 4>&2
        exec 1>/dev/null 2>/dev/null
    fi
    
    check_for_updates "$force_check" "$auto_update"
    
    # Restore output if silent mode
    if [[ "$silent" == "true" ]]; then
        exec 1>&3 2>&4
    fi
}

main "$@"
