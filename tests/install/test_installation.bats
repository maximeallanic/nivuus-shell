#!/usr/bin/env bats

# Installation script tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Use PROJECT_ROOT from test_helper
    export WORKSPACE_ROOT="$PROJECT_ROOT"
    
    # Source common.sh for testing
    source "$PROJECT_ROOT/install/common.sh"
    
    # Override some variables for testing
    INSTALL_MODULE_DIR="$PROJECT_ROOT/install"
}

teardown() {
    teardown_test_env
}

@test "Common.sh loads without errors" {
    run bash -c "source '$PROJECT_ROOT/install/common.sh'; echo 'LOADED'"
    [ "$status" -eq 0 ]
    assert_contains "$output" "LOADED"
}

@test "Print functions work correctly" {
    source "$PROJECT_ROOT/install/common.sh"
    
    run print_success "Test success message"
    [ "$status" -eq 0 ]
    assert_contains "$output" "✅ Test success message"
    
    run print_error "Test error message"
    [ "$status" -eq 0 ]
    assert_contains "$output" "❌ Test error message"
    
    run print_warning "Test warning message"
    [ "$status" -eq 0 ]
    assert_contains "$output" "⚠️  Test warning message"
}

@test "Debug mode functions work" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Test with debug mode off
    DEBUG_MODE=false
    run print_debug "Debug message"
    [ "$status" -eq 0 ]
    # Should not contain the debug message in output when debug is off
    
    # Test with debug mode on
    DEBUG_MODE=true
    run print_debug "Debug message"
    [ "$status" -eq 0 ]
    assert_contains "$output" "🐛 DEBUG: Debug message"
}

@test "Verbose mode functions work" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Test with verbose mode off
    VERBOSE_MODE=false
    DEBUG_MODE=false
    run print_verbose "Verbose message"
    [ "$status" -eq 0 ]
    
    # Test with verbose mode on
    VERBOSE_MODE=true
    run print_verbose "Verbose message"
    [ "$status" -eq 0 ]
    assert_contains "$output" "📝 Verbose message"
}

@test "Logging initialization works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Initialize logging
    init_logging
    
    # Check that log file was created
    [ -n "$LOG_FILE" ]
    [ -f "$LOG_FILE" ]
    
    # Check that system info was logged
    assert_file_exists "$LOG_FILE"
    run cat "$LOG_FILE"
    assert_contains "$output" "INSTALLATION DEBUG LOG"
    assert_contains "$output" "Date:"
    assert_contains "$output" "User:"
}

@test "OS detection works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Call detect_os directly (not through run)
    detect_os
    
    # Should detect some OS
    [ -n "$OS" ]
    [ -n "$DISTRO" ]
    [ -n "$PACKAGE_MANAGER" ]
    
    # Should be either linux or macos
    [[ "$OS" == "linux" || "$OS" == "macos" ]]
}

@test "Package manager detection works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # First detect OS to set PACKAGE_MANAGER
    detect_os
    
    run check_package_manager
    [ "$status" -eq 0 ]
    assert_contains "$output" "is available"
}

@test "Project directory check works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Should pass with correct PROJECT_ROOT
    PROJECT_ROOT="$PROJECT_ROOT"
    run check_project_directory
    [ "$status" -eq 0 ]
    
    # Should fail with incorrect PROJECT_ROOT
    PROJECT_ROOT="/tmp/nonexistent"
    run check_project_directory
    [ "$status" -eq 1 ]
    assert_contains "$output" "Installation must be run from the shell configuration directory"
}

@test "Directory check function works" {
    source "$PROJECT_ROOT/install/common.sh"
    init_logging
    
    # Test with existing directory
    run check_directory "$TEST_HOME"
    [ "$status" -eq 0 ]
    
    # Test with non-existing directory (should fail without create flag)
    run check_directory "$TEST_HOME/nonexistent"
    [ "$status" -eq 1 ]
    
    # Test with non-existing directory (should succeed with create flag)
    run check_directory "$TEST_HOME/testdir" true
    [ "$status" -eq 0 ]
    [ -d "$TEST_HOME/testdir" ]
}

