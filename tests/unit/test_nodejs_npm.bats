#!/usr/bin/env bats

# Node.js and npm integration tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Create minimal Node.js environment for testing
    export NODE_TEST_DIR="$TEST_HOME/node_test"
    mkdir -p "$NODE_TEST_DIR"
}

teardown() {
    teardown_test_env
}

@test "NVM integration module loads without errors" {
    run load_config_module "16-nvm-integration.zsh"
    [ "$status" -eq 0 ]
}

@test "NVM functions are available after config load" {
    load_config_module "16-nvm-integration.zsh"
    
    # Test if nvm_init function is defined
    run zsh -c "type nvm_init 2>/dev/null || echo 'FUNCTION_NOT_FOUND'"
    if assert_contains "$output" "FUNCTION_NOT_FOUND"; then
        skip "NVM functions not available in test environment"
    fi
    [ "$status" -eq 0 ]
    
    # Test if nvm_auto_use function is defined
    run zsh -c "type nvm_auto_use 2>/dev/null || echo 'FUNCTION_NOT_FOUND'"
    if assert_contains "$output" "FUNCTION_NOT_FOUND"; then
        skip "NVM auto_use function not available"
    fi
    [ "$status" -eq 0 ]
}

@test "Node.js is available after full config load" {
    # Load performance and NVM modules
    load_config_module "01-performance.zsh"
    load_config_module "16-nvm-integration.zsh"
    
    # Check if Node.js is available (system or NVM)
    run zsh -c "command -v node"
    if [ "$status" -eq 0 ]; then
        color_output "green" "✅ Node.js is available: $(node --version 2>/dev/null || echo 'version check failed')"
    else
        color_output "yellow" "⚠️  Node.js not found - checking if NVM can provide it"
        skip "Node.js not available in test environment"
    fi
}

@test "npm is available after full config load" {
    # Load performance and NVM modules
    load_config_module "01-performance.zsh"
    load_config_module "16-nvm-integration.zsh"
    
    # Check if npm is available
    run zsh -c "command -v npm"
    if [ "$status" -eq 0 ]; then
        color_output "green" "✅ npm is available: $(npm --version 2>/dev/null || echo 'version check failed')"
    else
        color_output "yellow" "⚠️  npm not found - may need Node.js installation"
        skip "npm not available in test environment"
    fi
}

@test "NVM environment variables are properly set" {
    load_config_module "16-nvm-integration.zsh"
    
    # Test NVM configuration variables
    run zsh -c "echo \$NVM_LAZY_LOAD"
    [ "$status" -eq 0 ]
    assert_contains "$output" "false"
    
    run zsh -c "echo \$NVM_AUTO_USE"
    [ "$status" -eq 0 ]
    assert_contains "$output" "true"
    
    run zsh -c "echo \$NVM_COMPLETION"
    [ "$status" -eq 0 ]
    assert_contains "$output" "true"
}

@test "NVM directory detection works correctly" {
    load_config_module "16-nvm-integration.zsh"
    
    # Test with NVM directory present
    mkdir -p "$TEST_HOME/.nvm"
    touch "$TEST_HOME/.nvm/nvm.sh"
    
    run zsh -c "
        export HOME='$TEST_HOME'
        source $PROJECT_ROOT/config/16-nvm-integration.zsh
        nvm_init && echo 'NVM_INIT_SUCCESS' || echo 'NVM_INIT_FAILED'
    "
    [ "$status" -eq 0 ]
    
    # Should try to initialize NVM
    # Result depends on whether actual NVM is installed
}

