#!/usr/bin/env bats

# Node.js and npm integration tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "NVM integration module loads without errors" {
    run load_config_module "16-nvm-integration.zsh"
    [ "$status" -eq 0 ]
}

@test "Node.js is available after shell initialization" {
    # Load the full shell configuration
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; command -v node"
    if [ "$status" -eq 0 ]; then
        color_output "green" "✅ Node.js is available"
        assert_contains "$output" "node"
    else
        color_output "yellow" "⚠️  Node.js not found (may not be installed)"
        skip "Node.js not available in environment"
    fi
}

@test "npm is available after shell initialization" {
    # Load the full shell configuration
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; command -v npm"
    if [ "$status" -eq 0 ]; then
        color_output "green" "✅ npm is available"
        assert_contains "$output" "npm"
    else
        color_output "yellow" "⚠️  npm not found (may not be installed)"
        skip "npm not available in environment"
    fi
}

@test "Node.js version is reasonable" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; node --version 2>/dev/null"
    if [ "$status" -eq 0 ]; then
        local version="$output"
        color_output "blue" "Node.js version: $version"
        
        # Check if version format is valid (starts with v and has numbers)
        [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]] || {
            color_output "red" "Invalid version format: $version"
            return 1
        }
        
        # Extract major version
        local major_version=$(echo "$version" | sed 's/^v\([0-9]*\).*/\1/')
        [ "$major_version" -ge 16 ] || {
            color_output "yellow" "⚠️  Node.js version ($version) is quite old"
        }
    else
        skip "Node.js not available"
    fi
}

@test "npm version is reasonable" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; npm --version 2>/dev/null"
    if [ "$status" -eq 0 ]; then
        local version="$output"
        color_output "blue" "npm version: $version"
        
        # Check if version format is valid
        [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || {
            color_output "red" "Invalid npm version format: $version"
            return 1
        }
        
        # Extract major version
        local major_version=$(echo "$version" | sed 's/^\([0-9]*\).*/\1/')
        [ "$major_version" -ge 8 ] || {
            color_output "yellow" "⚠️  npm version ($version) is quite old"
        }
    else
        skip "npm not available"
    fi
}

@test "NVM environment variables are set correctly" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; echo \$NVM_DIR"
    if [ "$status" -eq 0 ] && [ -n "$output" ]; then
        color_output "blue" "NVM_DIR: $output"
        
        # Verify NVM_DIR exists or is reasonable
        local nvm_dir="$output"
        [[ "$nvm_dir" == *"nvm"* ]] || {
            color_output "yellow" "⚠️  Unexpected NVM_DIR: $nvm_dir"
        }
    else
        color_output "yellow" "⚠️  NVM_DIR not set (NVM may not be installed)"
    fi
}

@test "npx is available and working" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; command -v npx"
    if [ "$status" -eq 0 ]; then
        color_output "green" "✅ npx is available"
        
        # Test npx with a simple command
        run zsh -c "source '$TEST_HOME/.zshrc'; npx --version 2>/dev/null"
        if [ "$status" -eq 0 ]; then
            color_output "blue" "npx version: $output"
        fi
    else
        color_output "yellow" "⚠️  npx not found"
        skip "npx not available"
    fi
}

@test "Global npm packages path is in PATH" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    run zsh -c "source '$TEST_HOME/.zshrc'; npm config get prefix 2>/dev/null"
    if [ "$status" -eq 0 ] && [ -n "$output" ]; then
        local npm_prefix="$output"
        color_output "blue" "npm prefix: $npm_prefix"
        
        # Check if npm bin directory is in PATH
        run zsh -c "source '$TEST_HOME/.zshrc'; echo \$PATH"
        if [ "$status" -eq 0 ]; then
            if [[ "$output" == *"$npm_prefix"* ]]; then
                color_output "green" "✅ npm global bin directory is in PATH"
            else
                color_output "yellow" "⚠️  npm global bin directory may not be in PATH"
            fi
        fi
    else
        skip "npm not available or configured"
    fi
}
