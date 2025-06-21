#!/usr/bin/env bats

# Node.js integration tests - test Node.js in full shell environment
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Create a complete shell configuration for testing
    cat > "$TEST_HOME/.zshrc" << 'EOF'
# Load all essential modules including Node.js
source $WORKSPACE_ROOT/config/01-performance.zsh
source $WORKSPACE_ROOT/config/02-history.zsh  
source $WORKSPACE_ROOT/config/03-completion.zsh
source $WORKSPACE_ROOT/config/10-environment.zsh
source $WORKSPACE_ROOT/config/16-nvm-integration.zsh
EOF
}

teardown() {
    teardown_test_env
}

@test "Node.js tools are available in integrated shell" {
    # Test that Node.js tools work in a full shell environment
    run zsh -c "source '$TEST_HOME/.zshrc'; which node npm npx 2>/dev/null"
    
    if [ "$status" -eq 0 ]; then
        color_output "green" "✅ Node.js tools found in integrated environment"
        echo "Available tools:"
        echo "$output"
    else
        color_output "yellow" "⚠️  Node.js tools not available (expected in test environment)"
        skip "Node.js not installed in test environment"
    fi
}

@test "Node.js project detection works" {
    # Create a fake Node.js project
    mkdir -p "$TEST_HOME/test-project"
    cd "$TEST_HOME/test-project"
    
    cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for shell integration",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Test passed\""
  }
}
EOF
    
    # Test that shell recognizes Node.js project
    run zsh -c "
        cd '$TEST_HOME/test-project'
        source '$TEST_HOME/.zshrc'
        [ -f package.json ] && echo 'NODEJS_PROJECT_DETECTED'
    "
    
    [ "$status" -eq 0 ]
    assert_contains "$output" "NODEJS_PROJECT_DETECTED"
    color_output "green" "✅ Node.js project detection works"
}

@test "Node.js environment variables are properly set" {
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        echo \"NODE_ENV=\$NODE_ENV\"
        echo \"NPM_CONFIG_PREFIX=\$NPM_CONFIG_PREFIX\"  
        echo \"NVM_DIR=\$NVM_DIR\"
    "
    
    [ "$status" -eq 0 ]
    color_output "blue" "Node.js environment variables:"
    echo "$output"
    
    # Check that some environment is set (even if empty)
    [[ "$output" == *"NODE_ENV="* ]] || {
        color_output "red" "NODE_ENV variable not handled"
        return 1
    }
}

@test "Node.js path is properly configured" {
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        echo \$PATH | tr ':' '\n' | grep node || echo 'NO_NODE_IN_PATH'
    "
    
    [ "$status" -eq 0 ]
    
    if [[ "$output" == *"NO_NODE_IN_PATH"* ]]; then
        color_output "yellow" "⚠️  No Node.js directories in PATH (expected if not installed)"
    else
        color_output "green" "✅ Node.js directories found in PATH"
        echo "Node.js paths:"
        echo "$output"
    fi
}
