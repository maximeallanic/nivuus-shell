#!/bin/bash

# =============================================================================
# UPDATE MODULE
# =============================================================================

# Smart update that preserves user configurations
smart_update() {
    print_step "Starting smart update..."
    
    local temp_backup_dir
    temp_backup_dir=$(mktemp -d)
    local update_log="$HOME/.zsh_update.log"
    
    echo "Update started at $(date)" >> "$update_log"
    
    # Extract current user configurations before update
    if [[ -f ~/.zshrc ]]; then
        print_step "Preserving current user configurations..."
        extract_user_configs ~/.zshrc "$temp_backup_dir/current_user_configs.zsh"
        
        # Also preserve .zsh_local if it exists
        if [[ -f ~/.zsh_local ]]; then
            cp ~/.zsh_local "$temp_backup_dir/zsh_local.backup"
        fi
    fi
    
    # Backup current configuration
    print_step "Creating update backup..."
    local update_backup_dir
    update_backup_dir="$HOME/.config/zsh-ultra-update-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$update_backup_dir"
    
    if [[ -f ~/.zshrc ]]; then
        cp ~/.zshrc "$update_backup_dir/zshrc.pre-update"
    fi
    
    if [[ -d "$INSTALL_DIR" ]]; then
        cp -r "$INSTALL_DIR" "$update_backup_dir/config.pre-update"
    fi
    
    # Perform the update
    print_step "Updating configuration files..."
    
    # Update configuration files
    if [[ -d "$SCRIPT_DIR/config" ]]; then
        cp -r "$SCRIPT_DIR/config" "$INSTALL_DIR/"
        print_success "Updated configuration modules"
    fi
    
    # Regenerate .zshrc with preserved configurations
    print_step "Regenerating .zshrc with preserved configurations..."
    
    local new_zshrc_content
    new_zshrc_content="# Modern ZSH Configuration (Updated: $(date))
# Configuration directory
export ZSH_CONFIG_DIR=\"$INSTALL_DIR\"

# Load all configuration modules
if [[ -d \"\$ZSH_CONFIG_DIR/config\" ]]; then
    for config_file in \"\$ZSH_CONFIG_DIR\"/config/*.zsh; do
        [[ -r \"\$config_file\" ]] && source \"\$config_file\"
    done
fi

# Load local customizations if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local"
    
    # Write new configuration
    echo "$new_zshrc_content" > ~/.zshrc
    
    # Restore preserved user configurations
    if [[ -f "$temp_backup_dir/current_user_configs.zsh" ]] && [[ -s "$temp_backup_dir/current_user_configs.zsh" ]]; then
        print_step "Restoring preserved user configurations..."
        echo "" >> ~/.zshrc
        echo "# =============================================================================" >> ~/.zshrc
        echo "# PRESERVED USER CONFIGURATIONS" >> ~/.zshrc
        echo "# =============================================================================" >> ~/.zshrc
        echo "" >> ~/.zshrc
        cat "$temp_backup_dir/current_user_configs.zsh" >> ~/.zshrc
        print_success "Restored preserved user configurations"
    fi
    
    # Restore .zsh_local if it was backed up
    if [[ -f "$temp_backup_dir/zsh_local.backup" ]]; then
        cp "$temp_backup_dir/zsh_local.backup" ~/.zsh_local
        print_success "Restored .zsh_local"
    fi
    
    # Clean up temporary backup
    rm -rf "$temp_backup_dir"
    
    # Log successful update
    echo "Update completed successfully at $(date)" >> "$update_log"
    echo "Backup created at: $update_backup_dir" >> "$update_log"
    
    print_success "Smart update completed!"
    print_step "Update backup saved to: $update_backup_dir"
    
    # Verify the update
    # shellcheck disable=SC1090
    if source ~/.zshrc 2>/dev/null; then
        print_success "Configuration validated successfully"
    else
        print_error "Configuration validation failed - check ~/.zshrc"
        print_warning "Restore from backup: $update_backup_dir/zshrc.pre-update"
    fi
}

# Check if update is needed
check_update_needed() {
    local version_file="$INSTALL_DIR/.version"
    local current_version=""
    
    if [[ -f "$version_file" ]]; then
        current_version=$(cat "$version_file")
    fi
    
    if [[ "$current_version" != "$VERSION" ]]; then
        return 0  # Update needed
    else
        return 1  # No update needed
    fi
}

# Update version tracking
update_version_info() {
    echo "$VERSION" > "$INSTALL_DIR/.version"
    echo "$(date)" > "$INSTALL_DIR/.last_update"
}
