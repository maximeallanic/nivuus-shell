#!/usr/bin/env bats

# Main test runner configuration
# Loads all test suites and provides global setup/teardown

load test_helper

# Global setup - runs once before all tests
setup_file() {
    color_output "blue" "🧪 Setting up test environment..."
    
    # Verify we're in the right directory
    [ -f "README.md" ] || {
        color_output "red" "❌ Tests must be run from project root"
        exit 1
    }
    
    # Check required tools
    assert_command_exists "zsh"
    assert_command_exists "git"
    
    color_output "green" "✅ Test environment ready"
}

# Global teardown - runs once after all tests
teardown_file() {
    color_output "blue" "🧹 Cleaning up test environment..."
    # Global cleanup if needed
}

# Individual test setup
setup() {
    setup_test_env
}

# Individual test teardown
teardown() {
    teardown_test_env
}

@test "Project structure validation" {
    # Core files
    assert_file_exists "README.md"
    assert_file_exists "Makefile" 
    assert_file_exists "install.sh"
    assert_file_exists "uninstall.sh"
    
    # Config directory
    assert_directory_exists "config"
    assert_file_exists "config/01-performance.zsh"
    
    # Install directory
    assert_directory_exists "install"
    assert_file_exists "install/common.sh"
}

@test "Main config files syntax check" {
    # Test main config modules syntax
    for config_file in config/*.zsh; do
        [ -f "$config_file" ] || continue
        
        run zsh -n "$config_file"
        [ "$status" -eq 0 ] || {
            color_output "red" "❌ Syntax error in $config_file"
            echo "$output"
            return 1
        }
    done
}

@test "Install scripts syntax check" {
    for script in install/*.sh; do
        [ -f "$script" ] || continue
        
        run bash -n "$script"
        [ "$status" -eq 0 ] || {
            color_output "red" "❌ Syntax error in $script"
            echo "$output"
            return 1
        }
    done
}
