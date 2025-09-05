#!/bin/bash
# Enhanced backup script with robust gcloud preservation

# =============================================================================
# BACKUP MODULE
# =============================================================================

# Create a full backup of the user's current shell configuration and extract
# user-specific customizations to be re-injected later by setup_zshrc.
# - Backs up ~/.zshrc (timestamped) when present
# - Backs up ~/.zsh_local when present
# - Backs up existing installation directory (INSTALL_DIR) when present
# - Extracts user configs into "$BACKUP_DIR/user_configs.zsh"
backup_existing_config() {
    print_step "Creating backup of existing configuration..."

    # Ensure backup directory exists
    if [[ -z "${BACKUP_DIR:-}" ]]; then
        # Fallback for safety; common.sh should have exported this already
        BACKUP_DIR="$HOME/.config/zsh-ultra-backup"
        export BACKUP_DIR
    fi

    mkdir -p "$BACKUP_DIR" 2>/dev/null || {
        print_error "Failed to create backup directory: $BACKUP_DIR"
        return 1
    }

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    # Backup ~/.zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        local zshrc_backup="$BACKUP_DIR/zshrc.backup.$timestamp"
        cp "$HOME/.zshrc" "$zshrc_backup" 2>>"$LOG_FILE" || true
        print_success "Backed up existing .zshrc to: $zshrc_backup"

        # Extract user-specific configurations for re-injection
        local user_configs_file="$BACKUP_DIR/user_configs.zsh"
        if extract_user_configs "$HOME/.zshrc" "$user_configs_file"; then
            print_success "Extracted user configurations: $user_configs_file"
        else
            # Ensure file exists but empty for downstream logic
            : > "$user_configs_file"
            print_warning "No user configurations detected to preserve"
        fi
    else
        print_info ".zshrc not found — nothing to backup for ~/.zshrc"
        # Still ensure placeholder file exists for setup_zshrc logic
        : > "$BACKUP_DIR/user_configs.zsh"
    fi

    # Backup ~/.zsh_local if present
    if [[ -f "$HOME/.zsh_local" ]]; then
        local zsh_local_backup="$BACKUP_DIR/zsh_local.backup.$timestamp"
        cp "$HOME/.zsh_local" "$zsh_local_backup" 2>>"$LOG_FILE" || true
        print_success "Backed up ~/.zsh_local to: $zsh_local_backup"
    fi

    # Backup existing installation directory if present
    if [[ -n "${INSTALL_DIR:-}" ]] && [[ -d "$INSTALL_DIR" ]]; then
        local install_backup="$BACKUP_DIR/install.backup.$timestamp"
        mkdir -p "$install_backup" 2>/dev/null || true
        cp -r "$INSTALL_DIR" "$install_backup/" 2>>"$LOG_FILE" || true
        print_success "Backed up existing install dir to: $install_backup/$(basename "$INSTALL_DIR")"
    fi

    print_success "Backup completed"
}

