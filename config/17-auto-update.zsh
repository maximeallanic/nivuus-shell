#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# AUTO-UPDATE SYSTEM WITH CONFIGURATION PRESERVATION
# =============================================================================

# Smart auto-update with configuration preservation
smart_auto_update() {
    local update_check_file="$HOME/.zsh_last_update_check"
    local current_time=$(date +%s)
    local config_dir="${ZSH_CONFIG_DIR:-$HOME/.config/zsh-ultra}"
    
    # Check once per week (604800 seconds)
    if [[ -f "$update_check_file" ]]; then
        local last_check=$(cat "$update_check_file")
        local time_diff=$((current_time - last_check))
        
        if (( time_diff < 604800 )); then
            return 0
        fi
    fi
    
    echo "$current_time" > "$update_check_file"
    
    # Synchronous check for updates (disabled for performance)
    # Auto-update functionality disabled to prevent async operations
    return 0
}

# User-friendly update command with configuration preservation
zsh_update() {
    local config_dir="${ZSH_CONFIG_DIR:-$HOME/.config/zsh-ultra}"
    
    if [[ ! -d "$config_dir" ]]; then
        echo "Error: Configuration directory not found: $config_dir"
        return 1
    fi
    
    echo "Starting smart update with configuration preservation..."
    
    # Create backup before update
    local backup_dir="$HOME/.config/zsh-update-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup current .zshrc
    if [[ -f ~/.zshrc ]]; then
        cp ~/.zshrc "$backup_dir/zshrc.backup"
        echo "Backed up current .zshrc"
    fi
    
    # Extract user configurations
    local user_configs_file="$backup_dir/user_configs.zsh"
    if [[ -f ~/.zshrc ]]; then
        extract_user_configs_inline ~/.zshrc "$user_configs_file"
    fi
    
    # Perform git update
    echo "Fetching latest updates..."
    cd "$config_dir" || return 1
    
    if git pull origin main --quiet; then
        echo "Updated configuration files"
    else
        echo "Failed to update - check network connection"
        return 1
    fi
    
    # Regenerate .zshrc with preserved configurations
    echo "Regenerating .zshrc with preserved configurations..."
    
    local zshrc_content="# Modern ZSH Configuration (Updated: $(date))
# Configuration directory
export ZSH_CONFIG_DIR=\"$config_dir\"

# Load all configuration modules
if [[ -d \"\$ZSH_CONFIG_DIR/config\" ]]; then
    for config_file in \"\$ZSH_CONFIG_DIR\"/config/*.zsh; do
        [[ -r \"\$config_file\" ]] && source \"\$config_file\"
    done
fi

# Load local customizations if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local"
    
    echo "$zshrc_content" > ~/.zshrc
    
    # Restore user configurations
    if [[ -f "$user_configs_file" ]] && [[ -s "$user_configs_file" ]]; then
        echo "" >> ~/.zshrc
        echo "# =============================================================================" >> ~/.zshrc
        echo "# PRESERVED USER CONFIGURATIONS" >> ~/.zshrc
        echo "# =============================================================================" >> ~/.zshrc
        echo "" >> ~/.zshrc
        cat "$user_configs_file" >> ~/.zshrc
        echo "Preserved user configurations"
    fi
    
    # Clean notification
    rm -f "$HOME/.zsh_update_available"
    
    echo ""
    echo "Update completed successfully!"
    echo "Backup saved to: $backup_dir"
    echo "Restart your terminal or run 'exec zsh' to apply changes"
}

# Inline version of extract_user_configs for auto-update
extract_user_configs_inline() {
    local zshrc_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$zshrc_file" ]]; then
        return 0
    fi
    
    local temp_file=$(mktemp)
    local found_configs=false
    
    # Extract user configurations
    while IFS= read -r line; do
        # Skip our configuration blocks
        if [[ "$line" =~ ^#.*Modern.*ZSH.*Configuration ]] || \
           [[ "$line" =~ ^export.*ZSH_CONFIG_DIR ]] || \
           [[ "$line" =~ ^\[.*-r.*config_file ]] || \
           [[ "$line" =~ ^for.*config_file.*in ]]; then
            continue
        fi
        
        # Preserve important user configurations
        local should_preserve=false
        
        # Check for various patterns that should be preserved
        case "$line" in
            *export*NVM_DIR*|*nvm.sh*|*bash_completion*|*gcloud*|*google-cloud-sdk*|*pyenv*|*rbenv*|*conda*|*anaconda*|*miniconda*)
                should_preserve=true ;;
            *export*JAVA_HOME*|*export*ANDROID*|*export*FLUTTER*|*export*DART*|*source*.bashrc*|*source*.profile*|*source*.bash_profile*)
                should_preserve=true ;;
            "#"*User*|"#"*Personal*|"#"*Custom*|"#"*My*|"#"*Added\ by*|"#"*The\ next\ line*|"#"*This\ line*|"#"*Enable*|"#"*Load*|"#"*Initialize*)
                should_preserve=true ;;
            *PRESERVED*USER*CONFIGURATIONS*)
                should_preserve=true ;;
        esac
        
        if [[ "$should_preserve" == "true" ]]; then
            echo "$line" >> "$temp_file"
            found_configs=true
        fi
    done < "$zshrc_file"
    
    if [[ "$found_configs" == true ]]; then
        mv "$temp_file" "$output_file"
    else
        rm -f "$temp_file"
    fi
}

# Manual update command for more control
zsh_manual_update() {
    echo "Manual update mode"
    echo "This will show you what changes before applying them."
    
    local config_dir="${ZSH_CONFIG_DIR:-$HOME/.config/zsh-ultra}"
    
    if [[ ! -d "$config_dir/.git" ]]; then
        echo "Error: Not a git repository: $config_dir"
        return 1
    fi
    
    cd "$config_dir" || return 1
    
    echo ""
    echo "Current status:"
    git status --short
    
    echo ""
    echo "Available updates:"
    git fetch origin main --quiet
    git log --oneline HEAD..origin/main
    
    echo ""
    read -p "Apply these updates? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        zsh_update
    else
        echo "Update cancelled"
    fi
}

# Show update notification if available
show_update_notification() {
    local notification_file="$HOME/.zsh_update_available"
    if [[ -f "$notification_file" ]]; then
        echo ""
        echo "Update notification:"
        cat "$notification_file"
        echo ""
    fi
}

# Auto-update disabled (no background processes)
# (smart_auto_update &) 2>/dev/null

# Show notification on startup if available
show_update_notification
