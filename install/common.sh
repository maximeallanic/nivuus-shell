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
    log_message "HEADER" "$1"
}

print_step() {
    echo -e "${CYAN}➤ $1${NC}"
    log_message "STEP" "$1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_message "WARNING" "$1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log_message "ERROR" "$1"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log_message "INFO" "$1"
}

print_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo -e "${PURPLE}🐛 DEBUG: $1${NC}"
    fi
    log_message "DEBUG" "$1"
}

print_verbose() {
    if [[ "$VERBOSE_MODE" == true ]] || [[ "$DEBUG_MODE" == true ]]; then
        echo -e "${CYAN}📝 $1${NC}"
    fi
    log_message "VERBOSE" "$1"
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

# Log system information
log_system_info() {
    if [[ -z "$LOG_FILE" ]]; then
        return
    fi
    
    {
        echo "================================="
        echo "INSTALLATION DEBUG LOG"
        echo "================================="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "UID: $(id -u)"
        echo "GID: $(id -g)"
        echo "PWD: $(pwd)"
        echo "HOME: $HOME"
        echo "SHELL: $SHELL"
        echo "PATH: $PATH"
        echo "OS: $(uname -a)"
        echo "Distro: $(cat /etc/os-release 2>/dev/null | head -5 || echo 'Unknown')"
        echo "Project Root: $PROJECT_ROOT"
        echo "Install Dir: $INSTALL_MODULE_DIR"
        echo "System Wide: $SYSTEM_WIDE"
        echo "Non Interactive: $NON_INTERACTIVE"
        echo "Debug Mode: $DEBUG_MODE"
        echo "Verbose Mode: $VERBOSE_MODE"
        echo "================================="
        echo ""
    } >> "$LOG_FILE"
}

# Global variables
INSTALL_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$INSTALL_MODULE_DIR")"
NON_INTERACTIVE=false
SYSTEM_WIDE=false

# Debug and logging variables
DEBUG_MODE=false
VERBOSE_MODE=false
LOG_FILE=""
INSTALL_LOG=""

# Initialize logging
init_logging() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    if [[ "$SYSTEM_WIDE" == true ]]; then
        INSTALL_LOG="/tmp/shell-install-${timestamp}.log"
    else
        INSTALL_LOG="$HOME/.cache/shell-install-${timestamp}.log"
        mkdir -p "$(dirname "$INSTALL_LOG")"
    fi
    
    # Create log file
    touch "$INSTALL_LOG" 2>/dev/null || {
        INSTALL_LOG="/tmp/shell-install-${timestamp}.log"
        touch "$INSTALL_LOG"
    }
    
    LOG_FILE="$INSTALL_LOG"
    
    # Log system info at start
    log_system_info
    
    print_info "Installation log: $INSTALL_LOG"
}

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
        export OS="macos"
        export DISTRO="macos"
        export PACKAGE_MANAGER="brew"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        export OS="linux"
        export DISTRO="${ID,,}"
        
        case "$DISTRO" in
            ubuntu|debian|pop|elementary|zorin)
                export PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|fedora|almalinux|rocky)
                if command -v dnf &> /dev/null; then
                    export PACKAGE_MANAGER="dnf"
                elif command -v yum &> /dev/null; then
                    export PACKAGE_MANAGER="yum"
                fi
                ;;
            alpine)
                export PACKAGE_MANAGER="apk"
                ;;
            arch|manjaro|endeavouros)
                export PACKAGE_MANAGER="pacman"
                ;;
            opensuse*|suse*)
                export PACKAGE_MANAGER="zypper"
                ;;
            *)
                # Try to detect by available commands
                if command -v apt &> /dev/null; then
                    export PACKAGE_MANAGER="apt"
                elif command -v dnf &> /dev/null; then
                    export PACKAGE_MANAGER="dnf"
                elif command -v yum &> /dev/null; then
                    export PACKAGE_MANAGER="yum"
                elif command -v apk &> /dev/null; then
                    export PACKAGE_MANAGER="apk"
                elif command -v pacman &> /dev/null; then
                    export PACKAGE_MANAGER="pacman"
                elif command -v zypper &> /dev/null; then
                    export PACKAGE_MANAGER="zypper"
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
    
    print_debug "Checking directory: $dir"
    
    if [[ ! -d "$dir" ]]; then
        if [[ "$create_if_missing" == true ]]; then
            print_debug "Creating missing directory: $dir"
            if mkdir -p "$dir" 2>>"$LOG_FILE"; then
                print_success "Created directory: $dir"
            else
                print_error "Failed to create directory: $dir"
                return 1
            fi
        else
            print_error "Directory does not exist: $dir"
            return 1
        fi
    fi
    
    if [[ ! -w "$dir" ]]; then
        print_error "Directory is not writable: $dir"
        print_debug "Directory permissions: $(ls -ld "$dir" 2>/dev/null || echo 'Cannot read permissions')"
        return 1
    fi
    
    print_debug "Directory check passed: $dir"
    return 0
}

