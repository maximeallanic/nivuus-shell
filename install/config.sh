#!/bin/bash

# =============================================================================
# CONFIGURATION SETUP MODULE
# =============================================================================

clone_config() {
    print_step "Setting up configuration directory..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy configuration files
    cp -r "$SCRIPT_DIR/config" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/.zshrc" "$INSTALL_DIR/"
    
    print_success "Configuration copied to $INSTALL_DIR"
}

setup_zshrc() {
    print_step "Setting up .zshrc..."
    
    local zshrc_content="# Modern ZSH Configuration
# Configuration directory
export ZSH_CONFIG_DIR=\"$INSTALL_DIR\"

# Load all configuration modules
if [[ -d \"\$ZSH_CONFIG_DIR/config\" ]]; then
    for config_file in \"\$ZSH_CONFIG_DIR\"/config/*.zsh; do
        [[ -r \"\$config_file\" ]] && source \"\$config_file\"
    done
fi

# Load local customizations if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local"
    
    echo "$zshrc_content" > ~/.zshrc
    print_success "Created new .zshrc"
}

create_local_config() {
    print_step "Creating local configuration file..."
    
    if [[ ! -f ~/.zsh_local ]]; then
        cat > ~/.zsh_local << 'EOF'
# Local ZSH Configuration
# Add your personal configurations, aliases, and functions here
# This file is not managed by the installer and won't be overwritten

# Example aliases
# alias ll='ls -la'
# alias grep='grep --color=auto'

# Example functions
# function mkcd() {
#     mkdir -p "$1" && cd "$1"
# }

# Example environment variables
# export EDITOR=vim
# export BROWSER=firefox
EOF
        print_success "Created ~/.zsh_local for personal configurations"
    else
        print_warning "Local configuration file already exists"
    fi
}

set_default_shell() {
    print_step "Setting ZSH as default shell..."
    
    if [[ "$SHELL" == "$(which zsh)" ]]; then
        print_success "ZSH is already the default shell"
        return
    fi
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$(which zsh)" /etc/shells; then
        echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null
        print_success "Added ZSH to /etc/shells"
    fi
    
    # Change default shell
    if chsh -s "$(which zsh)"; then
        print_success "ZSH set as default shell"
    else
        print_error "Failed to set ZSH as default shell"
        print_warning "You may need to run: chsh -s \$(which zsh)"
    fi
}

install_shell_config_system() {
    print_step "Installing shell configuration system-wide..."
    
    local install_dir="/opt/modern-shell"
    local config_dir="$install_dir/config"
    
    # Create installation directory
    mkdir -p "$config_dir"
    
    # Copy configuration files
    cp -r "$SCRIPT_DIR/config"/* "$config_dir/"
    cp "$SCRIPT_DIR/.zshrc" "$install_dir/zshrc.template"
    
    # Set proper permissions
    chmod -R 755 "$install_dir"
    
    print_success "Shell configuration installed to $install_dir"
}

setup_system_profile() {
    print_step "Setting up system-wide shell profile..."
    
    local profile_content='
# Modern Shell Configuration - System-wide
export ZSH_CONFIG_DIR="/opt/modern-shell"

# Load modern shell configuration if available
if [[ -d "$ZSH_CONFIG_DIR" && -n "$ZSH_VERSION" ]]; then
    # Source all configuration modules
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi'
    
    # Add to system profile
    echo "$profile_content" | sudo tee /etc/profile.d/modern-shell.sh > /dev/null
    chmod +x /etc/profile.d/modern-shell.sh
    
    print_success "System profile configured"
}

setup_user_configs_system() {
    print_step "Setting up user configurations..."
    
    local user_config='# Modern Shell Configuration
export ZSH_CONFIG_DIR="/opt/modern-shell"

# Load modern shell configuration if available  
if [[ -d "$ZSH_CONFIG_DIR" && -n "$ZSH_VERSION" ]]; then
    # Source all configuration modules
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
    
    print_success "User configurations completed"
}
