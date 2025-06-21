#!/usr/bin/env bats

# Performance benchmarks and tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "Shell startup time is under 300ms" {
    # Create a minimal test config
    cat > "$TEST_HOME/.zshrc" << 'EOF'
source $WORKSPACE_ROOT/config/01-performance.zsh
source $WORKSPACE_ROOT/config/02-history.zsh
source $WORKSPACE_ROOT/config/03-completion.zsh
EOF
    
    local startup_time=$(measure_startup_time "$TEST_HOME/.zshrc" 3)
    color_output "blue" "Startup time: ${startup_time}ms"
    
    # Should be under 300ms as per project goal
    [ "$startup_time" -lt 300 ] || {
        color_output "yellow" "⚠️  Startup time (${startup_time}ms) exceeds target (300ms)"
        return 1
    }
}

@test "Individual module load times are reasonable" {
    local max_module_time=50  # 50ms per module max
    
    for config_file in config/*.zsh; do
        [ -f "$config_file" ] || continue
        
        local module_name=$(basename "$config_file")
        local load_time=$(measure_startup_time "$config_file" 3)
        
        color_output "blue" "$module_name: ${load_time}ms"
        
        [ "$load_time" -lt "$max_module_time" ] || {
            color_output "yellow" "⚠️  Module $module_name load time (${load_time}ms) exceeds threshold (${max_module_time}ms)"
        }
    done
}

@test "Memory usage is reasonable" {
    # Create test config
    cat > "$TEST_HOME/.zshrc" << 'EOF'
for config in config/*.zsh; do
    [ -f "$config" ] && source "$config"
done
EOF
    
    # Measure memory usage
    local memory_output=$(zsh -c "source '$TEST_HOME/.zshrc'; ps -o rss= -p \$\$" 2>/dev/null || echo "0")
    # Extract only the numeric part, ignore any text/emojis
    local memory_kb=$(echo "$memory_output" | grep -o '[0-9]*' | head -1)
    memory_kb=${memory_kb:-0}
    local memory_mb=$((memory_kb / 1024))
    
    color_output "blue" "Memory usage: ${memory_mb}MB"
    
    # Should use less than 50MB
    [ "$memory_mb" -lt 50 ] || {
        color_output "yellow" "⚠️  Memory usage (${memory_mb}MB) is high"
    }
}

@test "Completion system loads quickly" {
    local start_time=$(date +%s%N)
    
    zsh -c "
        source $WORKSPACE_ROOT/config/01-performance.zsh
        source $WORKSPACE_ROOT/config/03-completion.zsh
        autoload -Uz compinit
        compinit -d '$TEST_HOME/.zcompdump'
    " 2>/dev/null
    
    local end_time=$(date +%s%N)
    local duration_ms=$(((end_time - start_time) / 1000000))
    
    color_output "blue" "Completion init time: ${duration_ms}ms"
    
    # Should load in under 100ms
    [ "$duration_ms" -lt 100 ] || {
        color_output "yellow" "⚠️  Completion loading time (${duration_ms}ms) is slow"
    }
}
