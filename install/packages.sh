#!/bin/bash
# =============================================================================
# CROSS-PLATFORM PACKAGES INSTALLATION
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Package mappings for different package managers
declare -A PACKAGE_MAPS

# Essential tools mapping
declare -A ESSENTIAL_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["jq"]="jq"
    ["htop"]="htop"
    ["tree"]="tree"
    ["unzip"]="unzip"
    ["zsh"]="zsh"
)

# Modern tools mapping
declare -A MODERN_PACKAGES=(
    ["eza"]="eza"
    ["bat"]="bat"
    ["fd"]="fd"
    ["ripgrep"]="ripgrep"
    ["gh"]="gh"
)

# ZSH plugins mapping
declare -A ZSH_PACKAGES=(
    ["zsh-syntax-highlighting"]="zsh-syntax-highlighting"
    ["zsh-autosuggestions"]="zsh-autosuggestions"
)

# Update system packages
update_system() {
    print_step "Updating system packages..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            sudo apt update > /dev/null 2>&1
            ;;
        dnf)
            sudo dnf check-update > /dev/null 2>&1 || true
            ;;
        yum)
            sudo yum check-update > /dev/null 2>&1 || true
            ;;
        apk)
            sudo apk update > /dev/null 2>&1
            ;;
        pacman)
            sudo pacman -Sy > /dev/null 2>&1
            ;;
        zypper)
            sudo zypper refresh > /dev/null 2>&1
            ;;
        brew)
            brew update > /dev/null 2>&1
            ;;
    esac
    
    print_success "System updated"
}

# Install a package using the appropriate package manager
install_package() {
    local package="$1"
    local package_name="${2:-$package}"
    
    if command -v "$package" &> /dev/null; then
        echo "  ✓ $package_name already installed"
        return 0
    fi
    
    echo "  Installing $package_name..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            # Special cases for apt
            case "$package" in
                "fd") package="fd-find" ;;
                "bat") 
                    sudo apt install -y bat
                    # Create symlink if batcat exists
                    if command -v batcat &> /dev/null; then
                        mkdir -p ~/.local/bin
                        ln -sf $(which batcat) ~/.local/bin/bat
                    fi
                    return 0
                    ;;
            esac
            sudo apt install -y "$package"
            ;;
        dnf)
            # Special cases for dnf
            case "$package" in
                "fd") package="fd-find" ;;
            esac
            sudo dnf install -y "$package"
            ;;
        yum)
            # Special cases for yum
            case "$package" in
                "fd") package="fd-find" ;;
            esac
            sudo yum install -y "$package"
            ;;
        apk)
            # Special cases for apk
            case "$package" in
                "htop") package="htop" ;;
            esac
            sudo apk add "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        zypper)
            sudo zypper install -y "$package"
            ;;
        brew)
            # Special cases for brew
            case "$package" in
                "zsh-syntax-highlighting"|"zsh-autosuggestions")
                    brew install "$package"
                    return 0
                    ;;
            esac
            brew install "$package"
            ;;
    esac
    
    # Create symlinks for some packages if needed
    case "$package" in
        "fd-find")
            if [[ "$PACKAGE_MANAGER" =~ ^(apt|dnf|yum)$ ]]; then
                mkdir -p ~/.local/bin
                ln -sf $(which fdfind) ~/.local/bin/fd 2>/dev/null || true
            fi
            ;;
    esac
    
    print_success "Installed $package_name"
}

# Install essential tools
install_essential_tools() {
    print_step "Installing essential tools..."
    
    for tool in git curl wget jq htop tree unzip; do
        install_package "$tool"
    done
}

# Install ZSH
install_zsh() {
    print_step "Installing ZSH..."
    install_package "zsh" "ZSH"
}

