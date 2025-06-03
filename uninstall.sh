#!/bin/bash
# ZSH Ultra Performance Config - Uninstaller
# Removes the modular ZSH configuration and restores backups

set -euo pipefail

# Repository configuration
REPO_URL="https://github.com/maximeallanic/nivuus-shell.git"
VERSION="3.0.0"

# Determine script location (handle both local and piped execution)
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

# Auto-clone detection and setup
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/uninstall.sh" ]] || [[ "$(basename "$SCRIPT_PATH")" != "uninstall.sh" ]]; then
    # We're running remotely, need to clone first
    print_remote_header() {
        echo -e "\033[0;34m================================\033[0m"
        echo -e "\033[0;34m  Modern ZSH Remote Uninstall\033[0m"
        echo -e "\033[0;34m================================\033[0m"
        echo
    }
    
    print_remote_step() {
        echo -e "\033[0;36m➤ $1\033[0m"
    }
    
    print_remote_success() {
        echo -e "\033[0;32m✅ $1\033[0m"
    }
    
    print_remote_error() {
        echo -e "\033[0;31m❌ $1\033[0m"
    }
    
    TEMP_DIR="/tmp/shell-uninstall-$$"
    
    print_remote_header
    
    # Install git if needed
    if ! command -v git &> /dev/null; then
        print_remote_step "Installing git..."
        sudo apt update > /dev/null 2>&1
        sudo apt install -y git
        print_remote_success "Git installed"
    fi
    
    # Clone repository
    print_remote_step "Downloading uninstaller..."
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    git clone "$REPO_URL" "$TEMP_DIR"
    print_remote_success "Repository downloaded"
    
    # Re-execute from cloned repository
    print_remote_step "Launching uninstaller..."
    cd "$TEMP_DIR"
    chmod +x uninstall.sh
    exec ./uninstall.sh "$@"
fi

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration paths
readonly CONFIG_DIR="$HOME/.config/zsh-ultra"
readonly BACKUP_DIR="$HOME/.config/zsh-ultra-backup"
readonly ZSHRC_PATH="$HOME/.zshrc"

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