@test "Execute command function works" {
    source "$PROJECT_ROOT/install/common.sh"
    init_logging
    
    # Test successful command
    run execute_cmd "echo 'test command'" "Testing echo"
    [ "$status" -eq 0 ]
    
    # Test failing command
    run execute_cmd "false" "Testing false command" false
    [ "$status" -eq 1 ]
    
    # Test that failing command with exit_on_error=true would exit
    # (we can't test actual exit, but we can test the logic)
}

@test "Command availability check works" {
    source "$PROJECT_ROOT/install/common.sh"
    init_logging
    
    # Test with existing command
    run check_command "bash"
    [ "$status" -eq 0 ]
    
    # Test with non-existing command (required)
    run check_command "nonexistent_command_12345"
    [ "$status" -eq 1 ]
    
    # Test with non-existing command (optional)
    run check_command "nonexistent_command_12345" false
    [ "$status" -eq 1 ]
}

@test "Set install dirs function works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Test user mode
    SYSTEM_WIDE=false
    set_install_dirs
    assert_contains "$INSTALL_DIR" ".config/zsh-ultra"
    
    # Test system-wide mode
    SYSTEM_WIDE=true
    set_install_dirs
    assert_contains "$INSTALL_DIR" "/opt/modern-shell"
}

@test "Debug argument parsing works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Initialize logging to avoid issues
    init_logging
    
    # Test debug flag
    DEBUG_MODE=false
    VERBOSE_MODE=false
    
    # Call function directly and check results
    parse_debug_args --debug --other-arg >/dev/null
    
    # Check if variables were set
    [[ "$DEBUG_MODE" == true ]]
    [[ "$VERBOSE_MODE" == true ]]
    
    # Reset for next test
    DEBUG_MODE=false
    VERBOSE_MODE=false
    
    # Test verbose flag
    parse_debug_args --verbose --another-arg >/dev/null
    [[ "$DEBUG_MODE" == false ]]
    [[ "$VERBOSE_MODE" == true ]]
}

@test "Log message function works" {
    source "$PROJECT_ROOT/install/common.sh"
    init_logging
    
    # Test logging a message
    log_message "TEST" "Test log message"
    
    # Check that message was logged
    run cat "$LOG_FILE"
    assert_contains "$output" "[TEST] Test log message"
}

@test "Debug report generation works" {
    source "$PROJECT_ROOT/install/common.sh"
    init_logging
    
    # Generate debug report
    run generate_debug_report
    [ "$status" -eq 0 ]
    assert_contains "$output" "Debug report generated:"
    
    # Check that report file exists
    local report_file="${LOG_FILE%.log}_debug_report.txt"
    [ -f "$report_file" ]
    
    # Check report contents
    run cat "$report_file"
    assert_contains "$output" "INSTALLATION DEBUG REPORT"
    assert_contains "$output" "SYSTEM INFORMATION"
    assert_contains "$output" "USER INFORMATION"
}

@test "Root check function works" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Test user mode (should not fail for non-root)
    SYSTEM_WIDE=false
    if [[ $EUID -ne 0 ]]; then
        run check_root
        [ "$status" -eq 0 ]
    fi
    
    # Test system-wide mode for non-root user (should fail)
    SYSTEM_WIDE=true
    if [[ $EUID -ne 0 ]]; then
        run check_root
        [ "$status" -eq 1 ]
        assert_contains "$output" "System-wide installation requires root privileges"
    fi
}

@test "Installation script can be called with debug flags" {
    # Test that the main install script accepts debug arguments
    run bash "$PROJECT_ROOT/install.sh" --help --debug
    # Should not crash (status might be 0 or 1 depending on help implementation)
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "Colors are properly defined" {
    source "$PROJECT_ROOT/install/common.sh"
    
    # Check that color variables are defined
    [ -n "$RED" ]
    [ -n "$GREEN" ]
    [ -n "$YELLOW" ]
    [ -n "$BLUE" ]
    [ -n "$NC" ]
    
    # Check that they contain ANSI escape sequences
    assert_contains "$RED" "033"
    assert_contains "$GREEN" "033"
    assert_contains "$NC" "033"
}
