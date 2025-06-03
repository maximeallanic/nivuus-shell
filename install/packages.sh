#!/bin/bash
# =============================================================================
# SYSTEM PACKAGES INSTALLATION
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Update system packages
update_system() {
    print_step "Updating system packages..."
    sudo apt update > /dev/null 2>&1
    print_success "System updated"
}

# Install ZSH
install_zsh() {
    print_step "Installing ZSH..."
    
    if command -v zsh &> /dev/null; then
        print_success "ZSH already installed"
        return
    fi
    
    sudo apt install -y zsh
    print_success "ZSH installed"
}

# Install essential tools
install_essential_tools() {
    print_step "Installing essential tools..."
    
    local tools=(
        "git"
        "curl" 
        "wget"
        "jq"
        "htop"
        "tree"
        "unzip"
    )
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            sudo apt install -y "$tool"
            print_success "Installed $tool"
        else
            echo "  ✓ $tool already installed"
        fi
    done
}

# Install modern CLI tools
install_modern_tools() {
    print_step "Installing modern CLI tools..."
    
    # Install eza (modern ls replacement)
    if ! command -v eza &> /dev/null; then
        echo "  Installing eza..."
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update > /dev/null 2>&1
        sudo apt install -y eza
        print_success "Installed eza"
    else
        echo "  ✓ eza already installed"
    fi
    
    # Install bat (modern cat replacement)
    if ! command -v bat &> /dev/null; then
        echo "  Installing bat..."
        sudo apt install -y bat
        # Create symlink if batcat exists
        if command -v batcat &> /dev/null; then
            mkdir -p ~/.local/bin
            ln -sf $(which batcat) ~/.local/bin/bat
        fi
        print_success "Installed bat"
    else
        echo "  ✓ bat already installed"
    fi
    
    # Install fd (modern find replacement)
    if ! command -v fd &> /dev/null; then
        echo "  Installing fd..."
        sudo apt install -y fd-find
        # Create symlink
        mkdir -p ~/.local/bin
        ln -sf $(which fdfind) ~/.local/bin/fd
        print_success "Installed fd"
    else
        echo "  ✓ fd already installed"
    fi
    
    # Install ripgrep (modern grep replacement)
    if ! command -v rg &> /dev/null; then
        echo "  Installing ripgrep..."
        sudo apt install -y ripgrep
        print_success "Installed ripgrep"
    else
        echo "  ✓ ripgrep already installed"
    fi
}

# Install ZSH plugins
install_zsh_plugins() {
    print_step "Installing ZSH plugins..."
    
    # Install zsh-syntax-highlighting
    if [[ ! -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        sudo apt install -y zsh-syntax-highlighting
        print_success "Installed zsh-syntax-highlighting"
    else
        echo "  ✓ zsh-syntax-highlighting already installed"
    fi
    
    # Install zsh-autosuggestions
    if [[ ! -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        sudo apt install -y zsh-autosuggestions
        print_success "Installed zsh-autosuggestions"
    else
        echo "  ✓ zsh-autosuggestions already installed"
    fi
}

# Install GitHub CLI (optional)
install_github_cli() {
    print_step "Installing GitHub CLI..."
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed"
        return
    fi
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update > /dev/null 2>&1
    sudo apt install -y gh
    print_success "Installed GitHub CLI"
}

# Main function to install all packages
install_packages() {
    update_system
    install_zsh
    install_essential_tools
    install_modern_tools
    install_zsh_plugins
}
