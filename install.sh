#!/bin/bash

# =============================================================================
# MODERN ZSH CONFIGURATION INSTALLER FOR DEBIAN
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/mallanic/zsh-ultra-performance.git"
INSTALL_DIR="$HOME/.config/zsh-ultra"
BACKUP_DIR="$HOME/.config/zsh-ultra-backup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global variables for non-interactive mode
NON_INTERACTIVE=false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

print_step() {
    echo -e "${CYAN}➤ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

check_debian() {
    if ! command -v apt &> /dev/null; then
        print_error "This installer is designed for Debian-based systems"
        exit 1
    fi
    print_success "Debian-based system detected"
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

backup_existing_config() {
    print_step "Backing up existing configuration..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing .zshrc
    if [[ -f ~/.zshrc ]]; then
        cp ~/.zshrc "$BACKUP_DIR/zshrc.backup"
        print_success "Backed up ~/.zshrc"
    fi
    
    # Backup existing zsh directory
    if [[ -d ~/.zsh ]]; then
        cp -r ~/.zsh "$BACKUP_DIR/zsh.backup"
        print_success "Backed up ~/.zsh directory"
    fi
    
    # Backup existing config
    if [[ -d "$INSTALL_DIR" ]]; then
        cp -r "$INSTALL_DIR" "$BACKUP_DIR/zsh-config.backup"
        print_success "Backed up existing configuration"
    fi
    
    print_success "Backup completed in $BACKUP_DIR"
}

# =============================================================================
# SYSTEM DEPENDENCIES
# =============================================================================

update_system() {
    print_step "Updating system packages..."
    sudo apt update > /dev/null 2>&1
    print_success "System updated"
}

install_zsh() {
    print_step "Installing ZSH..."
    
    if command -v zsh &> /dev/null; then
        print_success "ZSH already installed"
        return
    fi
    
    sudo apt install -y zsh
    print_success "ZSH installed"
}

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

install_nvm() {
    print_step "Installing Node Version Manager (NVM)..."
    
    if [[ -d "$HOME/.nvm" ]]; then
        echo "  ✓ NVM already installed"
        return
    fi
    
    # Download and install NVM
    local nvm_version="v0.39.4"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    
    # Source nvm immediately for verification
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node.js
    if command -v nvm &> /dev/null; then
        print_step "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        print_success "Installed Node.js LTS via NVM"
    else
        print_warning "NVM installation may require terminal restart"
    fi
    
    print_success "NVM installed"
}

install_github_cli() {
    print_step "Installing GitHub CLI..."
    
    if command -v gh &> /dev/null; then
        echo "  ✓ GitHub CLI already installed"
        return
    fi
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update > /dev/null 2>&1
    sudo apt install -y gh
    print_success "Installed GitHub CLI"
}

# =============================================================================
# CONFIGURATION INSTALLATION
# =============================================================================

clone_config() {
    print_step "Cloning configuration repository..."
    
    # Remove existing directory if it exists
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create parent directory
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    # Clone the repository
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        # Use token if available
        git clone "https://$GITHUB_TOKEN@github.com/${REPO_URL#https://github.com/}" "$INSTALL_DIR"
    else
        # Use current directory if we're already in the repo
        if [[ -f "$(pwd)/.zshrc" && -d "$(pwd)/config" ]]; then
            cp -r "$(pwd)" "$INSTALL_DIR"
            print_success "Copied local configuration"
            return
        fi
        
        print_warning "Repository URL not configured for remote installation"
        print_step "Using local files instead..."
        
        # Create the config directory structure manually
        mkdir -p "$INSTALL_DIR"
        cp -r config "$INSTALL_DIR/"
        cp .zshrc "$INSTALL_DIR/"
        print_success "Copied configuration files"
    fi
}

setup_zshrc() {
    print_step "Setting up .zshrc..."
    
    # Create symlink to the configuration
    if [[ -f ~/.zshrc ]]; then
        mv ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    ln -sf "$INSTALL_DIR/.zshrc" ~/.zshrc
    print_success "Created symlink to .zshrc"
}

create_local_config() {
    print_step "Creating local configuration file..."
    
    if [[ ! -f ~/.zsh_local ]]; then
        cat > ~/.zsh_local << 'EOF'
# =============================================================================
# LOCAL ZSH CONFIGURATION
# Add your personal configurations here
# =============================================================================

# Personal aliases
# alias myproject='cd ~/dev/my-project'

# Personal environment variables  
# export MY_API_KEY="your-key"

# Personal functions
# my_function() {
#     echo "Hello from my function"
# }

# Override default editor if needed
# export EDITOR="code"

# Additional PATH entries
# export PATH="$HOME/my-tools:$PATH"
EOF
        print_success "Created ~/.zsh_local"
    else
        echo "  ✓ ~/.zsh_local already exists"
    fi
}

set_default_shell() {
    print_step "Setting ZSH as default shell..."
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "  ✓ ZSH already set as default shell"
        return
    fi
    
    local zsh_path=$(which zsh)
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Change default shell
    chsh -s "$zsh_path"
    print_success "ZSH set as default shell (restart required)"
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_installation() {
    print_step "Verifying installation..."
    
    local issues=0
    
    # Check ZSH installation
    if command -v zsh &> /dev/null; then
        echo "  ✓ ZSH installed"
    else
        echo "  ❌ ZSH not found"
        ((issues++))
    fi
    
    # Check configuration files
    if [[ -f ~/.zshrc ]]; then
        echo "  ✓ .zshrc configured"
    else
        echo "  ❌ .zshrc not found"
        ((issues++))
    fi
    
    if [[ -d "$INSTALL_DIR/config" ]]; then
        echo "  ✓ Configuration modules found"
    else
        echo "  ❌ Configuration modules missing"
        ((issues++))
    fi
    
    # Check modern tools
    local tools=("eza" "bat" "fd" "rg" "jq")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "  ✓ $tool available"
        else
            echo "  ⚠️  $tool not available (optional)"
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        print_success "Installation verified successfully!"
        return 0
    else
        print_warning "Installation completed with $issues issues"
        return 1
    fi
}

# =============================================================================
# MAIN INSTALLATION FLOW
# =============================================================================

main() {
    print_header "Modern ZSH Configuration Installer"
    
    print_step "Starting installation..."
    echo
    
    # Pre-flight checks
    check_root
    check_debian
    
    # Backup existing configuration
    backup_existing_config
    echo
    
    # Install system dependencies
    update_system
    install_zsh
    install_essential_tools
    install_modern_tools
    install_zsh_plugins
    
    # Optional: Install GitHub CLI
    if [[ "$NON_INTERACTIVE" == true ]]; then
        print_step "Non-interactive mode: Installing GitHub CLI..."
        install_github_cli
    else
        read -p "$(echo -e "${YELLOW}Install GitHub CLI for AI features? (y/N): ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_github_cli
        fi
    fi
    echo
    
    # Install configuration
    clone_config
    setup_zshrc
    create_local_config
    echo
    
    # Set default shell
    if [[ "$NON_INTERACTIVE" == true ]]; then
        print_step "Non-interactive mode: Setting ZSH as default shell..."
        set_default_shell
    else
        read -p "$(echo -e "${YELLOW}Set ZSH as default shell? (y/N): ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            set_default_shell
        fi
    fi
    echo
    
    # Verify installation
    verify_installation
    echo
    
    # Final message
    print_header "Installation Complete!"
    echo -e "${GREEN}🎉 Modern ZSH configuration installed successfully!${NC}"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Restart your terminal or run: ${YELLOW}exec zsh${NC}"
    echo -e "  2. Run ${YELLOW}healthcheck${NC} to verify everything works"
    echo -e "  3. Run ${YELLOW}aihelp${NC} to see AI-powered commands"
    echo -e "  4. Edit ${YELLOW}~/.zsh_local${NC} for personal configurations"
    echo
    echo -e "${CYAN}Backup location:${NC} $BACKUP_DIR"
    echo -e "${CYAN}Configuration:${NC} $INSTALL_DIR"
    echo
    echo -e "${GREEN}Happy coding! 🚀${NC}"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Modern ZSH Configuration Installer"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h           Show this help message"
        echo "  --non-interactive    Run in non-interactive mode (auto-accept all prompts)"
        echo "  --uninstall          Uninstall the configuration"
        echo ""
        exit 0
        ;;
    "--non-interactive")
        NON_INTERACTIVE=true
        main
        ;;
    "--uninstall")
        print_header "Uninstalling Modern ZSH Configuration"
        
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
        
        print_success "Uninstallation complete"
        exit 0
        ;;
    *)
        main
        ;;
esac
