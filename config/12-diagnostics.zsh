# =============================================================================
# HEALTH CHECK & DIAGNOSTICS
# =============================================================================

# ZSH health check function
zsh_health_check() {
    echo "🏥 ZSH Configuration Health Check"
    echo "================================="
    
    local issues=0
    
    # Check startup time
    echo "⏱️  Startup Performance:"
    local start_time=$(date +%s%N)
    zsh -i -c exit 2>/dev/null
    local end_time=$(date +%s%N)
    local startup_ms=$(( (end_time - start_time) / 1000000 ))
    
    if (( startup_ms < 500 )); then
        echo "   ✅ Excellent ($startup_ms ms)"
    elif (( startup_ms < 1000 )); then
        echo "   ⚠️  Good ($startup_ms ms)"
    else
        echo "   ❌ Slow ($startup_ms ms)"
        ((issues++))
    fi
    
    # Check completion dump
    echo ""
    echo "📝 Completion System:"
    if [[ -f ~/.zcompdump ]]; then
        local dump_age=$(( $(date +%s) - $(stat -c %Y ~/.zcompdump) ))
        if (( dump_age > 86400 )); then
            echo "   ⚠️  Completion dump is old ($(( dump_age / 86400 )) days)"
        else
            echo "   ✅ Completion dump is fresh"
        fi
    else
        echo "   ❌ No completion dump found"
        ((issues++))
    fi
    
    # Check history
    echo ""
    echo "📚 History:"
    if [[ -f ~/.zsh_history ]]; then
        local hist_lines=$(wc -l < ~/.zsh_history)
        echo "   📊 $hist_lines commands in history"
        if (( hist_lines > 50000 )); then
            echo "   ⚠️  History file is large, consider cleanup"
        else
            echo "   ✅ History size is reasonable"
        fi
    else
        echo "   ❌ No history file found"
        ((issues++))
    fi
    
    # Check plugins
    echo ""
    echo "🔌 Plugins:"
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    if [[ -d "$plugin_dir/zsh-syntax-highlighting" ]]; then
        echo "   ✅ Syntax highlighting installed"
    else
        echo "   ❌ Syntax highlighting missing"
        ((issues++))
    fi
    
    if [[ -d "$plugin_dir/zsh-autosuggestions" ]]; then
        echo "   ✅ Auto-suggestions installed"
    else
        echo "   ❌ Auto-suggestions missing"
        ((issues++))
    fi
    
    # Check modern tools
    echo ""
    echo "🛠️  Modern CLI Tools:"
    local tools=("eza" "bat" "fd" "rg" "gh")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "   ✅ $tool available"
        else
            echo "   ⚠️  $tool not installed"
        fi
    done
    
    # Summary
    echo ""
    echo "📋 Summary:"
    if (( issues == 0 )); then
        echo "   🎉 Configuration is healthy!"
    else
        echo "   ⚠️  Found $issues issues to address"
    fi
    
    return $issues
}

# Performance benchmark
zsh_benchmark() {
    echo "🏃 ZSH Performance Benchmark"
    echo "============================"
    
    echo "🚀 Testing startup time (10 runs)..."
    local total_time=0
    
    for i in {1..10}; do
        local start_time=$(date +%s%N)
        zsh -i -c exit 2>/dev/null
        local end_time=$(date +%s%N)
        local run_time=$(( (end_time - start_time) / 1000000 ))
        
        echo "   Run $i: ${run_time}ms"
        total_time=$((total_time + run_time))
    done
    
    local avg_time=$((total_time / 10))
    echo ""
    echo "📊 Average startup time: ${avg_time}ms"
    
    if (( avg_time < 300 )); then
        echo "🚀 Lightning fast!"
    elif (( avg_time < 500 )); then
        echo "⚡ Very fast!"
    elif (( avg_time < 1000 )); then
        echo "👍 Good performance"
    else
        echo "⚠️  Could be optimized"
    fi
    
    # Completion test
    echo ""
    echo "🔄 Testing completion speed..."
    local comp_start=$(date +%s%N)
    compinit -d ~/.zcompdump 2>/dev/null
    local comp_end=$(date +%s%N)
    local comp_time=$(( (comp_end - comp_start) / 1000000 ))
    echo "📝 Completion initialization: ${comp_time}ms"
}

# System information
zsh_info() {
    echo "ℹ️  ZSH Configuration Information"
    echo "================================"
    echo "ZSH Version: $ZSH_VERSION"
    echo "Config Location: ~/.config/zsh-ultra"
    echo "Modules Loaded: $(ls ~/.config/zsh-ultra/config/*.zsh 2>/dev/null | wc -l)"
    echo "Shell: $SHELL"
    echo "Terminal: $TERM"
    echo "OS: $(uname -s) $(uname -r)"
    
    if [[ -f ~/.zsh_history ]]; then
        echo "History Entries: $(wc -l < ~/.zsh_history)"
    fi
    
    echo ""
    echo "📦 Available Tools:"
    local tools=("eza" "bat" "fd" "rg" "gh" "jq" "fzf")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=$(${tool} --version 2>/dev/null | head -1 || echo "unknown")
            echo "   ✅ $tool ($version)"
        fi
    done
}
