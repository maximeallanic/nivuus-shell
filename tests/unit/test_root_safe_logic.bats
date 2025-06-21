#!/usr/bin/env bats

# Test pour vérifier la logique root-safe corrigée

load ../test_helper

setup() {
    export ORIGINAL_EUID="$EUID"
    export ORIGINAL_UID="$UID"
    export ORIGINAL_USER="${USER:-}"
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_SUDO_USER="${SUDO_USER:-}"
    export ORIGINAL_SUDO_UID="${SUDO_UID:-}"
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_LANG="${LANG:-}"
    export ORIGINAL_FORCE_ROOT_SAFE="${FORCE_ROOT_SAFE:-}"
    export ORIGINAL_MINIMAL_MODE="${MINIMAL_MODE:-}"
}

teardown() {
    export USER="$ORIGINAL_USER"
    export HOME="$ORIGINAL_HOME"
    export SUDO_USER="$ORIGINAL_SUDO_USER"
    export SUDO_UID="$ORIGINAL_SUDO_UID"
    export PATH="$ORIGINAL_PATH"
    export LANG="$ORIGINAL_LANG"
    export FORCE_ROOT_SAFE="$ORIGINAL_FORCE_ROOT_SAFE"
    export MINIMAL_MODE="$ORIGINAL_MINIMAL_MODE"
}

@test "normale user should not trigger root-safe mode" {
    # Simulate normal user environment
    export USER="testuser"
    export HOME="/home/testuser"
    unset SUDO_USER SUDO_UID FORCE_ROOT_SAFE MINIMAL_MODE
    export PATH="/usr/local/bin:/usr/bin:/bin"
    
    # Source the function from the config file
    run bash -c "
        source '$PROJECT_ROOT/config/99-root-safe.zsh'
        is_root_environment && echo 'ROOT_SAFE_ACTIVE' || echo 'ROOT_SAFE_INACTIVE'
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == "ROOT_SAFE_INACTIVE" ]]
}

@test "normal sudo su should not trigger root-safe mode" {
    # Simulate 'sudo su' environment - has SUDO_USER but normal PATH
    export USER="root"
    export HOME="/root"
    export SUDO_USER="testuser"
    export SUDO_UID="1000"
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    unset FORCE_ROOT_SAFE MINIMAL_MODE
    
    # Test with EUID=0 simulation
    run bash -c "
        # Simulate root environment
        EUID=0
        UID=0
        source '$PROJECT_ROOT/config/99-root-safe.zsh'
        is_root_environment && echo 'ROOT_SAFE_ACTIVE' || echo 'ROOT_SAFE_INACTIVE'
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == "ROOT_SAFE_INACTIVE" ]]
}

@test "restricted sudo environment should trigger root-safe mode" {
    # Simulate problematic sudo environment with restricted PATH
    export USER="root"
    export HOME="/root"
    export SUDO_USER="testuser"
    export SUDO_UID="1000"
    export PATH="/usr/bin:/bin"  # Restricted PATH
    unset FORCE_ROOT_SAFE MINIMAL_MODE
    
    run bash -c "
        EUID=0
        UID=0
        source '$PROJECT_ROOT/config/99-root-safe.zsh'
        is_root_environment && echo 'ROOT_SAFE_ACTIVE' || echo 'ROOT_SAFE_INACTIVE'
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == "ROOT_SAFE_ACTIVE" ]]
}

@test "forced root-safe mode should always activate" {
    # Test explicit activation
    export USER="testuser"
    export HOME="/home/testuser"
    export FORCE_ROOT_SAFE="1"
    unset SUDO_USER SUDO_UID MINIMAL_MODE
    export PATH="/usr/local/bin:/usr/bin:/bin"
    
    run bash -c "
        source '$PROJECT_ROOT/config/99-root-safe.zsh'
        is_root_environment && echo 'ROOT_SAFE_ACTIVE' || echo 'ROOT_SAFE_INACTIVE'
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == "ROOT_SAFE_ACTIVE" ]]
}

@test "minimal mode should activate root-safe" {
    # Test minimal mode activation
    export USER="testuser"
    export HOME="/home/testuser"
    export MINIMAL_MODE="1"
    unset SUDO_USER SUDO_UID FORCE_ROOT_SAFE
    export PATH="/usr/local/bin:/usr/bin:/bin"
    
    run bash -c "
        source '$PROJECT_ROOT/config/99-root-safe.zsh'
        is_root_environment && echo 'ROOT_SAFE_ACTIVE' || echo 'ROOT_SAFE_INACTIVE'
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == "ROOT_SAFE_ACTIVE" ]]
}

@test "root-safe diagnostics should work" {
    run bash -c "
        source '$PROJECT_ROOT/config/99-root-safe.zsh'
        root_safe_diagnostics 2>&1
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Root-Safe Diagnostics"* ]]
    [[ "$output" == *"EUID="* ]]
    [[ "$output" == *"USER="* ]]
    [[ "$output" == *"Root environment detected:"* ]]
}
