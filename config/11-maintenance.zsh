#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# MAINTENANCE & CLEANUP FUNCTIONS
# =============================================================================

# Smart maintenance (runs automatically)
smart_maintenance() {
    local maintenance_marker="$HOME/.zsh_last_maintenance"
    local current_time=$(date +%s)
    
    # Check if maintenance was run in the last 7 days
    if [[ -f $maintenance_marker ]]; then
        local last_maintenance=$(cat "$maintenance_marker")
        local days_since=$(( (current_time - last_maintenance) / 86400 ))
        
        if (( days_since < 7 )); then
            return
        fi
    fi
    
    echo "$current_time" > "$maintenance_marker"
    
    # Clean history duplicates
    if [[ -f ~/.zsh_history ]] && (( $(wc -l < ~/.zsh_history) > 10000 )); then
        local original_size=$(wc -l < ~/.zsh_history)
        
        # Remove duplicates while preserving order
        awk '!seen[$0]++' ~/.zsh_history > ~/.zsh_history.tmp
        mv ~/.zsh_history.tmp ~/.zsh_history
        
        local new_size=$(wc -l < ~/.zsh_history)
        local removed=$((original_size - new_size))
        
        if (( removed > 0 )); then
            # Silent removal - no echo for startup performance
            true
        fi
    fi
    
    # Clean temporary files safely
    find /tmp -maxdepth 1 -name '.firebase_cache_*' -type f -delete 2>/dev/null || true
    [ -d "${XDG_RUNTIME_DIR:-/tmp}/firebase_cache_$USER" ] && rm -rf "${XDG_RUNTIME_DIR:-/tmp}/firebase_cache_$USER" 2>/dev/null || true
    find /tmp -maxdepth 1 -name '.env_backup_*' -type f -delete 2>/dev/null || true
    
    # Rebuild completion if old - only in zsh
    if [[ -n "$ZSH_VERSION" && -f ~/.zcompdump ]]; then
        local dump_age=$(( current_time - $(stat -c %Y ~/.zcompdump 2>/dev/null || echo 0) ))
        if (( dump_age > 604800 )); then  # 1 week
            autoload -U compinit
            compinit -d ~/.zcompdump
        fi
    fi
}

# Manual cleanup function
zsh_cleanup() {
    echo "🧹 ZSH Configuration Cleanup"
    echo "============================"
    
    # Clean history duplicates
    echo "📚 Cleaning history..."
    if [[ -f ~/.zsh_history ]]; then
        local original_size=$(wc -l < ~/.zsh_history)
        
        # Remove duplicates while preserving order
        awk '!seen[$0]++' ~/.zsh_history > ~/.zsh_history.tmp
        mv ~/.zsh_history.tmp ~/.zsh_history
        
        local new_size=$(wc -l < ~/.zsh_history)
        local removed=$((original_size - new_size))
        
        if (( removed > 0 )); then
            # Silent removal - logged for manual cleanup only
            true
        else
            # Silent - no duplicates found
            true
        fi
    fi
    
    # Clean temporary files
    echo "🧽 Cleaning temporary files..."
    rm -f /tmp/.firebase_cache_* 2>/dev/null
    rm -rf "${XDG_RUNTIME_DIR:-/tmp}/firebase_cache_$USER" 2>/dev/null
    rm -f /tmp/.env_backup_* 2>/dev/null
    echo "✅ Temporary files cleaned"
    
    # Rebuild completion - only in zsh
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "🔄 Rebuilding completions..."
        autoload -U compinit
        compinit -d ~/.zcompdump
        echo "✅ Completions rebuilt"
    fi
    
    echo ""
    echo "🎉 Cleanup complete!"
}

# Auto-update checker (runs once per day)
check_updates() {
    local update_check_file="$HOME/.zsh_last_update_check"
    local current_time=$(date +%s)
    
    if [[ -f $update_check_file ]]; then
        local last_check=$(cat "$update_check_file")
        local time_diff=$((current_time - last_check))
        
        # Check once per day (86400 seconds)
        if (( time_diff < 86400 )); then
            return
        fi
    fi
    
    echo "$current_time" > "$update_check_file"
    
    # Check for system updates (synchronous)
    if command -v apt >/dev/null 2>&1; then
        apt list --upgradable 2>/dev/null | wc -l > /tmp/.zsh_updates_count
    fi
}

# Maintenance checks disabled (no auto-run)
# (check_updates &)
# (smart_maintenance &)