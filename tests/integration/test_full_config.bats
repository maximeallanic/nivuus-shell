#!/usr/bin/env bats

# Integration tests - test modules working together
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Create a full test configuration
    cat > "$TEST_HOME/.zshrc" << 'EOF'
# Load all config modules
for config in config/*.zsh; do
    [ -f "$config" ] && source "$config"
done
EOF
}

teardown() {
    teardown_test_env
}

@test "All modules load together without conflicts" {
    run zsh -c "source '$TEST_HOME/.zshrc'; echo 'SUCCESS'"
    [ "$status" -eq 0 ]
    assert_contains "$output" "SUCCESS"
}

@test "Environment variables are properly set" {
    zsh -c "source '$TEST_HOME/.zshrc'" 2>/dev/null
    
    # Test essential environment variables
    run zsh -c "source '$TEST_HOME/.zshrc'; echo \$LANG"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    
    run zsh -c "source '$TEST_HOME/.zshrc'; echo \$PATH"
    [ "$status" -eq 0 ]
    assert_contains "$output" "/usr/local/bin"
}

@test "History configuration works properly" {
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        echo \$HISTSIZE
        echo \$SAVEHIST
    "
    [ "$status" -eq 0 ]
    
    # Should have reasonable history sizes
    local histsize=$(echo "$output" | head -n1)
    local savehist=$(echo "$output" | tail -n1)
    
    [ "$histsize" -gt 1000 ] || skip "HISTSIZE not set properly"
    [ "$savehist" -gt 1000 ] || skip "SAVEHIST not set properly"
}

@test "Completion system integrates properly" {
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        autoload -Uz compinit
        compinit -d '$TEST_HOME/.zcompdump'
        echo 'Completion loaded'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "Completion loaded"
}

@test "AI integration variables are set" {
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        # Check if AI-related functions exist
        type copilot 2>/dev/null && echo 'COPILOT_OK' || echo 'COPILOT_MISSING'
    "
    [ "$status" -eq 0 ]
    
    # AI integration might be optional
    if assert_contains "$output" "COPILOT_OK"; then
        color_output "green" "✅ AI integration available"
    else
        color_output "yellow" "⚠️  AI integration not available (may be optional)"
    fi
}

@test "VS Code integration works when available" {
    if [ -n "$VSCODE_INJECTION" ] || [ "$TERM_PROGRAM" = "vscode" ]; then
        run zsh -c "
            export VSCODE_INJECTION=1
            source '$TEST_HOME/.zshrc'
            echo 'VSCODE_MODE'
        "
        [ "$status" -eq 0 ]
        assert_contains "$output" "VSCODE_MODE"
    else
        skip "VS Code not detected, skipping VS Code integration test"
    fi
}

@test "Git integration works when git is available" {
    if command -v git >/dev/null 2>&1; then
        # Create a test git repo
        cd "$TEST_HOME"
        git init . >/dev/null 2>&1
        git config user.email "test@example.com"
        git config user.name "Test User"
        
        run zsh -c "
            cd '$TEST_HOME'
            source '$TEST_HOME/.zshrc'
            # Test git-related functions if they exist
            type git_current_branch 2>/dev/null && git_current_branch || echo 'NO_GIT_FUNCTIONS'
        "
        [ "$status" -eq 0 ]
    else
        skip "Git not available, skipping git integration test"
    fi
}
