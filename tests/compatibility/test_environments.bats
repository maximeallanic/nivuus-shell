#!/usr/bin/env bats

# Compatibility tests for different environments
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "Works with different ZSH versions" {
    local zsh_version=$(zsh --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    color_output "blue" "Testing with ZSH version: $zsh_version"
    
    run zsh -c "source config/01-performance.zsh; echo 'VERSION_OK'"
    [ "$status" -eq 0 ]
    assert_contains "$output" "VERSION_OK"
}

@test "Root-safe mode activates correctly" {
    # Simulate root environment
    run zsh -c "
        export MINIMAL_MODE=1
        export EUID=0
        source config/01-performance.zsh
        echo \$MINIMAL_MODE
        echo 'ROOT_SAFE_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "1"  # MINIMAL_MODE should be 1
    assert_contains "$output" "ROOT_SAFE_OK"
}

@test "Minimal mode works correctly" {
    run zsh -c "
        export MINIMAL_MODE=1
        source config/01-performance.zsh
        echo 'MINIMAL_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "MINIMAL_OK"
}

@test "Works without optional dependencies" {
    # Test that config works even if optional tools are missing
    run zsh -c "
        # Simulate missing tools by hiding them
        export PATH='/usr/bin:/bin'
        source config/01-performance.zsh
        echo 'NO_DEPS_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "NO_DEPS_OK"
}

@test "Handles missing directories gracefully" {
    # Test with restricted permissions
    local restricted_home="$TEST_HOME/restricted"
    mkdir -p "$restricted_home"
    chmod 555 "$restricted_home"  # Read-only
    
    run zsh -c "
        export HOME='$restricted_home'
        source config/01-performance.zsh 2>/dev/null || true
        echo 'RESTRICTED_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "RESTRICTED_OK"
    
    chmod 755 "$restricted_home"  # Restore permissions for cleanup
}

@test "Unicode and special characters handling" {
    run zsh -c "
        export LANG=C.UTF-8
        export LC_ALL=C.UTF-8
        source config/01-performance.zsh
        echo '🚀 Unicode test: éàü'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "🚀"
}

@test "SSH environment detection" {
    # Simulate SSH environment
    run zsh -c "
        export SSH_CLIENT='192.168.1.1 12345 22'
        export SSH_TTY='/dev/pts/0'
        source config/01-performance.zsh
        echo 'SSH_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "SSH_OK"
}

@test "Container environment compatibility" {
    # Simulate container environment
    run zsh -c "
        export container=docker
        unset DISPLAY
        source config/01-performance.zsh
        echo 'CONTAINER_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "CONTAINER_OK"
}