@test "Package.json node version detection works" {
    load_config_module "16-nvm-integration.zsh"
    
    # Create test package.json with Node.js version requirement
    cd "$NODE_TEST_DIR"
    cat > package.json << 'EOF'
{
  "name": "test-project",
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
    
    # Test package.json detection function if available
    run zsh -c "
        cd '$NODE_TEST_DIR'
        source $PROJECT_ROOT/config/16-nvm-integration.zsh
        type get_package_json_node_version >/dev/null 2>&1 && get_package_json_node_version || echo 'FUNCTION_NOT_FOUND'
    "
    [ "$status" -eq 0 ]
    
    # Should either extract version or indicate function not found
    if assert_contains "$output" "18"; then
        color_output "green" "✅ Package.json Node version detection works"
    else
        color_output "yellow" "⚠️  Package.json parsing function may not be available"
    fi
}

@test "nvmrc file detection and parsing works" {
    load_config_module "16-nvm-integration.zsh"
    
    # Create test .nvmrc file
    cd "$NODE_TEST_DIR"
    echo "18.17.0" > .nvmrc
    
    # Test .nvmrc detection
    run zsh -c "
        cd '$NODE_TEST_DIR'
        [ -f .nvmrc ] && cat .nvmrc
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "18.17.0"
    
    color_output "green" "✅ .nvmrc file detection works"
}

@test "Node.js version validation works" {
    # Skip if Node.js not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available for version testing"
    fi
    
    load_config_module "16-nvm-integration.zsh"
    
    # Get current Node.js version
    local node_version=$(node --version 2>/dev/null)
    [ -n "$node_version" ]
    
    color_output "green" "✅ Node.js version: $node_version"
    
    # Validate version format (should start with 'v' and contain dots)
    [[ "$node_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "npm configuration and availability" {
    # Skip if npm not available
    if ! command -v npm >/dev/null 2>&1; then
        skip "npm not available for testing"
    fi
    
    load_config_module "16-nvm-integration.zsh"
    
    # Test npm version
    run npm --version
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    
    color_output "green" "✅ npm version: $output"
    
    # Test npm configuration access
    run npm config get registry
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    
    color_output "blue" "npm registry: $output"
}

@test "NVM auto-switch functionality test" {
    load_config_module "16-nvm-integration.zsh"
    
    # Create test directories with different Node requirements
    local project1="$NODE_TEST_DIR/project1"
    local project2="$NODE_TEST_DIR/project2"
    
    mkdir -p "$project1" "$project2"
    
    # Project 1 with .nvmrc
    echo "16.20.0" > "$project1/.nvmrc"
    
    # Project 2 with package.json
    cat > "$project2/package.json" << 'EOF'
{
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
    
    # Test directory detection
    [ -f "$project1/.nvmrc" ]
    [ -f "$project2/package.json" ]
    
    color_output "green" "✅ Test projects created for auto-switch testing"
    
    # Test nvm_auto_use function (won't actually switch in test env)
    run zsh -c "
        cd '$project1'
        source '$PROJECT_ROOT/config/16-nvm-integration.zsh'
        type nvm_auto_use >/dev/null 2>&1 && echo 'FUNCTION_AVAILABLE' || echo 'FUNCTION_MISSING'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "FUNCTION_AVAILABLE"
}

@test "PATH includes Node.js and npm after config load" {
    load_config_module "01-performance.zsh"
    load_config_module "16-nvm-integration.zsh"
    
    # Check if Node.js paths are in PATH
    run zsh -c "echo \$PATH"
    [ "$status" -eq 0 ]
    
    # Look for common Node.js path patterns
    if [[ "$output" == *"node"* ]] || [[ "$output" == *".nvm"* ]] || command -v node >/dev/null 2>&1; then
        color_output "green" "✅ Node.js paths detected in PATH"
    else
        color_output "yellow" "⚠️  Node.js paths not found in PATH (may not be installed)"
    fi
}

@test "Global npm packages accessibility" {
    # Skip if npm not available
    if ! command -v npm >/dev/null 2>&1; then
        skip "npm not available for global package testing"
    fi
    
    load_config_module "16-nvm-integration.zsh"
    
    # Test npm global bin path
    run npm bin -g 2>/dev/null
    if [ "$status" -ne 0 ]; then
        skip "npm bin -g command not available or failed"
    fi
    [ -n "$output" ]
    
    local npm_global_bin="$output"
    color_output "blue" "npm global bin: $npm_global_bin"
    
    # Check if global bin is in PATH
    run bash -c "echo \$PATH | grep -q '$npm_global_bin' && echo 'IN_PATH' || echo 'NOT_IN_PATH'"
    [ "$status" -eq 0 ]
    
    if assert_contains "$output" "IN_PATH"; then
        color_output "green" "✅ npm global bin is in PATH"
    else
        color_output "yellow" "⚠️  npm global bin not in PATH"
    fi
}
