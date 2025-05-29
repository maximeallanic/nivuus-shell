#!/bin/bash
# ZSH Ultra Performance Config - Test Suite
# Comprehensive testing for the modular ZSH configuration

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.config" 2>/dev/null || true

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Logging functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    ((TESTS_TOTAL++))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test syntax of ZSH files
test_syntax() {
    log_test "Testing ZSH syntax"
    
    local failed=0
    
    # Test main .zshrc file
    if zsh -n .zshrc 2>/dev/null; then
        log_pass "Main .zshrc syntax OK"
    else
        log_fail "Main .zshrc has syntax errors"
        failed=1
    fi
    
    # Test all module files
    for module in config/*.zsh; do
        if [[ -f "$module" ]]; then
            if zsh -n "$module" 2>/dev/null; then
                log_pass "$(basename "$module") syntax OK"
            else
                log_fail "$(basename "$module") has syntax errors"
                failed=1
            fi
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_pass "All ZSH files have valid syntax"
    fi
}

# Test file structure
test_file_structure() {
    log_test "Testing file structure"
    
    local failed=0
    
    # Check if all expected files exist
    if [[ ! -f ".zshrc" ]]; then
        log_fail "Main .zshrc file missing"
        failed=1
    fi
    
    if [[ ! -d "config" ]]; then
        log_fail "Config directory missing"
        failed=1
    fi
    
    # Check module files
    for module in "${MODULE_FILES[@]}"; do
        if [[ ! -f "config/$module" ]]; then
            log_fail "Module file missing: $module"
            failed=1
        fi
    done
    
    # Check scripts
    for script in "install.sh" "uninstall.sh"; do
        if [[ ! -f "$script" ]]; then
            log_fail "Script missing: $script"
            failed=1
        elif [[ ! -x "$script" ]]; then
            log_fail "Script not executable: $script"
            failed=1
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_pass "File structure is correct"
    fi
}

# Test module file sizes
test_file_sizes() {
    log_test "Testing module file sizes"
    
    local failed=0
    local max_size=${MAX_FILE_SIZE:-200}
    
    for module in config/*.zsh; do
        if [[ -f "$module" ]]; then
            local line_count=$(wc -l < "$module")
            if [[ $line_count -gt $max_size ]]; then
                log_fail "$(basename "$module") is too large: $line_count lines (max: $max_size)"
                failed=1
            else
                log_pass "$(basename "$module") size OK: $line_count lines"
            fi
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_pass "All modules are within size limits"
    fi
}

# Test dependencies
test_dependencies() {
    log_test "Testing system dependencies"
    
    local missing_deps=()
    
    # Check required packages
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing_deps+=("$pkg")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_pass "All required dependencies available"
    else
        log_warn "Missing dependencies: ${missing_deps[*]}"
    fi
    
    # Check optional packages
    local optional_available=()
    for pkg in "${OPTIONAL_PACKAGES[@]}"; do
        if command -v "$pkg" >/dev/null 2>&1; then
            optional_available+=("$pkg")
        fi
    done
    
    if [[ ${#optional_available[@]} -gt 0 ]]; then
        log_pass "Optional tools available: ${optional_available[*]}"
    fi
}

# Test ZSH startup performance
test_performance() {
    log_test "Testing ZSH startup performance"
    
    if ! command -v zsh >/dev/null 2>&1; then
        log_warn "ZSH not available, skipping performance test"
        return
    fi
    
    local total_time=0
    local test_count=5
    local target_time=${TARGET_STARTUP_TIME:-300}
    
    for i in $(seq 1 $test_count); do
        local start_time=$(date +%s%3N)
        zsh -i -c 'exit' 2>/dev/null || true
        local end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        total_time=$((total_time + duration))
    done
    
    local avg_time=$((total_time / test_count))
    
    if [[ $avg_time -le $target_time ]]; then
        log_pass "Average startup time: ${avg_time}ms (target: ${target_time}ms)"
    else
        log_fail "Startup time too slow: ${avg_time}ms (target: ${target_time}ms)"
    fi
}

# Test installation script
test_install_script() {
    log_test "Testing installation script"
    
    if [[ ! -f "install.sh" ]]; then
        log_fail "install.sh not found"
        return
    fi
    
    # Test script syntax
    if bash -n install.sh 2>/dev/null; then
        log_pass "install.sh syntax OK"
    else
        log_fail "install.sh has syntax errors"
    fi
    
    # Check for required functions
    local required_functions=("check_system" "install_packages" "setup_zsh")
    for func in "${required_functions[@]}"; do
        if grep -q "^$func()" install.sh; then
            log_pass "Function $func found in install.sh"
        else
            log_warn "Function $func not found in install.sh"
        fi
    done
}

# Test uninstallation script
test_uninstall_script() {
    log_test "Testing uninstallation script"
    
    if [[ ! -f "uninstall.sh" ]]; then
        log_fail "uninstall.sh not found"
        return
    fi
    
    # Test script syntax
    if bash -n uninstall.sh 2>/dev/null; then
        log_pass "uninstall.sh syntax OK"
    else
        log_fail "uninstall.sh has syntax errors"
    fi
}

# Test documentation
test_documentation() {
    log_test "Testing documentation"
    
    if [[ ! -f "README.md" ]]; then
        log_fail "README.md not found"
        return
    fi
    
    # Check for required sections
    local required_sections=("Installation" "Usage" "Features" "Requirements")
    for section in "${required_sections[@]}"; do
        if grep -qi "# $section\|## $section" README.md; then
            log_pass "Section '$section' found in README.md"
        else
            log_warn "Section '$section' not found in README.md"
        fi
    done
}

# Test shellcheck if available
test_shellcheck() {
    log_test "Running shellcheck analysis"
    
    if ! command -v shellcheck >/dev/null 2>&1; then
        log_warn "shellcheck not available, skipping"
        return
    fi
    
    local failed=0
    
    # Check shell scripts
    for script in install.sh uninstall.sh; do
        if shellcheck "$script" 2>/dev/null; then
            log_pass "shellcheck passed for $script"
        else
            log_fail "shellcheck failed for $script"
            failed=1
        fi
    done
    
    # Check ZSH modules (treat as bash for compatibility)
    for module in config/*.zsh; do
        if [[ -f "$module" ]]; then
            if shellcheck -s bash "$module" 2>/dev/null; then
                log_pass "shellcheck passed for $(basename "$module")"
            else
                log_warn "shellcheck issues in $(basename "$module")"
            fi
        fi
    done
}

# Main test runner
main() {
    echo "🧪 ZSH Ultra Performance Config - Test Suite"
    echo "============================================="
    echo
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run all tests
    test_syntax
    test_file_structure
    test_file_sizes
    test_dependencies
    test_performance
    test_install_script
    test_uninstall_script
    test_documentation
    test_shellcheck
    
    # Print results
    echo
    echo "📊 Test Results"
    echo "==============="
    echo -e "Total tests: ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
