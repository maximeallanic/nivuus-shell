#!/bin/bash
# =============================================================================
# INSTALLATION TEST SCRIPT
# Test installation functions and debugging features
# =============================================================================

set -euo pipefail

# Import functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/install/common.sh"

main() {
    echo "🧪 Testing installation functions..."
    echo "===================================="
    
    # Test 1: Initialize logging
    echo "📝 Test 1: Initialize logging"
    init_logging
    echo "✅ Log file created: $LOG_FILE"
    
    # Test 2: Test print functions
    echo "📝 Test 2: Print functions"
    print_success "Success message test"
    print_warning "Warning message test"
    print_error "Error message test"
    print_info "Info message test"
    
    # Test 3: Test debug mode
    echo "📝 Test 3: Debug mode"
    DEBUG_MODE=true
    print_debug "Debug message test"
    DEBUG_MODE=false
    
    # Test 4: Test verbose mode
    echo "📝 Test 4: Verbose mode"
    VERBOSE_MODE=true
    print_verbose "Verbose message test"
    VERBOSE_MODE=false
    
    # Test 5: Test OS detection
    echo "📝 Test 5: OS detection"
    detect_os
    echo "✅ Detected: $OS ($DISTRO) with $PACKAGE_MANAGER"
    
    # Test 6: Test package manager check
    echo "📝 Test 6: Package manager check"
    check_package_manager
    
    # Test 7: Test directory check
    echo "📝 Test 7: Directory check"
    test_dir="/tmp/test-shell-install-$$"
    check_directory "$test_dir" true
    echo "✅ Directory check passed"
    rmdir "$test_dir" 2>/dev/null || true
    
    # Test 8: Test command check
    echo "📝 Test 8: Command availability check"
    check_command "bash"
    check_command "nonexistent_command_12345" false || echo "✅ Correctly detected missing command"
    
    # Test 9: Test argument parsing
    echo "📝 Test 9: Argument parsing"
    DEBUG_MODE=false
    VERBOSE_MODE=false
    remaining=$(parse_debug_args --debug --verbose --other-arg)
    echo "✅ Debug mode: $DEBUG_MODE, Verbose mode: $VERBOSE_MODE"
    echo "✅ Remaining args: $remaining"
    
    # Test 10: Generate debug report
    echo "📝 Test 10: Generate debug report"
    generate_debug_report
    
    echo ""
    echo "🎉 All installation function tests completed!"
    echo "📄 Check log file for details: $LOG_FILE"
    echo "📄 Debug report also generated"
}

# Handle script arguments
if [[ $# -gt 0 ]]; then
    # Parse any debug arguments passed to this test script
    remaining_args=($(parse_debug_args "$@"))
    
    # Handle remaining arguments
    for arg in "${remaining_args[@]}"; do
        case "$arg" in
            --help|-h)
                echo "Usage: $0 [--debug] [--verbose] [--help]"
                echo "Test the installation functions with optional debug output"
                exit 0
                ;;
        esac
    done
fi

main
