#!/bin/bash
# =============================================================================
# COMMON UTILITIES FOR INSTALLATION SCRIPTS
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Global variables
INSTALL_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$INSTALL_MODULE_DIR")"
NON_INTERACTIVE=false
SYSTEM_WIDE=false

# Configuration based on mode
set_install_dirs() {
    if [[ "$SYSTEM_WIDE" == true ]]; then
        INSTALL_DIR="/opt/modern-shell"
        BACKUP_DIR="/opt/modern-shell-backup"
    else
        INSTALL_DIR="$HOME/.config/zsh-ultra"
        BACKUP_DIR="$HOME/.config/zsh-ultra-backup"
    fi
}

# Check if running as root
check_root() {
    if [[ "$SYSTEM_WIDE" == true ]]; then
        if [[ $EUID -ne 0 ]]; then
            print_error "System-wide installation requires root privileges (use sudo)"
            exit 1
        fi
    else
        if [[ $EUID -eq 0 ]]; then
            print_error "User installation should not be run as root"
            exit 1
        fi
    fi
}

# Detect operating system and package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
        PACKAGE_MANAGER="brew"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS="linux"
        DISTRO="${ID,,}"
        
        case "$DISTRO" in
            ubuntu|debian|pop|elementary|zorin)
                PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|fedora|almalinux|rocky)
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                elif command -v yum &> /dev/null; then
                    PACKAGE_MANAGER="yum"
                fi
                ;;
            alpine)
                PACKAGE_MANAGER="apk"
                ;;
            arch|manjaro|endeavouros)
                PACKAGE_MANAGER="pacman"
                ;;
            opensuse*|suse*)
                PACKAGE_MANAGER="zypper"
                ;;
            *)
                # Try to detect by available commands
                if command -v apt &> /dev/null; then
                    PACKAGE_MANAGER="apt"
                elif command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                elif command -v yum &> /dev/null; then
                    PACKAGE_MANAGER="yum"
                elif command -v apk &> /dev/null; then
                    PACKAGE_MANAGER="apk"
                elif command -v pacman &> /dev/null; then
                    PACKAGE_MANAGER="pacman"
                elif command -v zypper &> /dev/null; then
                    PACKAGE_MANAGER="zypper"
                else
                    print_error "Unsupported package manager"
                    exit 1
                fi
                ;;
        esac
    else
        print_error "Unable to detect operating system"
        exit 1
    fi
    
    print_success "Detected: $OS ($DISTRO) with $PACKAGE_MANAGER"
}

# Check if required package manager is available
check_package_manager() {
    case "$PACKAGE_MANAGER" in
        brew)
            if ! command -v brew &> /dev/null; then
                print_error "Homebrew not found. Please install it first:"
                print_info "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            ;;
        apt|dnf|yum|apk|pacman|zypper)
            if ! command -v "$PACKAGE_MANAGER" &> /dev/null; then
                print_error "Package manager $PACKAGE_MANAGER not found"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported package manager: $PACKAGE_MANAGER"
            exit 1
            ;;
    esac
    print_success "Package manager $PACKAGE_MANAGER is available"
}

# Check if we're in the right directory
check_project_directory() {
    if [[ ! -f "$PROJECT_ROOT/config/16-nvm-integration.zsh" ]]; then
        print_error "Installation must be run from the shell configuration directory"
        print_error "Current directory: $(pwd)"
        print_error "Expected files not found in: $PROJECT_ROOT"
        exit 1
    fi
}

# Check if directory exists and is writable
check_directory() {
    local dir="$1"
    local create_if_missing="${2:-false}"
    
    if [[ ! -d "$dir" ]]; then
        if [[ "$create_if_missing" == true ]]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        else
            print_error "Directory does not exist: $dir"
            return 1
        fi
    fi
    
    if [[ ! -w "$dir" ]]; then
        print_error "Directory is not writable: $dir"
        return 1
    fi
    
    return 0
}
