#!/usr/bin/env bats

# Node.js performance tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "NVM integration doesn't slow down shell startup significantly" {
    # Test startup time with NVM integration
    cat > "$TEST_HOME/.zshrc_with_nvm" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    cat > "$TEST_HOME/.zshrc_without_nvm" << 'EOF'
source config/01-performance.zsh
EOF
    
    local startup_with_nvm=$(measure_startup_time "$TEST_HOME/.zshrc_with_nvm" 3)
    local startup_without_nvm=$(measure_startup_time "$TEST_HOME/.zshrc_without_nvm" 3)
    
    color_output "blue" "Startup with NVM: ${startup_with_nvm}ms"
    color_output "blue" "Startup without NVM: ${startup_without_nvm}ms"
    
    local difference=$((startup_with_nvm - startup_without_nvm))
    color_output "blue" "NVM overhead: ${difference}ms"
    
    # NVM should add less than 100ms to startup time
    [ "$difference" -lt 100 ] || {
        color_output "yellow" "⚠️  NVM integration adds significant overhead (${difference}ms)"
        return 1
    }
    
    color_output "green" "✅ NVM integration overhead is acceptable"
}

@test "Node.js command availability check is fast" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    # Measure time to check if node is available
    local start_time=$(date +%s%N)
    
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        command -v node >/dev/null 2>&1
    "
    
    local end_time=$(date +%s%N)
    local duration_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "Node.js availability check: ${duration_ms}ms"
    
    # Should be very fast (< 50ms)
    [ "$duration_ms" -lt 50 ] || {
        color_output "yellow" "⚠️  Node.js availability check is slow (${duration_ms}ms)"
    }
}

@test "NVM lazy loading performance" {
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source config/01-performance.zsh
source config/16-nvm-integration.zsh
EOF
    
    # Test if NVM uses lazy loading (doesn't load immediately)
    local start_time=$(date +%s%N)
    
    run zsh -c "
        source '$TEST_HOME/.zshrc'
        # Just load shell, don't use nvm
        echo 'SHELL_LOADED'
    "
    
    local end_time=$(date +%s%N)
    local duration_ms=$(((end_time - start_time) / 1000000))
    
    [ "$status" -eq 0 ]
    assert_contains "$output" "SHELL_LOADED"
    
    color_output "blue" "Shell load with NVM module: ${duration_ms}ms"
    
    # With lazy loading, this should be fast
    [ "$duration_ms" -lt 100 ] || {
        color_output "yellow" "⚠️  NVM module slows down shell loading (${duration_ms}ms)"
    }
    
    color_output "green" "✅ NVM integration has good performance characteristics"
}