# Execute command with logging
execute_cmd() {
    local cmd="$1"
    local description="${2:-Running command}"
    local exit_on_error="${3:-true}"
    
    print_verbose "$description"
    print_debug "Executing: $cmd"
    
    if eval "$cmd" 2>>"$LOG_FILE"; then
        print_debug "Command succeeded: $cmd"
        return 0
    else
        local exit_code=$?
        print_error "Command failed (exit code: $exit_code): $cmd"
        log_message "ERROR" "Command output may be in log file"
        
        if [[ "$exit_on_error" == true ]]; then
            print_error "Installation aborted due to command failure"
            print_error "Check log file for details: $LOG_FILE"
            exit $exit_code
        fi
        return $exit_code
    fi
}

# Check command availability with logging
check_command() {
    local cmd="$1"
    local required="${2:-true}"
    
    print_debug "Checking command availability: $cmd"
    
    if command -v "$cmd" &> /dev/null; then
        local version=$(${cmd} --version 2>/dev/null | head -1 || echo "Unknown version")
        print_debug "Command found: $cmd ($version)"
        return 0
    else
        if [[ "$required" == true ]]; then
            print_error "Required command not found: $cmd"
            return 1
        else
            print_warning "Optional command not found: $cmd"
            return 1
        fi
    fi
}

# Generate debug report
generate_debug_report() {
    local report_file="${LOG_FILE%.log}_debug_report.txt"
    
    print_info "Generating debug report: $report_file"
    
    {
        echo "================================="
        echo "INSTALLATION DEBUG REPORT"
        echo "================================="
        echo "Generated: $(date)"
        echo ""
        
        echo "=== SYSTEM INFORMATION ==="
        uname -a
        echo ""
        
        echo "=== DISTRIBUTION INFO ==="
        cat /etc/os-release 2>/dev/null || echo "Not available"
        echo ""
        
        echo "=== USER INFORMATION ==="
        echo "User: $(whoami)"
        echo "UID: $(id -u)"
        echo "Groups: $(groups)"
        echo "Home: $HOME"
        echo "Shell: $SHELL"
        echo ""
        
        echo "=== ENVIRONMENT ==="
        echo "PATH: $PATH"
        echo "PWD: $(pwd)"
        echo "Project Root: $PROJECT_ROOT"
        echo "Install Dir: $INSTALL_MODULE_DIR"
        echo ""
        
        echo "=== FILE PERMISSIONS ==="
        echo "Project root permissions:"
        ls -la "$PROJECT_ROOT" 2>/dev/null || echo "Cannot access project root"
        echo ""
        echo "Config directory permissions:"
        ls -la "$PROJECT_ROOT/config" 2>/dev/null || echo "Cannot access config directory"
        echo ""
        
        echo "=== PACKAGE MANAGERS ==="
        for pm in apt dnf yum brew pacman apk zypper; do
            if command -v "$pm" &>/dev/null; then
                echo "$pm: $(command -v "$pm") ($(${pm} --version 2>/dev/null | head -1 || echo 'version unknown'))"
            fi
        done
        echo ""
        
        echo "=== SHELLS ==="
        for shell in bash zsh fish; do
            if command -v "$shell" &>/dev/null; then
                echo "$shell: $(command -v "$shell") ($(${shell} --version 2>/dev/null | head -1 || echo 'version unknown'))"
            fi
        done
        echo ""
        
        echo "=== INSTALLATION LOG ==="
        if [[ -f "$LOG_FILE" ]]; then
            cat "$LOG_FILE"
        else
            echo "Log file not found: $LOG_FILE"
        fi
        
    } > "$report_file"
    
    print_success "Debug report generated: $report_file"
    print_info "Send this report when asking for support"
}

# Parse command line arguments for debug options
parse_debug_args() {
    local remaining_args=()
    
    # Force initialize variables if not properly set
    [[ -z "$DEBUG_MODE" ]] && DEBUG_MODE=false
    [[ -z "$VERBOSE_MODE" ]] && VERBOSE_MODE=false
    
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
            --log-file)
                LOG_FILE="$2"
                echo "ℹ️  Using log file: $LOG_FILE" >&2
                shift 2
                ;;
            --generate-report)
                # Will be handled after init_logging
                remaining_args+=("$1")
                shift
                ;;
            *)
                # Keep other arguments
                remaining_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Output remaining arguments
    printf '%s\n' "${remaining_args[@]}"
}