# Install modern CLI tools with fallback strategies
install_modern_tools() {
    print_step "Installing modern CLI tools..."
    
    # Install eza
    if ! command -v eza &> /dev/null; then
        echo "  Installing eza..."
        case "$PACKAGE_MANAGER" in
            apt)
                # Use official repository for Ubuntu/Debian
                if ! grep -q "gierens" /etc/apt/sources.list.d/* 2>/dev/null; then
                    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                    sudo apt update > /dev/null 2>&1
                fi
                sudo apt install -y eza
                ;;
            brew|dnf|pacman)
                install_package "eza"
                ;;
            *)
                # Fallback: install from GitHub releases
                echo "    Using fallback installation method..."
                install_eza_fallback
                ;;
        esac
        print_success "Installed eza"
    else
        echo "  ✓ eza already installed"
    fi
    
    # Install other modern tools
    install_package "bat"
    install_package "fd"
    install_package "ripgrep" "ripgrep"
}

# Fallback installation for eza
install_eza_fallback() {
    local arch
    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) 
            print_warning "Unsupported architecture for eza fallback"
            return 1
            ;;
    esac
    
    local url="https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-musl.tar.gz"
    local temp_dir=$(mktemp -d)
    
    if curl -fsSL "$url" | tar -xz -C "$temp_dir"; then
        mkdir -p ~/.local/bin
        cp "$temp_dir/eza" ~/.local/bin/
        chmod +x ~/.local/bin/eza
        rm -rf "$temp_dir"
        return 0
    else
        rm -rf "$temp_dir"
        return 1
    fi
}

# Install ZSH plugins with platform-specific methods
install_zsh_plugins() {
    print_step "Installing ZSH plugins..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            install_package "zsh-syntax-highlighting"
            install_package "zsh-autosuggestions"
            ;;
        brew)
            install_package "zsh-syntax-highlighting"
            install_package "zsh-autosuggestions"
            ;;
        dnf|yum)
            # Try package manager first, fallback to manual install
            if ! sudo $PACKAGE_MANAGER install -y zsh-syntax-highlighting 2>/dev/null; then
                install_zsh_plugin_manual "zsh-syntax-highlighting"
            fi
            if ! sudo $PACKAGE_MANAGER install -y zsh-autosuggestions 2>/dev/null; then
                install_zsh_plugin_manual "zsh-autosuggestions"
            fi
            ;;
        *)
            # Manual installation for other systems
            install_zsh_plugin_manual "zsh-syntax-highlighting"
            install_zsh_plugin_manual "zsh-autosuggestions"
            ;;
    esac
}

# Manual ZSH plugin installation
install_zsh_plugin_manual() {
    local plugin="$1"
    local plugin_dir
    
    if [[ "$SYSTEM_WIDE" == true ]]; then
        plugin_dir="/usr/local/share/$plugin"
    else
        plugin_dir="$HOME/.local/share/$plugin"
    fi
    
    if [[ ! -d "$plugin_dir" ]]; then
        echo "  Installing $plugin manually..."
        mkdir -p "$(dirname "$plugin_dir")"
        case "$plugin" in
            "zsh-syntax-highlighting")
                git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"
                ;;
            "zsh-autosuggestions")
                git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir"
                ;;
        esac
        print_success "Installed $plugin"
    else
        echo "  ✓ $plugin already installed"
    fi
}

# Install GitHub CLI with platform-specific methods
install_github_cli() {
    print_step "Installing GitHub CLI..."
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed"
        return
    fi
    
    case "$PACKAGE_MANAGER" in
        apt)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update > /dev/null 2>&1
            sudo apt install -y gh
            ;;
        dnf)
            sudo dnf install -y 'dnf-command(config-manager)'
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
            ;;
        yum)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo yum install -y gh
            ;;
        brew|pacman)
            install_package "gh" "GitHub CLI"
            ;;
        *)
            print_warning "GitHub CLI installation not supported for $PACKAGE_MANAGER, skipping..."
            return
            ;;
    esac
    
    print_success "Installed GitHub CLI"
}

# Main function to install all packages
install_packages() {
    # First detect OS and package manager
    detect_os
    check_package_manager
    
    # Then proceed with installation
    update_system
    install_zsh
    install_essential_tools
    install_modern_tools
    install_zsh_plugins
}


