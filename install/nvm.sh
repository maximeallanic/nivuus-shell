#!/bin/bash

# =============================================================================
# NVM INSTALLATION MODULE
# =============================================================================

install_nvm() {
    print_step "Installing Node Version Manager (NVM)..."
    
    if [[ -d "$HOME/.nvm" ]]; then
        print_success "NVM already installed"
        return
    fi
    
    # Download and install NVM
    local nvm_version="v0.39.4"
    local nvm_script_url="https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh"
    
    print_step "Downloading NVM installer..."
    if curl -o- "$nvm_script_url" | bash; then
        print_success "NVM installer completed"
    else
        print_error "Failed to download/install NVM"
        return 1
    fi
    
    # Source NVM immediately for verification and Node.js installation
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node.js if NVM is available
    if command -v nvm &> /dev/null; then
        print_step "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        nvm alias default "lts/*"
        print_success "Installed Node.js LTS and set as default"
    else
        print_warning "NVM installation completed but command not immediately available"
        print_warning "Restart terminal or run 'source ~/.zshrc' to use NVM"
    fi
    
    print_success "NVM installation completed"
}

install_nvm_system() {
    print_step "Installing NVM system-wide for all users..."
    
    local nvm_version="v0.39.4"
    local nvm_script_url="https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh"
    
    # Install NVM for root first
    if [[ ! -d "/root/.nvm" ]]; then
        print_step "Installing NVM for root user..."
        curl -o- "$nvm_script_url" | bash
        print_success "NVM installed for root"
    else
        echo "  ✓ NVM already installed for root"
    fi
    
    # Install NVM for all users with home directories
    for user_home in /home/*; do
        if [[ -d "$user_home" ]] && [[ -w "$user_home" ]]; then
            local username=$(basename "$user_home")
            local user_nvm_dir="$user_home/.nvm"
            
            if [[ ! -d "$user_nvm_dir" ]]; then
                print_step "Installing NVM for user: $username"
                
                # Run NVM installer as the user
                sudo -u "$username" bash -c "curl -o- '$nvm_script_url' | bash"
                
                # Set proper ownership
                chown -R "$(stat -c '%U:%G' "$user_home")" "$user_nvm_dir" 2>/dev/null || true
                
                print_success "NVM installed for user: $username"
            else
                echo "  ✓ NVM already installed for user: $username"
            fi
        fi
    done
    
    print_success "NVM installation completed for all users"
}
