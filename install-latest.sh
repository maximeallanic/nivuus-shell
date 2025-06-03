#!/bin/bash

# =============================================================================
# NIVUUS SHELL - INSTALLER FROM LATEST RELEASE
# =============================================================================

set -euo pipefail

# Repository configuration
readonly REPO_OWNER="maximeallanic"
readonly REPO_NAME="nivuus-shell"
readonly INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/master/install.sh"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info "Downloading Nivuus Shell installer from latest release..."

# Download and execute the installer
if command -v curl &> /dev/null; then
    bash <(curl -fsSL "$INSTALL_SCRIPT_URL") "$@"
elif command -v wget &> /dev/null; then
    bash <(wget -qO- "$INSTALL_SCRIPT_URL") "$@"
else
    echo "❌ Neither curl nor wget found. Please install one of them first."
    exit 1
fi

print_success "Installation completed!"
