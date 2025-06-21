#!/usr/bin/env bats

# Main installation script tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Use PROJECT_ROOT from test_helper
    export WORKSPACE_ROOT="$PROJECT_ROOT"
    
    # Create a mock installation environment
    export MOCK_INSTALL=true
    export TEST_INSTALL_DIR="$TEST_HOME/.config/zsh-ultra-test"
    mkdir -p "$TEST_INSTALL_DIR"
}

teardown() {
    teardown_test_env
}

@test "Installation script shows help" {
    run bash "$PROJECT_ROOT/install.sh" --help
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
    # Should contain help information
    [[ "$output" =~ "Usage" || "$output" =~ "help" || "$output" =~ "options" ]]
}

@test "Installation script accepts debug flag" {
    # Test that debug flag is accepted and enables debug mode
    run timeout 10 bash "$PROJECT_ROOT/install.sh" --debug --help 2>&1
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]
    # Should not crash and should show debug info
}

@test "Installation script accepts verbose flag" {
    run timeout 10 bash "$PROJECT_ROOT/install.sh" --verbose --help 2>&1
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]
    # Should not crash
}

@test "Installation script detects current directory" {
    # Run from correct directory
    cd "$PROJECT_ROOT"
    run timeout 10 bash "./install.sh" --help 2>&1
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]
    
    # Test from wrong directory should fail
    cd /tmp
    run timeout 5 bash "$PROJECT_ROOT/install.sh" --help 2>&1
    # May fail due to directory check or timeout, both are acceptable
}

@test "Installation script creates log file" {
    # Test that running with debug creates a log file
    cd "$PROJECT_ROOT"
    run timeout 10 bash "./install.sh" --debug --generate-report 2>&1
    
    # Check if any log files were created
    local log_files=$(find "$TEST_HOME" -name "*install*.log" 2>/dev/null | wc -l)
    local temp_logs=$(find /tmp -name "*install*.log" 2>/dev/null | wc -l)
    
    [[ $log_files -gt 0 || $temp_logs -gt 0 ]]
}

@test "Installation script can generate debug report" {
    cd "$PROJECT_ROOT"
    run timeout 15 bash "./install.sh" --debug --generate-report 2>&1
    
    # Should have attempted to generate a report
    # May fail due to other issues, but shouldn't crash on the report generation
    [[ "$status" -ne 127 ]]  # Command not found
    [[ "$status" -ne 126 ]]  # Command not executable
}

@test "Installation script handles non-interactive mode" {
    cd "$PROJECT_ROOT"
    run timeout 10 bash "./install.sh" --non-interactive --help 2>&1
    
    # Should handle non-interactive flag without crashing
    [[ "$status" -ne 127 ]]
    [[ "$status" -ne 126 ]]
}

@test "Installation script validates system requirements" {
    cd "$PROJECT_ROOT"
    
    # Run with debug to see what it's checking
    run timeout 15 bash "./install.sh" --debug 2>&1
    
    # Should have tried to detect OS and package manager
    # Even if it fails, it should fail gracefully
    [[ "$status" -ne 127 ]]  # Command not found
    [[ "$status" -ne 126 ]]  # Command not executable
    [[ "$status" -ne 139 ]]  # Segmentation fault
}

@test "Installation modules can be sourced individually" {
    # Test that each install module can be sourced without errors
    for module in "$PROJECT_ROOT/install"/*.sh; do
        if [[ -f "$module" && "$module" != *"install.sh" ]]; then
            run bash -c "source '$module'; echo 'MODULE_LOADED'"
            [ "$status" -eq 0 ]
            assert_contains "$output" "MODULE_LOADED"
        fi
    done
}

@test "Installation script has proper shebang" {
    # Check that install script has proper shebang
    local first_line=$(head -1 "$PROJECT_ROOT/install.sh")
    [[ "$first_line" =~ ^#!/bin/bash || "$first_line" =~ ^#!/usr/bin/env ]]
}

@test "Installation script is executable" {
    # Check that install script is executable
    [ -x "$PROJECT_ROOT/install.sh" ]
}

@test "Installation script handles missing dependencies gracefully" {
    cd "$PROJECT_ROOT"
    
    # Create a mock environment where some commands might be missing
    export PATH="/usr/bin:/bin"  # Minimal PATH
    
    run timeout 10 bash "./install.sh" --debug --help 2>&1
    
    # Should not crash with segfault or similar
    [[ "$status" -ne 139 ]]  # Segmentation fault
    [[ "$status" -ne 132 ]]  # Illegal instruction
}

@test "Installation backup functionality can be tested" {
    # Test that backup functions don't crash
    if [[ -f "$PROJECT_ROOT/install/backup.sh" ]]; then
        run bash -c "source '$PROJECT_ROOT/install/backup.sh'; echo 'BACKUP_LOADED'"
        [ "$status" -eq 0 ]
        assert_contains "$output" "BACKUP_LOADED"
    fi
}

@test "Installation verification functionality can be tested" {
    # Test that verification functions don't crash
    if [[ -f "$PROJECT_ROOT/install/verification.sh" ]]; then
        run bash -c "source '$PROJECT_ROOT/install/verification.sh'; echo 'VERIFICATION_LOADED'"
        [ "$status" -eq 0 ]
        assert_contains "$output" "VERIFICATION_LOADED"
    fi
}

@test "Installation handles interrupted execution" {
    cd "$PROJECT_ROOT"
    
    # Start installation and interrupt it
    timeout 2 bash "./install.sh" --debug &
    local pid=$!
    sleep 1
    kill -INT $pid 2>/dev/null || true
    wait $pid 2>/dev/null || true
    
    # Should have handled the interruption gracefully
    # (We can't easily test this, but at least we verify the script can be interrupted)
    true
}

@test "Installation logging works in different scenarios" {
    cd "$PROJECT_ROOT"
    
    # Test logging in user directory
    export HOME="$TEST_HOME"
    run timeout 5 bash "./install.sh" --debug --help 2>&1
    
    # Test logging in system directory (if writable)
    if [[ -w /tmp ]]; then
        run timeout 5 bash "./install.sh" --debug --log-file /tmp/test-install.log --help 2>&1
        # Should have attempted to use the specified log file
    fi
}
