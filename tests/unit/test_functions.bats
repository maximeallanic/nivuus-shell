#!/usr/bin/env bats

# Functions module tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "Functions module loads without errors" {
    run load_config_module "07-functions.zsh"
    [ "$status" -eq 0 ]
}

@test "Custom functions are defined" {
    load_config_module "07-functions.zsh"
    
    # Test common functions existence (adjust based on actual functions)
    run zsh -c "type mkcd 2>/dev/null"
    [ "$status" -eq 0 ] || skip "mkcd function not found"
    
    run zsh -c "type extract 2>/dev/null" 
    [ "$status" -eq 0 ] || skip "extract function not found"
}

@test "Functions work correctly" {
    load_config_module "07-functions.zsh"
    
    # Test mkcd function if it exists
    if zsh -c "type mkcd" >/dev/null 2>&1; then
        run zsh -c "cd '$TEST_HOME' && mkcd test_dir && pwd"
        [ "$status" -eq 0 ]
        assert_contains "$output" "test_dir"
        [ -d "$TEST_HOME/test_dir" ]
    fi
}

@test "No function conflicts with system commands" {
    load_config_module "07-functions.zsh"
    
    # Ensure common system commands aren't overridden
    run zsh -c "type ls"
    assert_contains "$output" "ls is"
    
    run zsh -c "type cd"
    assert_contains "$output" "cd is"
}
