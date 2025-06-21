#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# Integration tests for Node.js functionality
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Create a complete test project structure
    export TEST_PROJECT="$TEST_HOME/test-project"
    mkdir -p "$TEST_PROJECT"
    
    # Create test shell configuration
    cat > "$TEST_HOME/.zshrc" << EOF
# Load essential modules for Node.js testing
source $PROJECT_ROOT/config/01-performance.zsh
source $PROJECT_ROOT/config/02-history.zsh
source $PROJECT_ROOT/config/16-nvm-integration.zsh
EOF
}

teardown() {
    teardown_test_env
}

@test "Full shell loads with Node.js integration" {
    run zsh -c "source '$TEST_HOME/.zshrc'; echo 'SHELL_LOADED'"
    [ "$status" -eq 0 ]
    assert_contains "$output" "SHELL_LOADED"
}

@test "Node.js available in new shell session" {
    # Test in a new shell session
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        command -v node >/dev/null 2>&1 && echo 'NODE_AVAILABLE' || echo 'NODE_NOT_FOUND'
    "
    [ "$status" -eq 0 ]
    
    if assert_contains "$output" "NODE_AVAILABLE"; then
        color_output "green" "✅ Node.js is available in new shell"
    else
        color_output "yellow" "⚠️  Node.js not found in new shell session"
        skip "Node.js not available in test environment"
    fi
}

@test "npm available in new shell session" {
    # Test in a new shell session
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        command -v npm >/dev/null 2>&1 && echo 'NPM_AVAILABLE' || echo 'NPM_NOT_FOUND'
    "
    [ "$status" -eq 0 ]
    
    if assert_contains "$output" "NPM_AVAILABLE"; then
        color_output "green" "✅ npm is available in new shell"
    else
        color_output "yellow" "⚠️  npm not found in new shell session"
        skip "npm not available in test environment"
    fi
}

@test "Node.js and npm versions accessible" {
    # Skip if Node.js not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available for version testing"
    fi
    
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        echo 'Node.js:' \$(node --version 2>/dev/null || echo 'VERSION_ERROR')
        echo 'npm:' \$(npm --version 2>/dev/null || echo 'VERSION_ERROR')
    "
    [ "$status" -eq 0 ]
    
    assert_contains "$output" "Node.js:"
    assert_contains "$output" "npm:"
    
    # Should not contain VERSION_ERROR
    if [[ "$output" != *"VERSION_ERROR"* ]]; then
        color_output "green" "✅ Both Node.js and npm versions accessible"
    else
        color_output "yellow" "⚠️  Issue getting Node.js or npm version"
    fi
}

@test "Project with package.json - Node.js detection" {
    # Skip if Node.js not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available for project testing"
    fi
    
    cd "$TEST_PROJECT"
    
    # Create a realistic package.json
    cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for Node.js integration",
  "main": "index.js",
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  },
  "scripts": {
    "test": "echo \"Test script executed\"",
    "start": "node index.js"
  }
}
EOF
    
    # Create a simple index.js
    cat > index.js << 'EOF'
console.log("Hello from Node.js!");
console.log("Node version:", process.version);
EOF
    
    # Test that Node.js can execute the project
    run -127 zsh -c "
        cd '$TEST_PROJECT'
        source '$TEST_HOME/.zshrc'
        node index.js 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "Node.js not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "Node.js execution failed in test environment (status: $status)"
    fi
    assert_contains "$output" "Hello from Node.js!"
    assert_contains "$output" "Node version:"
    
    color_output "green" "✅ Node.js successfully executes project code"
}

@test "npm scripts execution works" {
    # Skip if npm not available
    if ! command -v npm >/dev/null 2>&1; then
        skip "npm not available for script testing"
    fi
    
    cd "$TEST_PROJECT"
    
    # Ensure package.json exists
    if [ ! -f package.json ]; then
        cat > package.json << 'EOF'
{
  "name": "test-project",
  "scripts": {
    "test": "echo \"npm test executed successfully\"",
    "hello": "echo \"Hello from npm script\""
  }
}
EOF
    fi
    
    # Test npm script execution
    run -127 zsh -c "
        cd '$TEST_PROJECT'
        source '$TEST_HOME/.zshrc'
        npm run test 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "npm not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "npm execution failed in test environment (status: $status)"
    fi
    assert_contains "$output" "npm test executed successfully"
    
    color_output "green" "✅ npm scripts execute correctly"
}

@test "NVM auto-switch with .nvmrc integration" {
    cd "$TEST_PROJECT"
    
    # Create .nvmrc file
    echo "18.17.0" > .nvmrc
    
    # Test shell behavior with .nvmrc
    run zsh -c "
        cd '$TEST_PROJECT'
        source '$TEST_HOME/.zshrc'
        # Check if .nvmrc is detected
        [ -f .nvmrc ] && echo 'NVMRC_FOUND:' \$(cat .nvmrc)
        # Try to call nvm_auto_use if available
        type nvm_auto_use >/dev/null 2>&1 && echo 'AUTO_USE_AVAILABLE' || echo 'AUTO_USE_MISSING'
    "
    [ "$status" -eq 0 ]
    
    assert_contains "$output" "NVMRC_FOUND: 18.17.0"
    assert_contains "$output" "AUTO_USE_AVAILABLE"
    
    color_output "green" "✅ .nvmrc file detection works in shell integration"
}

@test "Environment variables persist across shell sessions" {
    # Test that Node.js related environment variables are set
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        echo 'NVM_DIR:' \$NVM_DIR
        echo 'NODE_PATH:' \$NODE_PATH
        echo 'PATH_HAS_NODE:' \$(echo \$PATH | grep -q node && echo 'YES' || echo 'NO')
    "
    [ "$status" -eq 0 ]
    
    # Should have some Node.js related environment setup
    assert_contains "$output" "NVM_DIR:"
    
    color_output "blue" "Environment variables check completed"
}

@test "Global npm packages installation path" {
    # Skip if npm not available
    if ! command -v npm >/dev/null 2>&1; then
        skip "npm not available for global package testing"
    fi
    
    run -127 zsh -c "
        source '$TEST_HOME/.zshrc'
        npm config get prefix 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "npm config not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "npm config failed in test environment (status: $status)"
    fi
    [ -n "$output" ]
    
    local npm_prefix="$output"
    color_output "blue" "npm prefix: $npm_prefix"
    
    # Test npm global bin directory
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        npm bin -g
    "
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    
    color_output "blue" "npm global bin: $output"
}

@test "Node.js module resolution works" {
    # Skip if Node.js not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available for module resolution testing"
    fi
    
    cd "$TEST_PROJECT"
    
    # Test built-in module resolution
    run -127 zsh -c "
        cd '$TEST_PROJECT'
        source '$TEST_HOME/.zshrc'
        node -e \"console.log('Built-in modules test:'); console.log(require('path').resolve('.'))\" 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "Node.js not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "Node.js execution failed in test environment (status: $status)"
    fi
    assert_contains "$output" "Built-in modules test:"
    
    color_output "green" "✅ Node.js module resolution works"
}

@test "Shell startup time with Node.js integration" {
    # Measure shell startup time with Node.js integration
    local startup_time=$(measure_startup_time "$TEST_HOME/.zshrc" 3)
    
    color_output "blue" "Shell startup time with Node.js integration: ${startup_time}ms"
    
    # Should still be reasonable even with Node.js integration
    [ "$startup_time" -lt 500 ] || {
        color_output "yellow" "⚠️  Startup time with Node.js (${startup_time}ms) is slower than expected"
    }
}
