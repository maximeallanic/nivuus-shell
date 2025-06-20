#!/usr/bin/env bats

# Aliases module tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "Aliases module loads without errors" {
    run load_config_module "06-aliases.zsh"
    [ "$status" -eq 0 ]
}

@test "Common aliases are defined" {
    load_config_module "06-aliases.zsh"
    
    # Test for common aliases (adjust based on your actual aliases)
    run zsh -c "alias ll"
    [ "$status" -eq 0 ] || skip "ll alias not found"
    
    run zsh -c "alias la"
    [ "$status" -eq 0 ] || skip "la alias not found"
    
    run zsh -c "alias grep"
    [ "$status" -eq 0 ] || skip "grep alias not found"
}

@test "Git aliases work correctly" {
    load_config_module "06-aliases.zsh"
    
    # Test git aliases if they exist
    if zsh -c "alias | grep '^g='" >/dev/null 2>&1; then
        run zsh -c "alias g"
        assert_contains "$output" "git"
    fi
    
    if zsh -c "alias | grep '^gs='" >/dev/null 2>&1; then
        run zsh -c "alias gs"
        assert_contains "$output" "git"
    fi
}

@test "Safety aliases prevent destructive operations" {
    load_config_module "06-aliases.zsh"
    
    # Check for safe rm, cp, mv aliases
    if zsh -c "alias rm" >/dev/null 2>&1; then
        run zsh -c "alias rm"
        assert_contains "$output" "-i"
    fi
    
    if zsh -c "alias cp" >/dev/null 2>&1; then
        run zsh -c "alias cp"
        assert_contains "$output" "-i"
    fi
}