# Check if a line contains user configuration
is_user_config() {
    local line="$1"
    
    # Skip empty lines and our own configuration
    [[ -z "$line" ]] && return 1
    [[ "$line" =~ ^#.*Modern.*ZSH.*Configuration ]] && return 1
    [[ "$line" =~ ^export.*ZSH_CONFIG_DIR ]] && return 1
    [[ "$line" =~ ^\[.*-r.*config_file ]] && return 1
    [[ "$line" =~ ^for.*config_file.*in ]] && return 1
    
    # Node.js/NVM configurations
    [[ "$line" =~ ^export.*NVM_DIR ]] && return 0
    [[ "$line" =~ ^\[.*-s.*nvm\.sh ]] && return 0
    [[ "$line" =~ ^\[.*-s.*bash_completion ]] && return 0
    
    # Google Cloud SDK configurations - enhanced patterns
    [[ "$line" =~ gcloud ]] && return 0
    [[ "$line" =~ google-cloud-sdk ]] && return 0
    [[ "$line" =~ ^source.*google-cloud ]] && return 0
    [[ "$line" =~ ^\..*google-cloud ]] && return 0
    [[ "$line" =~ path\.zsh\.inc ]] && return 0
    [[ "$line" =~ completion\.zsh\.inc ]] && return 0
    [[ "$line" =~ ^export.*GOOGLE_CLOUD ]] && return 0
    [[ "$line" =~ ^export.*GCLOUD ]] && return 0
    [[ "$line" =~ ^export.*GOOGLE_APPLICATION_CREDENTIALS ]] && return 0
    [[ "$line" =~ ^export.*CLOUDSDK ]] && return 0
    [[ "$line" =~ ^PATH.*gcloud ]] && return 0
    [[ "$line" =~ ^PATH.*google-cloud ]] && return 0
    [[ "$line" =~ ^alias.*gcloud ]] && return 0
    
    # Other development environments
    [[ "$line" =~ pyenv ]] && return 0
    [[ "$line" =~ rbenv ]] && return 0
    [[ "$line" =~ conda ]] && return 0
    [[ "$line" =~ anaconda ]] && return 0
    [[ "$line" =~ miniconda ]] && return 0
    [[ "$line" =~ ^export.*JAVA_HOME ]] && return 0
    [[ "$line" =~ ^export.*ANDROID ]] && return 0
    [[ "$line" =~ ^export.*FLUTTER ]] && return 0
    [[ "$line" =~ ^export.*DART ]] && return 0
    
    # Common shell customizations
    [[ "$line" =~ ^source.*\.bashrc ]] && return 0
    [[ "$line" =~ ^source.*\.profile ]] && return 0
    [[ "$line" =~ ^source.*\.bash_profile ]] && return 0
    [[ "$line" =~ ^alias ]] && return 0
    [[ "$line" =~ ^function ]] && return 0
    
    # User configuration comments
    [[ "$line" =~ ^#.*User ]] && return 0
    [[ "$line" =~ ^#.*Personal ]] && return 0
    [[ "$line" =~ ^#.*Custom ]] && return 0
    [[ "$line" =~ ^#.*My ]] && return 0
    [[ "$line" =~ ^#.*Added.by ]] && return 0
    [[ "$line" =~ ^#.*The.next.line ]] && return 0
    [[ "$line" =~ ^#.*This.line ]] && return 0
    [[ "$line" =~ ^#.*Enable ]] && return 0
    [[ "$line" =~ ^#.*Load ]] && return 0
    [[ "$line" =~ ^#.*Initialize ]] && return 0
    
    # PATH modifications (but not our own)
    if [[ "$line" =~ ^export.*PATH.*= ]] && [[ ! "$line" =~ ZSH_CONFIG_DIR ]]; then
        return 0
    fi
    
    return 1
}

# Extract user configurations
extract_user_configs() {
    local source_file="$1"
    local output_file="$2"
    
    [[ ! -f "$source_file" ]] && return 1
    
    local temp_file
    temp_file=$(mktemp)
    local found_configs=false
    local in_preserved_section=false
    
    while IFS= read -r line; do
        # Check for preserved section markers
        if [[ "$line" =~ ^#.*PRESERVED.*USER.*CONFIGURATIONS ]]; then
            in_preserved_section=true
            continue
        fi
        
        # End of preserved section
        if [[ "$in_preserved_section" == true ]] && [[ "$line" =~ ^#.*===.*=== ]]; then
            in_preserved_section=false
            continue
        fi
        
        # Include everything in preserved section
        if [[ "$in_preserved_section" == true ]]; then
            echo "$line" >> "$temp_file"
            found_configs=true
            continue
        fi
        
        # Check if line is user configuration
        if is_user_config "$line"; then
            echo "$line" >> "$temp_file"
            found_configs=true
        fi
    done < "$source_file"
    
    if [[ "$found_configs" == true ]]; then
        # Clean up empty lines and save
        sed '/^$/N;/^\n$/d' "$temp_file" > "$output_file"
        rm -f "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# (No standalone execution block)
