#!/bin/bash

# =============================================================================
# NIVUUS SHELL - CROSS-PLATFORM ZSH CONFIGURATION INSTALLER
# =============================================================================

set -euo pipefail

# Repository configuration
REPO_URL="https://github.com/maximeallanic/nivuus-shell.git"
VERSION="1.1.1"

# Function to get latest version from GitHub
get_latest_version() {
    local latest_version
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "https://api.github.com/repos/maximeallanic/nivuus-shell/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/' 2>/dev/null)
    elif command -v wget &> /dev/null; then
        latest_version=$(wget -qO- "https://api.github.com/repos/maximeallanic/nivuus-shell/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/' 2>/dev/null)
    fi
    
    if [[ -n "$latest_version" ]]; then
        echo "$latest_version"
    else
        echo "$VERSION"  # Fallback to hardcoded version
    fi
}

# Determine script location (handle both local and piped execution)
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

# Auto-clone detection and setup
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/install/common.sh" ]]; then
    # We're running remotely, need to clone first
    print_remote_header() {
        echo -e "\033[0;34m================================\033[0m"
        echo -e "\033[0;34m  Nivuus Shell Remote Install\033[0m"
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
    
    TEMP_DIR="/tmp/shell-install-$$"
    
    print_remote_header
    
    # Install git if needed (cross-platform)
    if ! command -v git &> /dev/null; then
        print_remote_step "Installing git..."
        
        # Detect package manager and install git
        if command -v apt &> /dev/null; then
            sudo apt update > /dev/null 2>&1
            sudo apt install -y git
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v apk &> /dev/null; then
            sudo apk add git
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm git
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y git
        elif command -v brew &> /dev/null; then
            brew install git
        else
            print_remote_error "Cannot install git: unsupported package manager"
            exit 1
        fi
        
        print_remote_success "Git installed"
    fi
    
    # Clone repository
    print_remote_step "Downloading configuration..."
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    # Get latest version and use it for cloning
    LATEST_VERSION=$(get_latest_version)
    print_remote_step "Using version: $LATEST_VERSION"
    
    git clone --depth 1 --branch "v$LATEST_VERSION" "$REPO_URL" "$TEMP_DIR" 2>/dev/null || \
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
    
    print_remote_success "Repository downloaded"
    
    # Re-execute from cloned repository
    print_remote_step "Launching installer..."
    cd "$TEMP_DIR"
    chmod +x install.sh
    exec ./install.sh "$@"
fi

# Script directory (after potential clone or local execution)
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
fi

# =============================================================================
# LOAD MODULES
# =============================================================================

# Load shared utilities first
source "$SCRIPT_DIR/install/common.sh"

# Global variables (after loading common module)
NON_INTERACTIVE=false
SYSTEM_WIDE=false

# Load installation modules
source "$SCRIPT_DIR/install/packages.sh"
source "$SCRIPT_DIR/install/nvm.sh"
source "$SCRIPT_DIR/install/backup.sh"
source "$SCRIPT_DIR/install/config.sh"
source "$SCRIPT_DIR/install/system.sh"
source "$SCRIPT_DIR/install/verification.sh"
source "$SCRIPT_DIR/install/update.sh"

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

install_github_cli() {
    print_step "Installing GitHub CLI..."
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed"
        return
    fi
    
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    sudo apt update > /dev/null 2>&1
    sudo apt install -y gh
    
    print_success "GitHub CLI installed"
}

# =============================================================================
# MAIN INSTALLATION FUNCTIONS
# =============================================================================

install_user_mode() {
    print_header "Installing Nivuus Shell Configuration (User Mode)"
    
    # Pre-installation checks
    detect_os
    check_package_manager
    check_root
    
    # Backup existing configuration
    backup_existing_config
    echo
    
    # System dependencies
    update_system
    install_zsh
    install_essential_tools
    install_modern_tools
    install_zsh_plugins
    echo
    
    # Install NVM
    install_nvm
    echo
    
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

install_system_mode() {
    print_header "Installing Nivuus Shell Configuration (System-wide)"
    
    # Pre-installation checks
    detect_os
    check_package_manager
    check_root
    
    # Check if we're in the right directory
    if [[ ! -f "$SCRIPT_DIR/config/16-nvm-integration.zsh" ]]; then
        print_error "Installation must be run from the shell configuration directory"
        exit 1
    fi
    
    # System dependencies
    update_system
    install_zsh
    install_essential_tools
    install_modern_tools
    install_zsh_plugins
    echo
    
    # Install system-wide components
    install_shell_config_system
    install_nvm_system
    install_vim_config_system
    setup_system_profile
    setup_user_configs_system
    echo
    
    # Verify installation
    verify_system_installation
    echo
    
    print_header "System-wide Installation Complete!"
    echo -e "${GREEN}🎉 Modern ZSH configuration installed system-wide!${NC}"
    echo
    echo -e "${CYAN}Installation details:${NC}"
    echo -e "  • Configuration: ${YELLOW}/opt/modern-shell/${NC}"
    echo -e "  • Vim config: ${YELLOW}/etc/vim/vimrc.modern${NC}"
    echo -e "  • System profile: ${YELLOW}/etc/profile.d/modern-shell.sh${NC}"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. All users will have modern shell on next login"
    echo -e "  2. Current users can run: ${YELLOW}source ~/.zshrc${NC}"
    echo -e "  3. Test with: ${YELLOW}./test-system.sh${NC}"
    echo
    echo -e "${GREEN}System-wide deployment complete! 🚀${NC}"
}

main() {
    print_header "Modern ZSH Configuration Installer v$VERSION"
    
    if [[ "$SYSTEM_WIDE" == true ]]; then
        install_system_mode
    else
        install_user_mode
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

show_help() {
    echo "Modern ZSH Configuration Installer v$VERSION"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --system             Install system-wide for all users (requires sudo)"
    echo "  --non-interactive    Run in non-interactive mode (auto-accept all prompts)"
    echo "  --uninstall          Uninstall the configuration"
    echo "  --health-check       Run health check on existing installation"
    echo ""
    echo "Examples:"
    echo "  $0                   # Install for current user"
    echo "  sudo $0 --system     # Install system-wide"
    echo "  $0 --non-interactive # Silent installation"
    echo "  $0 --uninstall       # Remove installation"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --system)
            SYSTEM_WIDE=true
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --uninstall)
            if [[ "$SYSTEM_WIDE" == true ]]; then
                uninstall_system
            else
                uninstall_user
            fi
            exit 0
            ;;
        --health-check)
            health_check
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Update directories based on final mode
if [[ "$SYSTEM_WIDE" == true ]]; then
    INSTALL_DIR="/opt/modern-shell"
    BACKUP_DIR="/opt/modern-shell-backup"
else
    INSTALL_DIR="$HOME/.config/zsh-ultra"
    BACKUP_DIR="$HOME/.config/zsh-ultra-backup"
fi

# Export variables for modules
export INSTALL_DIR BACKUP_DIR NON_INTERACTIVE SYSTEM_WIDE

# Run main installation
main