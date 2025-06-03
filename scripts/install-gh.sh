#!/bin/bash

# =============================================================================
# NIVUUS SHELL - GITHUB CLI INSTALLER
# =============================================================================

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

install_github_cli() {
    print_info "Installing GitHub CLI..."
    
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        type -p curl >/dev/null || sudo apt install curl -y
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install 'dnf-command(config-manager)' -y
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install gh -y
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo yum install gh -y
    elif command -v brew &> /dev/null; then
        # macOS
        brew install gh
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -S github-cli
    else
        print_warning "Unsupported package manager. Please install GitHub CLI manually:"
        print_info "https://github.com/cli/cli#installation"
        return 1
    fi
    
    print_success "GitHub CLI installed"
}

main() {
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI is already installed"
        gh --version
    else
        install_github_cli
        
        print_info "Please authenticate with GitHub:"
        print_info "gh auth login"
    fi
}

main "$@"
