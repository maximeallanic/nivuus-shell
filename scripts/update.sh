#!/bin/bash
# ZSH Ultra Performance Config - Smart Updater
# Updates configuration while preserving user customizations

set -euo pipefail

# Repository configuration
REPO_URL="https://github.com/maximeallanic/nivuus-shell.git"
VERSION="3.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

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

# Detect configuration directory
detect_config_dir() {
    local config_dir=""
    
    if [[ -n "${ZSH_CONFIG_DIR:-}" ]] && [[ -d "$ZSH_CONFIG_DIR" ]]; then
        config_dir="$ZSH_CONFIG_DIR"
    elif [[ -d "$HOME/.config/zsh-ultra" ]]; then
        config_dir="$HOME/.config/zsh-ultra"
    elif [[ -d "/opt/modern-shell" ]]; then
        config_dir="/opt/modern-shell"
    else
        print_error "Configuration directory not found"
        echo "Please ensure the shell configuration is properly installed"
        exit 1
    fi
    
    echo "$config_dir"
}

# Extract user configurations from .zshrc
extract_user_configs() {
    local zshrc_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$zshrc_file" ]]; then
        return 0
    fi
    
    print_step "Extracting user configurations..."
    
    local temp_file=$(mktemp)
    local found_configs=false
    local in_preserved_section=false
    
    while IFS= read -r line; do
        # Skip our configuration blocks
        if [[ "$line" =~ ^#.*Modern.*ZSH.*Configuration ]] || \
           [[ "$line" =~ ^export.*ZSH_CONFIG_DIR ]] || \
           [[ "$line" =~ ^\[.*-r.*config_file ]] || \
           [[ "$line" =~ ^for.*config_file.*in ]]; then
            continue
        fi
        
        # Detect preserved section
        if [[ "$line" =~ ^#.*PRESERVED.*USER.*CONFIGURATIONS ]]; then
            in_preserved_section=true
            continue
        fi
        
        # If in preserved section, include everything until next major section
        if [[ "$in_preserved_section" == true ]]; then
            if [[ "$line" =~ ^#.*===.*=== ]]; then
                in_preserved_section=false
            else
                echo "$line" >> "$temp_file"
                found_configs=true
            fi
            continue
        fi
        
        # Preserve important user configurations
        if [[ "$line" =~ ^export.*NVM_DIR ]] || \
           [[ "$line" =~ ^\[.*-s.*nvm\.sh ]] || \
           [[ "$line" =~ ^\[.*-s.*bash_completion ]] || \
           [[ "$line" =~ [Gg]cloud ]] || \
           [[ "$line" =~ google-cloud-sdk ]] || \
           [[ "$line" =~ ^source.*google-cloud ]] || \
           [[ "$line" =~ ^\..*google-cloud ]] || \
           [[ "$line" =~ path\.zsh\.inc ]] || \
           [[ "$line" =~ completion\.zsh\.inc ]] || \
           [[ "$line" =~ ^export.*GOOGLE_CLOUD ]] || \
           [[ "$line" =~ ^export.*GCLOUD ]] || \
           [[ "$line" =~ ^export.*GOOGLE_APPLICATION_CREDENTIALS ]] || \
           [[ "$line" =~ ^export.*CLOUDSDK ]] || \
           [[ "$line" =~ ^PATH.*gcloud ]] || \
           [[ "$line" =~ ^PATH.*google-cloud ]] || \
           [[ "$line" =~ ^alias.*gcloud ]] || \
           [[ "$line" =~ pyenv ]] || \
           [[ "$line" =~ rbenv ]] || \
           [[ "$line" =~ conda ]] || \
           [[ "$line" =~ anaconda ]] || \
           [[ "$line" =~ miniconda ]] || \
           [[ "$line" =~ ^export.*JAVA_HOME ]] || \
           [[ "$line" =~ ^export.*ANDROID ]] || \
           [[ "$line" =~ ^export.*FLUTTER ]] || \
           [[ "$line" =~ ^export.*DART ]] || \
           [[ "$line" =~ ^source.*\.bashrc ]] || \
           [[ "$line" =~ ^source.*\.profile ]] || \
           [[ "$line" =~ ^source.*\.bash_profile ]] || \
           [[ "$line" =~ ^alias.*ll= ]] || \
           [[ "$line" =~ ^alias.*la= ]] || \
           [[ "$line" =~ ^alias.*grep= ]] || \
           [[ "$line" =~ ^# User ]] || \
           [[ "$line" =~ ^# Personal ]] || \
           [[ "$line" =~ ^# Custom ]] || \
           [[ "$line" =~ ^# My ]] || \
           [[ "$line" =~ ^# Added by ]] || \
           [[ "$line" =~ ^# The next line ]] || \
           [[ "$line" =~ ^# This line ]] || \
           [[ "$line" =~ ^# Enable ]] || \
           [[ "$line" =~ ^# Load ]] || \
           [[ "$line" =~ ^# Initialize ]]; then
            echo "$line" >> "$temp_file"
            found_configs=true
        fi
    done < "$zshrc_file"
    
    if [[ "$found_configs" == true ]]; then
        # Clean up and save to output file
        sed '/^$/N;/^\n$/d' "$temp_file" > "$output_file"
        rm -f "$temp_file"
        print_success "Extracted user configurations"
        
        # Show what will be preserved
        if [[ -s "$output_file" ]]; then
            echo "Configurations to preserve:"
            while IFS= read -r line; do
                echo "  $line"
            done < "$output_file"
        fi
        return 0
    else
        rm -f "$temp_file"
        print_warning "No user configurations found to preserve"
        return 1
    fi
}

# Smart update function
smart_update() {
    print_header "Smart Update with Configuration Preservation"
    
    local config_dir=$(detect_config_dir)
    print_step "Using configuration directory: $config_dir"
    
    # Create backup directory
    local backup_dir="$HOME/.config/zsh-update-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    print_step "Created backup directory: $backup_dir"
    
    # Backup current .zshrc
    if [[ -f ~/.zshrc ]]; then
        cp ~/.zshrc "$backup_dir/zshrc.backup"
        print_success "Backed up current .zshrc"
        
        # Extract user configurations
        local user_configs_file="$backup_dir/user_configs.zsh"
        extract_user_configs ~/.zshrc "$user_configs_file"
    fi
    
    # Backup .zsh_local if it exists
    if [[ -f ~/.zsh_local ]]; then
        cp ~/.zsh_local "$backup_dir/zsh_local.backup"
        print_success "Backed up .zsh_local"
    fi
    
    # Update configuration files
    print_step "Updating configuration files..."
    if [[ -d "$config_dir/.git" ]]; then
        cd "$config_dir"
        
        if git pull origin main --quiet; then
            print_success "Updated configuration files from repository"
        else
            print_error "Failed to update from repository"
            return 1
        fi
    else
        print_warning "Not a git repository - manual update required"
        return 1
    fi
    
    # Regenerate .zshrc with preserved configurations
    print_step "Regenerating .zshrc with preserved configurations..."
    
    local zshrc_content="# Modern ZSH Configuration (Updated: $(date))
# Configuration directory
export ZSH_CONFIG_DIR=\"$config_dir\"

# Load all configuration modules
if [[ -d \"\$ZSH_CONFIG_DIR/config\" ]]; then
    for config_file in \"\$ZSH_CONFIG_DIR\"/config/*.zsh; do
        [[ -r \"\$config_file\" ]] && source \"\$config_file\"
    done
fi

# Load local customizations if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local"
    
    echo "$zshrc_content" > ~/.zshrc
    
    # Restore user configurations
    local user_configs_file="$backup_dir/user_configs.zsh"
    if [[ -f "$user_configs_file" ]] && [[ -s "$user_configs_file" ]]; then
        echo "" >> ~/.zshrc
        echo "# =============================================================================" >> ~/.zshrc
        echo "# PRESERVED USER CONFIGURATIONS" >> ~/.zshrc
        echo "# =============================================================================" >> ~/.zshrc
        echo "" >> ~/.zshrc
        cat "$user_configs_file" >> ~/.zshrc
        print_success "Restored preserved user configurations"
    fi
    
    # Update version info
    echo "$VERSION" > "$config_dir/.version"
    echo "$(date)" > "$config_dir/.last_update"
    
    print_success "Update completed successfully!"
    echo ""
    echo -e "${CYAN}Update Summary:${NC}"
    echo -e "  • Configuration updated to latest version"
    echo -e "  • User configurations preserved"
    echo -e "  • Backup saved to: ${YELLOW}$backup_dir${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Restart your terminal or run: ${YELLOW}exec zsh${NC}"
    echo -e "  2. Run ${YELLOW}healthcheck${NC} to verify everything works"
    echo ""
}

# Check for configuration changes
check_for_changes() {
    local config_dir=$(detect_config_dir)
    
    if [[ ! -d "$config_dir/.git" ]]; then
        print_error "Configuration is not a git repository"
        return 1
    fi
    
    cd "$config_dir"
    
    print_step "Checking for updates..."
    
    if git fetch origin main --quiet 2>/dev/null; then
        local current_commit=$(git rev-parse HEAD)
        local latest_commit=$(git rev-parse origin/main)
        
        if [[ "$current_commit" != "$latest_commit" ]]; then
            echo ""
            echo -e "${GREEN}Updates available!${NC}"
            echo ""
            echo "Recent changes:"
            git log --oneline --graph HEAD..origin/main
            echo ""
            return 0
        else
            print_success "Configuration is up to date"
            return 1
        fi
    else
        print_error "Failed to check for updates"
        return 1
    fi
}

# Show help
show_help() {
    echo "ZSH Ultra Performance Config - Smart Updater v$VERSION"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  update       Perform smart update with configuration preservation"
    echo "  check        Check for available updates"
    echo "  status       Show current configuration status"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 update    # Update configuration preserving user settings"
    echo "  $0 check     # Check if updates are available"
    echo ""
}

# Show status
show_status() {
    local config_dir=$(detect_config_dir)
    
    print_header "Configuration Status"
    
    echo -e "${CYAN}Configuration Directory:${NC} $config_dir"
    
    if [[ -f "$config_dir/.version" ]]; then
        local installed_version=$(cat "$config_dir/.version")
        echo -e "${CYAN}Installed Version:${NC} $installed_version"
    else
        echo -e "${CYAN}Installed Version:${NC} Unknown"
    fi
    
    if [[ -f "$config_dir/.last_update" ]]; then
        local last_update=$(cat "$config_dir/.last_update")
        echo -e "${CYAN}Last Update:${NC} $last_update"
    else
        echo -e "${CYAN}Last Update:${NC} Unknown"
    fi
    
    if [[ -d "$config_dir/.git" ]]; then
        cd "$config_dir"
        local current_commit=$(git rev-parse --short HEAD)
        echo -e "${CYAN}Current Commit:${NC} $current_commit"
        
        local branch=$(git rev-parse --abbrev-ref HEAD)
        echo -e "${CYAN}Branch:${NC} $branch"
    fi
    
    echo ""
}

# Main function
main() {
    case "${1:-update}" in
        update)
            smart_update
            ;;
        check)
            if check_for_changes; then
                echo ""
                read -p "Apply updates? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    smart_update
                fi
            fi
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
