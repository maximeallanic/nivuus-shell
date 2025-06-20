#!/usr/bin/env bats

# PATH Health Tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "PATH contains basic system directories" {
    # Test that PATH contains essential system directories
    echo "Current PATH: $PATH"
    
    # Check for essential directories
    run bash -c 'echo "$PATH" | grep -E "(^|:)/usr/bin(:|$)"'
    [ "$status" -eq 0 ] || fail "PATH missing /usr/bin"
    
    run bash -c 'echo "$PATH" | grep -E "(^|:)/bin(:|$)"'
    [ "$status" -eq 0 ] || fail "PATH missing /bin"
    
    run bash -c 'echo "$PATH" | grep -E "(^|:)/usr/sbin(:|$)"'
    [ "$status" -eq 0 ] || fail "PATH missing /usr/sbin"
    
    run bash -c 'echo "$PATH" | grep -E "(^|:)/sbin(:|$)"'
    [ "$status" -eq 0 ] || fail "PATH missing /sbin"
}

@test "Basic commands are available" {
    echo "Testing basic commands availability..."
    
    # Test essential commands
    run which ls
    [ "$status" -eq 0 ] || fail "ls command not found in PATH"
    
    run which cat
    [ "$status" -eq 0 ] || fail "cat command not found in PATH"
    
    run which sed
    [ "$status" -eq 0 ] || fail "sed command not found in PATH"
    
    run which grep
    [ "$status" -eq 0 ] || fail "grep command not found in PATH"
    
    run which awk
    [ "$status" -eq 0 ] || fail "awk command not found in PATH"
}

@test "PATH does not contain invalid directories" {
    echo "Current PATH: $PATH"
    
    # Check for problematic paths
    run bash -c 'echo "$PATH" | grep "/opt/homebrew/share/man"'
    [ "$status" -ne 0 ] || fail "PATH contains invalid homebrew man directory"
    
    # Check PATH is not empty
    [ -n "$PATH" ] || fail "PATH is empty"
    
    # Check PATH doesn't start with colon
    run bash -c 'echo "$PATH" | grep "^:"'
    [ "$status" -ne 0 ] || fail "PATH starts with colon"
    
    # Check PATH doesn't end with colon
    run bash -c 'echo "$PATH" | grep ":$"'
    [ "$status" -ne 0 ] || fail "PATH ends with colon"
}

@test "PATH has correct order" {
    echo "Current PATH: $PATH"
    
    # Extract first few PATH entries
    local first_paths=$(echo "$PATH" | cut -d: -f1-5)
    echo "First 5 PATH entries: $first_paths"
    
    # Check that system paths come before user paths
    run bash -c 'echo "$PATH" | grep -E "^/usr/local/bin:|^/usr/bin:"'
    [ "$status" -eq 0 ] || fail "System paths should come first"
}

@test "Load config and test PATH after loading" {
    # Source our configuration
    export ZSH_CONFIG_DIR="/home/mallanic/Projects/Personal/shell"
    
    # Load all configuration modules
    if [[ -d "$ZSH_CONFIG_DIR/config" ]]; then
        for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
            if [[ -r "$config_file" ]]; then
                echo "Loading: $config_file"
                source "$config_file"
            fi
        done
    fi
    
    echo "PATH after loading config: $PATH"
    
    # Test that basic commands still work
    run which ls
    [ "$status" -eq 0 ] || fail "ls not found after config load"
    
    run which cat
    [ "$status" -eq 0 ] || fail "cat not found after config load"
    
    run which sed
    [ "$status" -eq 0 ] || fail "sed not found after config load"
}

@test "Test eza alias functionality" {
    # Load config first
    export ZSH_CONFIG_DIR="/home/mallanic/Projects/Personal/shell"
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
    
    # Test if eza or ls alias works
    if command -v eza >/dev/null 2>&1; then
        run eza --version
        [ "$status" -eq 0 ] || fail "eza command failed"
    else
        echo "eza not available, checking ls alias"
        run ls --version
        [ "$status" -eq 0 ] || fail "ls command failed"
    fi
}

@test "Diagnose PATH corruption sources" {
    echo "=== PATH DIAGNOSIS ==="
    echo "Initial PATH: $PATH"
    
    # Check common PATH corruption sources
    if [[ -f "/home/mallanic/google-cloud-sdk/path.zsh.inc" ]]; then
        echo "Found Google Cloud SDK path file"
        source "/home/mallanic/google-cloud-sdk/path.zsh.inc"
        echo "PATH after Google Cloud SDK: $PATH"
    fi
    
    # Check for other potential sources
    if [[ -f ~/.zshenv ]]; then
        echo "Found ~/.zshenv"
        cat ~/.zshenv
    fi
    
    if [[ -f ~/.profile ]]; then
        echo "Found ~/.profile"  
        cat ~/.profile
    fi
    
    echo "Final PATH: $PATH"
    
    # This test always passes, it's just for diagnosis
    true
}
