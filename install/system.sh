#!/bin/bash

# =============================================================================
# SYSTEM-WIDE INSTALLATION MODULE
# =============================================================================

install_vim_config_system() {
    print_step "Installing vim configuration system-wide..."
    
    # Check if vim integration config exists
    if [[ -f "$SCRIPT_DIR/config/13-vim-integration.zsh" ]]; then
        # Source the vim integration module
        source "$SCRIPT_DIR/config/13-vim-integration.zsh"
        
        # Install vim config system-wide
        vim_install_system
        
        print_success "Vim configuration installed system-wide"
    else
        print_warning "Vim integration config not found, skipping"
    fi
}

uninstall_system() {
    print_header "Uninstalling Modern ZSH Configuration (System-wide)"
    
    # Remove system files
    sudo rm -rf /opt/modern-shell
    sudo rm -f /etc/profile.d/modern-shell.sh
    sudo rm -f /etc/vim/vimrc.modern
    
    # Remove user configurations
    rm -f /root/.zshrc
    for user_home in /home/*; do
        if [[ -d "$user_home" ]]; then
            local username=$(basename "$user_home")
            local zshrc="$user_home/.zshrc"
            if [[ -f "$zshrc.backup."* ]]; then
                latest_backup=$(ls -t "$zshrc.backup."* | head -1)
                mv "$latest_backup" "$zshrc"
                chown "$(stat -c '%U:%G' "$user_home")" "$zshrc"
                print_success "Restored .zshrc for user: $username"
            else
                rm -f "$zshrc"
                print_success "Removed .zshrc for user: $username"
            fi
        fi
    done
    
    print_success "System-wide uninstallation complete"
}

uninstall_user() {
    print_header "Uninstalling Modern ZSH Configuration (User)"
    
    # Restore backup if available
    if [[ -f ~/.zshrc.backup.* ]]; then
        latest_backup=$(ls -t ~/.zshrc.backup.* | head -1)
        mv "$latest_backup" ~/.zshrc
        print_success "Restored previous .zshrc"
    else
        rm -f ~/.zshrc
        print_success "Removed .zshrc"
    fi
    
    # Remove configuration directory
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        print_success "Removed configuration directory"
    fi
    
    print_success "User uninstallation complete"
}
