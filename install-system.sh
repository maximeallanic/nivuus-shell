#!/bin/bash
# =============================================================================
# SHELL CONFIGURATION INSTALLER
# Install modern shell configuration for all users
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This installer must be run as root (use sudo)"
        exit 1
    fi
}

# Install system-wide shell configuration
install_shell_config() {
    print_info "Installing shell configuration system-wide..."
    
    local install_dir="/opt/modern-shell"
    local config_dir="$install_dir/config"
    
    # Create installation directory
    mkdir -p "$config_dir"
    
    # Copy configuration files
    cp -r ./config/* "$config_dir/"
    cp ./.zshrc "$install_dir/zshrc.template"
    
    # Set proper permissions
    chmod -R 755 "$install_dir"
    
    print_success "Shell configuration installed to $install_dir"
}

# Install vim configuration system-wide
install_vim_config() {
    print_info "Installing vim configuration system-wide..."
    
    # Source the vim integration module
    source "./config/13-vim-integration.zsh"
    
    # Install vim config system-wide
    vim_install_system
    
    print_success "Vim configuration installed system-wide"
}

# Create system-wide profile
setup_system_profile() {
    print_info "Setting up system-wide shell profile..."
    
    local profile_content='# Modern Shell Configuration
if [[ -d "/opt/modern-shell" ]]; then
    export ZSH_CONFIG_DIR="/opt/modern-shell"
    
    # Load all configuration modules
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi'
    
    # Add to system zsh configuration
    local zsh_config_dir="/etc/zsh/zshrc.d"
    mkdir -p "$zsh_config_dir"
    
    echo "$profile_content" > "$zsh_config_dir/00-modern-shell.zsh"
    chmod 644 "$zsh_config_dir/00-modern-shell.zsh"
    
    # Add to system profile for other shells
    if ! grep -q "modern-shell" /etc/profile 2>/dev/null; then
        echo "" >> /etc/profile
        echo "$profile_content" >> /etc/profile
    fi
    
    print_success "System-wide profile configured"
}

# Setup for all existing users
setup_user_configs() {
    print_info "Setting up configuration for existing users..."
    
    local user_config='# Load modern shell configuration
if [[ -d "/opt/modern-shell" ]]; then
    export ZSH_CONFIG_DIR="/opt/modern-shell"
    # Load all configuration files
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi'
    
    # Setup for root user first
    local root_zshrc="/root/.zshrc"
    if [[ -f "$root_zshrc" ]]; then
        cp "$root_zshrc" "$root_zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backed up existing .zshrc for root"
    fi
    echo "$user_config" > "$root_zshrc"
    print_success "Configured shell for user: root"
    
    # Setup for all users with home directories
    for user_home in /home/*; do
        if [[ -d "$user_home" ]] && [[ -w "$user_home" ]]; then
            local username=$(basename "$user_home")
            local zshrc="$user_home/.zshrc"
            
            # Backup existing .zshrc if it exists
            if [[ -f "$zshrc" ]]; then
                cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d_%H%M%S)"
                print_warning "Backed up existing .zshrc for user $username"
            fi
            
            # Create new .zshrc
            echo "$user_config" > "$zshrc"
            chown "$(stat -c '%U:%G' "$user_home")" "$zshrc"
            
            print_success "Configured shell for user: $username"
        fi
    done
}

# Main installation function
main() {
    print_info "Starting system-wide shell configuration installation..."
    
    check_root
    
    # Check if we're in the right directory
    if [[ ! -f "./config/13-vim-integration.zsh" ]]; then
        print_error "Installation must be run from the shell configuration directory"
        exit 1
    fi
    
    install_shell_config
    install_vim_config
    setup_system_profile
    setup_user_configs
    
    print_success "System-wide installation completed!"
    print_info "All users will have the modern shell configuration on next login"
    print_info "Run 'source ~/.zshrc' or restart terminal to apply changes"
}

# Run installer
main "$@"