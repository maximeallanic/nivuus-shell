#!/bin/bash
# =============================================================================
# REMOTE SHELL CONFIGURATION INSTALLER (USER)
# Download and install modern shell configuration for current user
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/maximeallanic/zshrc.git"
TEMP_DIR="/tmp/modern-shell-installer-$$"

# Print functions
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v zsh &> /dev/null; then
        missing_deps+=("zsh")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and try again"
        
        # Suggest installation command based on system
        if command -v apt-get &> /dev/null; then
            print_info "Try: sudo apt-get install ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            print_info "Try: sudo yum install ${missing_deps[*]}"
        elif command -v pacman &> /dev/null; then
            print_info "Try: sudo pacman -S ${missing_deps[*]}"
        elif command -v brew &> /dev/null; then
            print_info "Try: brew install ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    print_success "All dependencies are available"
}

# Download repository
download_repository() {
    print_info "Downloading shell configuration..."
    
    # Clean up any existing temporary directory
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    # Try curl method first (more reliable for public repos)
    print_info "Using curl method for download..."
    mkdir -p "$TEMP_DIR"
    
    if curl -fsSL "https://github.com/maximeallanic/zshrc/archive/refs/heads/master.tar.gz" | tar -xz -C "$TEMP_DIR" --strip-components=1; then
        print_success "Repository downloaded successfully using curl"
    else
        print_warning "Curl method failed, trying git clone..."
        rm -rf "$TEMP_DIR"
        
        # Configure git to avoid credential prompts for this session
        export GIT_TERMINAL_PROMPT=0
        
        # Try git clone as fallback
        if git clone --depth 1 "https://github.com/maximeallanic/zshrc.git" "$TEMP_DIR" 2>/dev/null; then
            print_success "Repository downloaded successfully using git"
        else
            print_error "Both download methods failed"
            exit 1
        fi
    fi
    
    # Verify the download
    if [[ ! -d "$TEMP_DIR" ]] || [[ ! -f "$TEMP_DIR/install.sh" ]]; then
        print_error "Failed to download repository or installation script not found"
        exit 1
    fi
    
    print_success "Repository downloaded and verified successfully"
}

# Run installation
run_installation() {
    print_info "Running user installation..."
    
    cd "$TEMP_DIR"
    
    # Make sure installation script is executable
    chmod +x install.sh
    
    # Run the installation script
    ./install.sh
    
    print_success "Installation completed"
}

# Cleanup
cleanup() {
    print_info "Cleaning up temporary files..."
    
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    print_success "Cleanup completed"
}

# Main function
main() {
    print_info "Starting remote user shell configuration installation..."
    
    check_dependencies
    download_repository
    run_installation
    cleanup
    
    print_success "Remote installation completed successfully!"
    print_info "Run 'source ~/.zshrc' or restart terminal to apply changes"
}

# Handle interrupts and errors
trap 'print_error "Installation interrupted"; cleanup; exit 1' INT TERM
trap 'print_error "Installation failed"; cleanup; exit 1' ERR

# Run installer
main "$@"