# Check if running on supported system
check_system() {
    if [[ ! -f /etc/debian_version ]]; then
        log_warning "This uninstaller is designed for Debian-based systems"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Create backup before uninstalling
create_backup() {
    if [[ -f "$ZSHRC_PATH" ]]; then
        local backup_file="$BACKUP_DIR/zshrc.pre-uninstall.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp "$ZSHRC_PATH" "$backup_file"
        log_success "Current .zshrc backed up to: $backup_file"
    fi
}

# Restore original .zshrc from backup
restore_backup() {
    if [[ -d "$BACKUP_DIR" ]]; then
        local backups=($(ls -t "$BACKUP_DIR"/zshrc.backup.* 2>/dev/null || true))
        
        if [[ ${#backups[@]} -gt 0 ]]; then
            echo
            log_info "Available backups:"
            for i in "${!backups[@]}"; do
                local backup_file="${backups[$i]}"
                local backup_date=$(basename "$backup_file" | sed 's/zshrc.backup.//')
                echo "  $((i+1)). $(basename "$backup_file") (created: $backup_date)"
            done
            
            echo
            read -p "Select backup to restore (1-${#backups[@]}, or 0 to skip): " -r selection
            
            if [[ "$selection" =~ ^[1-9][0-9]*$ ]] && [[ "$selection" -le "${#backups[@]}" ]]; then
                local selected_backup="${backups[$((selection-1))]}"
                cp "$selected_backup" "$ZSHRC_PATH"
                log_success "Restored backup: $(basename "$selected_backup")"
            elif [[ "$selection" != "0" ]]; then
                log_warning "Invalid selection. Skipping backup restoration."
            fi
        else
            log_warning "No backups found to restore"
        fi
    fi
}

# Remove ZSH configuration files
remove_config() {
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        log_success "Removed configuration directory: $CONFIG_DIR"
    fi
    
    if [[ -f "$ZSHRC_PATH" ]]; then
        # Check if it's our configuration
        if grep -q "ZSH Ultra Performance Config" "$ZSHRC_PATH" 2>/dev/null; then
            rm "$ZSHRC_PATH"
            log_success "Removed ZSH configuration file: $ZSHRC_PATH"
        else
            log_warning "Existing .zshrc doesn't appear to be our configuration. Keeping it."
        fi
    fi
}

# Remove ZSH plugins installed by our config
remove_plugins() {
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # Remove syntax highlighting plugin
    if [[ -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
        rm -rf "$zsh_custom/plugins/zsh-syntax-highlighting"
        log_success "Removed zsh-syntax-highlighting plugin"
    fi
    
    # Remove autosuggestions plugin
    if [[ -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        rm -rf "$zsh_custom/plugins/zsh-autosuggestions"
        log_success "Removed zsh-autosuggestions plugin"
    fi
}

# Clean up shell cache
clean_cache() {
    # Remove ZSH compiled files
    find "$HOME" -name "*.zwc" -type f -delete 2>/dev/null || true
    
    # Clear ZSH completions cache
    if [[ -d "$HOME/.zcompdump"* ]]; then
        rm -f "$HOME"/.zcompdump*
        log_success "Cleared ZSH completions cache"
    fi
    
    # Clear history if it was created by our config
    if [[ -f "$HOME/.zsh_history" ]]; then
        read -p "Remove ZSH history? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$HOME/.zsh_history"
            log_success "Removed ZSH history"
        fi
    fi
}

# Optional: Remove installed packages
remove_packages() {
    echo
    read -p "Remove packages installed by the installer (eza, bat, fd-find, ripgrep)? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing packages..."
        
        # Check which packages were installed
        local packages_to_remove=()
        
        if command -v eza >/dev/null 2>&1; then
            packages_to_remove+=("eza")
        fi
        
        if command -v bat >/dev/null 2>&1; then
            packages_to_remove+=("bat")
        fi
        
        if command -v fd >/dev/null 2>&1; then
            packages_to_remove+=("fd-find")
        fi
        
        if command -v rg >/dev/null 2>&1; then
            packages_to_remove+=("ripgrep")
        fi
        
        if [[ ${#packages_to_remove[@]} -gt 0 ]]; then
            sudo apt remove --purge -y "${packages_to_remove[@]}"
            sudo apt autoremove -y
            log_success "Removed packages: ${packages_to_remove[*]}"
        else
            log_info "No packages to remove"
        fi
    fi
}

# Reset shell to default
reset_shell() {
    echo
    read -p "Reset default shell to bash? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v bash >/dev/null 2>&1; then
            chsh -s "$(which bash)"
            log_success "Default shell reset to bash"
            log_info "Please log out and log back in for the change to take effect"
        else
            log_error "Bash not found on system"
        fi
    fi
}

# Main uninstallation function
main() {
    echo "🗑️  ZSH Ultra Performance Config - Uninstaller"
    echo "============================================="
    echo
    
    # Confirm uninstallation
    read -p "Are you sure you want to uninstall ZSH Ultra Performance Config? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
    
    check_system
    
    log_info "Starting uninstallation process..."
    
    # Create backup before removing anything
    create_backup
    
    # Remove configuration files
    remove_config
    
    # Remove plugins
    remove_plugins
    
    # Clean cache
    clean_cache
    
    # Restore backup
    restore_backup
    
    # Optional removals
    remove_packages
    reset_shell
    
    echo
    echo "🎉 Uninstallation completed!"
    echo
    log_info "What was removed:"
    echo "  - ZSH Ultra Performance configuration files"
    echo "  - ZSH plugins (syntax highlighting, autosuggestions)"
    echo "  - ZSH cache files"
    echo
    log_info "What was preserved:"
    echo "  - Configuration backups in: $BACKUP_DIR"
    echo "  - System packages (unless you chose to remove them)"
    echo
    log_warning "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
}

# Run main function
main "$@"
