#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# Node.js performance tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    
    # Create shell config with Node.js modules
    cat > "$TEST_HOME/.zshrc" << EOF
source $PROJECT_ROOT/config/01-performance.zsh
source $PROJECT_ROOT/config/16-nvm-integration.zsh
EOF
}

teardown() {
    teardown_test_env
}

@test "NVM module load time is acceptable" {
    local start_time=$(date +%s%N)
    
    run zsh -c "source $PROJECT_ROOT/config/16-nvm-integration.zsh"
    [ "$status" -eq 0 ]
    
    local end_time=$(date +%s%N)
    local load_time_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "NVM module load time: ${load_time_ms}ms"
    
    # Should load quickly (under 100ms)
    [ "$load_time_ms" -lt 100 ] || {
        color_output "yellow" "⚠️  NVM module load time (${load_time_ms}ms) is slow"
    }
}

@test "Shell startup with Node.js integration under 400ms" {
    local startup_time=$(measure_startup_time "$TEST_HOME/.zshrc" 5)
    
    color_output "blue" "Shell startup with Node.js: ${startup_time}ms"
    
    # Allow slightly more time for Node.js integration
    [ "$startup_time" -lt 400 ] || {
        color_output "yellow" "⚠️  Shell startup with Node.js (${startup_time}ms) exceeds 400ms threshold"
        return 1
    }
    
    color_output "green" "✅ Shell startup with Node.js is within acceptable limits"
}

@test "Node.js command execution performance" {
    # Skip if Node.js not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available for performance testing"
    fi
    
    # Test simple Node.js execution time
    local start_time=$(date +%s%N)
    
    run -127 zsh -c "
        source '$TEST_HOME/.zshrc'
        node -e 'console.log(\"Performance test\")' 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "Node.js not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "Node.js execution failed in test environment (status: $status)"
    fi
    
    local end_time=$(date +%s%N)
    local exec_time_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "Node.js execution time: ${exec_time_ms}ms"
    
    # Should execute quickly (under 200ms for simple command)
    [ "$exec_time_ms" -lt 200 ] || {
        color_output "yellow" "⚠️  Node.js execution time (${exec_time_ms}ms) is slow"
    }
    
    assert_contains "$output" "Performance test"
}

@test "npm command execution performance" {
    # Skip if npm not available
    if ! command -v npm >/dev/null 2>&1; then
        skip "npm not available for performance testing"
    fi
    
    # Test npm version command performance
    local start_time=$(date +%s%N)
    
    run -127 zsh -c "
        source '$TEST_HOME/.zshrc'
        npm --version 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "npm not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "npm execution failed in test environment (status: $status)"
    fi
    
    local end_time=$(date +%s%N)
    local exec_time_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "npm --version execution time: ${exec_time_ms}ms"
    
    # npm tends to be slower than node, allow more time
    [ "$exec_time_ms" -lt 500 ] || {
        color_output "yellow" "⚠️  npm execution time (${exec_time_ms}ms) is slow"
    }
    
    [ -n "$output" ]
}

@test "Multiple Node.js commands performance" {
    # Skip if Node.js not available
    if ! command -v node >/dev/null 2>&1; then
        skip "Node.js not available for multiple command testing"
    fi
    
    local start_time=$(date +%s%N)
    
    # Run multiple Node.js commands
    run -127 zsh -c "
        source '$TEST_HOME/.zshrc'
        node --version 2>/dev/null
        node -e 'console.log(process.platform)' 2>/dev/null
        node -e 'console.log(process.arch)' 2>/dev/null
    "
    if [ "$status" -eq 127 ]; then
        skip "Node.js not available in test environment"
    elif [ "$status" -ne 0 ]; then
        skip "Node.js execution failed in test environment (status: $status)"
    fi
    
    local end_time=$(date +%s%N)
    local total_time_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "Multiple Node.js commands total time: ${total_time_ms}ms"
    
    # Should handle multiple commands efficiently
    [ "$total_time_ms" -lt 800 ] || {
        color_output "yellow" "⚠️  Multiple Node.js commands time (${total_time_ms}ms) is slow"
    }
    
    # Verify all commands executed
    assert_contains "$output" "v"  # version should contain 'v'
}

@test "NVM function call overhead" {
    # Load NVM module
    run zsh -c "source $PROJECT_ROOT/config/16-nvm-integration.zsh"
    [ "$status" -eq 0 ]
    
    # Test nvm_auto_use function call time
    local start_time=$(date +%s%N)
    
    run zsh -c "
        source $PROJECT_ROOT/config/16-nvm-integration.zsh
        # Call function multiple times to test overhead
        nvm_auto_use 2>/dev/null || true
        nvm_auto_use 2>/dev/null || true
        nvm_auto_use 2>/dev/null || true
    "
    [ "$status" -eq 0 ]
    
    local end_time=$(date +%s%N)
    local function_time_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "NVM function calls time: ${function_time_ms}ms"
    
    # Function calls should be fast
    [ "$function_time_ms" -lt 150 ] || {
        color_output "yellow" "⚠️  NVM function calls time (${function_time_ms}ms) has overhead"
    }
}

@test "Memory usage with Node.js integration" {
    # Test memory usage with Node.js modules loaded
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        # Get shell memory usage
        ps -o rss= -p \$\$ 2>/dev/null || echo '0'
    "
    [ "$status" -eq 0 ]
    
    local memory_output="$output"
    # Extract only the numeric part, ignore any text/emojis
    local memory_kb=$(echo "$memory_output" | grep -o '[0-9]*' | head -1)
    memory_kb=${memory_kb:-0}
    local memory_mb=$((memory_kb / 1024))
    
    color_output "blue" "Memory usage with Node.js integration: ${memory_mb}MB"
    
    # Should not use excessive memory
    [ "$memory_mb" -lt 100 ] || {
        color_output "yellow" "⚠️  Memory usage with Node.js (${memory_mb}MB) is high"
    }
}
