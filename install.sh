#!/bin/bash

# =============================================================================
# NIVUUS SHELL - CROSS-PLATFORM ZSH CONFIGURATION INSTALLER
# =============================================================================

set -euo pipefail

# Parse debug arguments first
DEBUG_MODE=false
VERBOSE_MODE=false
TEMP_LOG_FILE=""

# Parse early debug args
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG_MODE=true
            VERBOSE_MODE=true
            echo "🐛 Debug mode enabled" >&2
            shift
            ;;
        --verbose|-v)
            VERBOSE_MODE=true
            echo "📝 Verbose mode enabled" >&2
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Repository configuration
REPO_URL="https://github.com/maximeallanic/nivuus-shell.git"
VERSION="1.2.3"

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
        [[ -n "$TEMP_LOG_FILE" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$TEMP_LOG_FILE"
    }
    
    print_remote_debug() {
        if [[ "$DEBUG_MODE" == true ]]; then
            echo -e "\033[0;35m🐛 DEBUG: $1\033[0m" >&2
        fi
        [[ -n "$TEMP_LOG_FILE" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >> "$TEMP_LOG_FILE"
    }
    
    print_remote_verbose() {
        if [[ "$VERBOSE_MODE" == true ]] || [[ "$DEBUG_MODE" == true ]]; then
            echo -e "\033[0;36m📝 $1\033[0m" >&2
        fi
        [[ -n "$TEMP_LOG_FILE" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VERBOSE] $1" >> "$TEMP_LOG_FILE"
    }
    
    # Initialize temp logging
    TEMP_LOG_FILE="/tmp/shell-remote-install-$(date +%Y%m%d_%H%M%S).log"
    touch "$TEMP_LOG_FILE" 2>/dev/null || TEMP_LOG_FILE=""
    
    if [[ -n "$TEMP_LOG_FILE" ]]; then
        print_remote_step "Remote installation log: $TEMP_LOG_FILE"
        {
            echo "================================="
            echo "REMOTE INSTALLATION LOG"
            echo "================================="
            echo "Date: $(date)"
            echo "User: $(whoami)"
            echo "System: $(uname -a)"
            echo "Debug Mode: $DEBUG_MODE"
            echo "Verbose Mode: $VERBOSE_MODE"
            echo "================================="
        } >> "$TEMP_LOG_FILE"
    fi
    
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

# Initialize logging with original arguments (before parsing)
original_args=("$@")
init_logging

# Parse debug arguments and get remaining arguments
mapfile -t remaining_args < <(parse_debug_args "${original_args[@]}")

print_debug "Script directory: $SCRIPT_DIR"
print_debug "Remaining arguments: ${remaining_args[*]}"

# Global variables (after loading common module)
NON_INTERACTIVE=false
SYSTEM_WIDE=false

# Load installation modules
print_debug "Loading installation modules..."
source "$SCRIPT_DIR/install/packages.sh"
source "$SCRIPT_DIR/install/nvm.sh"
source "$SCRIPT_DIR/install/backup.sh"
source "$SCRIPT_DIR/install/config.sh"
source "$SCRIPT_DIR/install/system.sh"
source "$SCRIPT_DIR/install/verification.sh"
source "$SCRIPT_DIR/install/update.sh"
print_debug "All modules loaded successfully"

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
    
    # Run post-installation guide
    if [[ -f "scripts/post-install.sh" ]]; then
        echo "Running post-installation setup guide..."
        echo
        bash scripts/post-install.sh
    else
        echo -e "${CYAN}Next steps:${NC}"
        echo -e "  1. Restart your terminal or run: ${YELLOW}exec zsh${NC}"
        echo -e "  2. Run ${YELLOW}nvm-health${NC} to verify everything works"
        echo -e "  3. Run ${YELLOW}nvm-auto-install${NC} to configure Node.js auto-installation"  
        echo -e "  4. Edit ${YELLOW}~/.zsh_local${NC} for personal configurations"
        echo
        echo -e "${CYAN}Backup location:${NC} $BACKUP_DIR"
        echo -e "${CYAN}Configuration:${NC} $INSTALL_DIR"
        echo
        echo -e "${GREEN}Happy coding! 🚀${NC}"
    fi
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
    echo "  --debug              Enable debug mode with verbose logging"
    echo "  --verbose, -v        Enable verbose output"
    echo "  --log-file FILE      Specify custom log file location"
    echo "  --generate-report    Generate debug report and exit"
    echo ""
    echo "Debug Options:"
    echo "  --debug              Full debug mode (implies --verbose)"
    echo "  --verbose            Show detailed progress information"
    echo "  --generate-report    Create diagnostic report for troubleshooting"
    echo ""
    echo "Examples:"
    echo "  $0                   # Install for current user"
    echo "  sudo $0 --system     # Install system-wide"
    echo "  $0 --non-interactive # Silent installation"
    echo "  $0 --debug           # Debug installation issues"
    echo "  $0 --generate-report # Generate diagnostic report"
    echo "  $0 --uninstall       # Remove installation"
    echo ""
}

# Parse command line arguments (skip already parsed debug args)
set -- "${remaining_args[@]}"
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --system)
            SYSTEM_WIDE=true
            print_debug "System-wide installation mode enabled"
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            print_debug "Non-interactive mode enabled"
            shift
            ;;
        --uninstall)
            print_debug "Uninstall mode requested"
            if [[ "$SYSTEM_WIDE" == true ]]; then
                uninstall_system
            else
                uninstall_user
            fi
            exit 0
            ;;
        --health-check)
            print_debug "Health check requested"
            health_check
            exit 0
            ;;
        --generate-report)
            print_debug "Debug report generation requested"
            generate_debug_report
            exit 0
            ;;
        --debug|--verbose|-v|--log-file)
            # These were already processed by parse_debug_args
            if [[ "$1" == "--log-file" ]]; then
                shift # skip the file argument too
            fi
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            print_error "Run '$0 --help' for usage information"
            generate_debug_report
            exit 1
            ;;
    esac
done

# Trap to generate debug report on failure
trap 'if [[ $? -ne 0 ]]; then 
    print_error "Installation failed!"
    print_error "Debug information:"
    print_error "- Exit code: $?"
    print_error "- Last command: $BASH_COMMAND"
    print_error "- Log file: $LOG_FILE"
    if [[ "$DEBUG_MODE" == true ]]; then
        print_error "Generating debug report..."
        generate_debug_report
    else
        print_error "Run with --debug for detailed troubleshooting information"
        print_error "Or run: $0 --generate-report"
    fi
fi' EXIT

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