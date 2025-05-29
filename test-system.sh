#!/bin/bash
# =============================================================================
# TEST SYSTEM INSTALLATION
# Test the system-wide shell configuration
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
print_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
print_error() { echo -e "${RED}[FAIL]${NC} $1"; }

test_vim_system_config() {
    print_info "Testing system-wide vim configuration..."
    
    if [[ -f "/etc/vim/vimrc.modern" ]]; then
        print_success "System vim config exists"
    else
        print_error "System vim config missing"
        return 1
    fi
    
    if [[ -f "/etc/zsh/zshrc.d/99-vim-modern.zsh" ]]; then
        print_success "System zsh vim integration exists"
    else
        print_error "System zsh vim integration missing"
        return 1
    fi
}

test_shell_system_config() {
    print_info "Testing system-wide shell configuration..."
    
    if [[ -d "/opt/modern-shell" ]]; then
        print_success "Shell config directory exists"
    else
        print_error "Shell config directory missing"
        return 1
    fi
    
    if [[ -f "/etc/zsh/zshrc.d/00-modern-shell.zsh" ]]; then
        print_success "System shell integration exists"
    else
        print_error "System shell integration missing"
        return 1
    fi
}

test_vim_functionality() {
    print_info "Testing vim with modern config..."
    
    # Create a test file
    local test_file="/tmp/vim_test_$$"
    echo "Test vim functionality" > "$test_file"
    
    # Test vim command with system config
    if vim -u /etc/vim/vimrc.modern -c ":q" "$test_file" 2>/dev/null; then
        print_success "Vim with modern config works"
    else
        print_error "Vim with modern config failed"
        rm -f "$test_file"
        return 1
    fi
    
    rm -f "$test_file"
}

test_root_config() {
    print_info "Testing root user configuration..."
    
    if [[ -f "/root/.vimrc.modern" ]]; then
        print_success "Root vim config exists"
    else
        print_error "Root vim config missing"
        return 1
    fi
    
    if [[ -f "/root/.zshrc" ]]; then
        print_success "Root shell config exists"
    else
        print_error "Root shell config missing"
        return 1
    fi
}

main() {
    echo "=== SYSTEM INSTALLATION TEST ==="
    echo ""
    
    local tests_passed=0
    local tests_total=4
    
    if test_vim_system_config; then
        ((tests_passed++))
    fi
    
    if test_shell_system_config; then
        ((tests_passed++))
    fi
    
    if test_vim_functionality; then
        ((tests_passed++))
    fi
    
    if test_root_config; then
        ((tests_passed++))
    fi
    
    echo ""
    echo "=== TEST RESULTS ==="
    echo "Tests passed: $tests_passed/$tests_total"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        print_success "All tests passed! System installation is working correctly."
        exit 0
    else
        print_error "Some tests failed. System installation may have issues."
        exit 1
    fi
}

main "$@"
