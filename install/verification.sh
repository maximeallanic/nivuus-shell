#!/bin/bash

# =============================================================================
# VERIFICATION MODULE
# =============================================================================

verify_installation() {
    print_step "Verifying installation..."
    
    local errors=0
    
    # Check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        print_error "ZSH is not installed"
        errors=$((errors + 1))
    else
        echo "  ✓ ZSH is installed"
    fi
    
    # Check if configuration directory exists
    local install_dir="${INSTALL_DIR:-$HOME/.config/zsh-ultra}"
    if [[ ! -d "$install_dir" ]]; then
        print_error "Configuration directory not found: $install_dir"
        errors=$((errors + 1))
    else
        echo "  ✓ Configuration directory exists"
    fi
    
    # Check if .zshrc exists and contains our configuration
    if [[ ! -f ~/.zshrc ]]; then
        print_error ".zshrc file not found"
        errors=$((errors + 1))
    elif ! grep -q "ZSH_CONFIG_DIR" ~/.zshrc; then
        print_error ".zshrc does not contain our configuration"
        errors=$((errors + 1))
    else
        echo "  ✓ .zshrc is properly configured"
    fi
    
    # Check essential tools
    local tools=("git" "curl" "wget" "tree")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "  ✓ $tool is available"
        else
            print_warning "$tool is not installed"
        fi
    done
    
    # Check modern tools
    local modern_tools=("eza" "bat" "fd" "rg")
    for tool in "${modern_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "  ✓ $tool is available"
        else
            print_warning "$tool is not installed"
        fi
    done
    
    # Check NVM installation
    if [[ -d "$HOME/.nvm" ]]; then
        echo "  ✓ NVM is installed"
        
        # Check if NVM is properly sourced
        export NVM_DIR="$HOME/.nvm"
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            source "$NVM_DIR/nvm.sh"
            if command -v nvm &> /dev/null; then
                echo "  ✓ NVM is properly configured"
                
                # Check Node.js installation
                if command -v node &> /dev/null; then
                    local node_version
                    node_version=$(node --version)
                    echo "  ✓ Node.js is installed: $node_version"
                else
                    print_warning "Node.js is not installed"
                fi
            else
                print_warning "NVM is not properly configured"
            fi
        else
            print_warning "NVM script not found"
        fi
    else
        print_warning "NVM is not installed"
    fi
    
    # Check ZSH plugins
    if [[ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        echo "  ✓ zsh-syntax-highlighting is available"
    else
        print_warning "zsh-syntax-highlighting is not installed"
    fi
    
    if [[ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        echo "  ✓ zsh-autosuggestions is available"
    else
        print_warning "zsh-autosuggestions is not installed"
    fi
    
    # Final result
    if [[ $errors -eq 0 ]]; then
        print_success "Installation verification completed successfully"
        return 0
    else
        print_error "Installation verification found $errors critical issues"
        return 1
    fi
}

verify_system_installation() {
    print_step "Verifying system-wide installation..."
    
    local errors=0
    
    # Check system configuration directory
    if [[ ! -d "/opt/modern-shell" ]]; then
        print_error "System configuration directory not found"
        errors=$((errors + 1))
    else
        echo "  ✓ System configuration directory exists"
    fi
    
    # Check system profile
    if [[ ! -f "/etc/profile.d/modern-shell.sh" ]]; then
        print_error "System profile not found"
        errors=$((errors + 1))
    else
        echo "  ✓ System profile is installed"
    fi
    
    # Check root configuration
    if [[ ! -f "/root/.zshrc" ]]; then
        print_error "Root .zshrc not found"
        errors=$((errors + 1))
    else
        echo "  ✓ Root shell is configured"
    fi
    
    # Check user configurations
    local user_count=0
    for user_home in /home/*; do
        if [[ -d "$user_home" ]]; then
            local username
            username=$(basename "$user_home")
            local zshrc="$user_home/.zshrc"
            
            if [[ -f "$zshrc" ]] && grep -q "ZSH_CONFIG_DIR" "$zshrc"; then
                echo "  ✓ User $username is configured"
                user_count=$((user_count + 1))
            else
                print_warning "User $username is not configured"
            fi
        fi
    done
    
    if [[ $user_count -gt 0 ]]; then
        echo "  ✓ $user_count users configured"
    else
        print_warning "No users are configured"
    fi
    
    # Final result
    if [[ $errors -eq 0 ]]; then
        print_success "System-wide installation verification completed successfully"
        return 0
    else
        print_error "System-wide installation verification found $errors critical issues"
        return 1
    fi
}

health_check() {
    print_header "Health Check"
    
    echo -e "${CYAN}System Information:${NC}"
    echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
    echo "  Shell: $SHELL"
    echo "  ZSH Version: $(zsh --version 2>/dev/null || echo "Not installed")"
    echo
    
    echo -e "${CYAN}Configuration:${NC}"
    echo "  Install Dir: ${INSTALL_DIR:-$HOME/.config/zsh-ultra}"
    echo "  Backup Dir: ${BACKUP_DIR:-$HOME/.config/zsh-ultra/backups}"
    echo
    
    if [[ "$SYSTEM_WIDE" == true ]]; then
        verify_system_installation
    else
        verify_installation
    fi
}
