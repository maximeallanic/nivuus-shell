# =============================================================================
# NIVUUS SHELL - AUTO UPDATE INTEGRATION
# =============================================================================

# Auto-update configuration
readonly NIVUUS_UPDATE_SCRIPT="$NIVUUS_ROOT/scripts/update.sh"
readonly NIVUUS_UPDATE_CHECK_INTERVAL=86400  # 24 hours

# Function to check for updates
nivuus-update() {
    if [[ -x "$NIVUUS_UPDATE_SCRIPT" ]]; then
        "$NIVUUS_UPDATE_SCRIPT" "$@"
    else
        echo "❌ Update script not found. Please reinstall Nivuus Shell."
        return 1
    fi
}

# Function to check for updates silently (for background checks)
_nivuus_check_updates_silent() {
    if [[ -x "$NIVUUS_UPDATE_SCRIPT" ]]; then
        "$NIVUUS_UPDATE_SCRIPT" --silent
    fi
}

# Function to check if we should prompt for updates
_nivuus_should_check_updates() {
    local check_file="$HOME/.config/nivuus-shell/.last-update-check"
    local current_time=$(date +%s)
    local last_check_time
    
    if [[ ! -f "$check_file" ]]; then
        return 0  # Should check
    fi
    
    last_check_time=$(cat "$check_file" 2>/dev/null || echo "0")
    
    if (( current_time - last_check_time > NIVUUS_UPDATE_CHECK_INTERVAL )); then
        return 0  # Should check
    else
        return 1  # Too soon
    fi
}

# Auto-check for updates on shell startup (asynchronous)
if [[ "${NIVUUS_AUTO_UPDATE_CHECK:-true}" == "true" ]] && _nivuus_should_check_updates; then
    # Run update check in background, completely silent
    {
        setopt LOCAL_OPTIONS NO_MONITOR
        (
            # Small delay to not interfere with shell startup
            sleep 2
            _nivuus_check_updates_silent
        ) &>/dev/null &
    }
fi

# Aliases
alias nvs-update='nivuus-update'
alias nvs-check='nivuus-update --check'
