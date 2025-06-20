# =============================================================================
# SECURE ENVIRONMENT MANAGEMENT
# =============================================================================

# PATH is already fixed in 00-vscode-integration.zsh
# Just ensure additional paths are available

# Add common Linux binary directories if they exist
[[ -d "/usr/local/sbin" ]] && export PATH="/usr/local/sbin:$PATH"

# Global environment validation settings
export ENV_VALIDATION_SILENT=true  # Set to false to see validation messages

# Whitelist of safe environment variables
SAFE_ENV_VARS=(
    "NODE_ENV" "ENVIRONMENT" "NODE_OPTIONS"
    "API_URL" "API_KEY" "DATABASE_URL"
    "PORT" "HOST" "DEBUG"
    "REACT_APP_" "NEXT_PUBLIC_" "VITE_"
    "FIREBASE_" "GOOGLE_" "AWS_"
    "DOCKER_" "COMPOSE_"
    "OPENAI_" "USE_" "WHATSAPP_" "DISCORD_"
    "AUTHORIZED_" "TOKEN" "BOT_"
    "FACEBOOK_" "LINKEDIN_" "ANDROID_" "OPENSSL_" "CPPFLAGS"
)

# Secure .env file validation
validate_env_file() {
    local env_file="$1"
    local silent_mode="${2:-$ENV_VALIDATION_SILENT}"  # Use global setting by default
    local line_num=0
    local issues=0
    
    while IFS= read -r line; do
        ((line_num++))
        
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z ${line// } ]] && continue
        
        # Check format (only report critical syntax errors)
        if [[ ! $line =~ ^[A-Z_][A-Z0-9_]*=.*$ ]]; then
            [[ $silent_mode != "true" ]] && echo "⚠️  Line $line_num: Invalid format - $line"
            ((issues++))
            continue
        fi
        
        # Skip security warnings in silent mode
        if [[ $silent_mode != "true" ]]; then
            # Extract variable name
            local var_name=${line%%=*}
            
            # Check if variable is in whitelist
            local is_safe=false
            for safe_pattern in "${SAFE_ENV_VARS[@]}"; do
                if [[ $var_name == $safe_pattern* ]]; then
                    is_safe=true
                    break
                fi
            done
            
            if [[ $is_safe == false ]]; then
                echo "🔒 Line $line_num: Potentially unsafe variable - $var_name"
            fi
        fi
        
    done < "$env_file"
    
    if [[ $issues -gt 0 ]]; then
        [[ $silent_mode != "true" ]] && echo "❌ Found $issues formatting issues in $env_file"
        return 1
    fi
    
    return 0
}

# Enhanced .env loading with backup (silent by default)
load_env() {
    local env_file="${1:-.env}"
    local silent="${2:-true}"  # Silent by default
    
    if [[ ! -f $env_file ]]; then
        return 0
    fi
    
    if [[ ! -r $env_file ]]; then
        [[ $silent != "true" ]] && echo "⚠️  Cannot read $env_file (permission denied)"
        return 1
    fi
    
    # Silent validation always
    if ! validate_env_file "$env_file" true 2>/dev/null; then
        # Silent validation failed - skip loading
        return 1
    fi
    
    # Create backup of current environment
    local backup_file="/tmp/.env_backup_$$"
    env | grep -E "^($(IFS='|'; echo "${SAFE_ENV_VARS[*]}"))" > "$backup_file" 2>/dev/null
    
    # Silent loading
    set -o allexport
    source "$env_file" 2>/dev/null
    set +o allexport
    
    # Store backup location
    export _ENV_BACKUP_FILE="$backup_file"
}

# Smart env unloading
unload_env() {
    if [[ -n "$_PREV_ENV_FILE" && -f "$_PREV_ENV_FILE" ]]; then
        # Silent unloading for better performance
        
        while IFS= read -r line; do
            if [[ $line == *"="* && ! $line == "#"* ]]; then
                local var_name=${line%%=*}
                unset "$var_name"
            fi
        done < "$_PREV_ENV_FILE"
        
        unset _PREV_ENV_FILE
        # Silent unload - use 'envshow' to check current state
    fi
}

# Enhanced auto-env with security (silent mode)
auto_env() {
    # Track current directory to avoid unnecessary operations
    local current_dir="$(pwd)"
    
    # Check if directory actually changed
    if [[ -n "$_NIVUUS_LAST_ENV_PWD" && "$current_dir" == "$_NIVUUS_LAST_ENV_PWD" ]]; then
        return 0  # Same directory, do nothing
    fi
    
    # Update last directory
    export _NIVUUS_LAST_ENV_PWD="$current_dir"
    
    # Unload previous environment
    unload_env
    
    # Load new .env if it exists (completely silent)
    if [[ -f .env && -r .env ]]; then
        export _PREV_ENV_FILE="$(pwd)/.env"
        load_env .env >/dev/null 2>&1
    fi
}

# Manual environment management commands
envload() {
    local env_file="${1:-.env}"
    echo "🔍 Validating $env_file..."
    if ! validate_env_file "$env_file" false; then  # Force verbose for manual loading
        echo "❌ Validation failed. Load anyway? (y/N)"
        read -r response
        [[ $response != [yY] ]] && return 1
    fi
    load_env "$env_file" false  # Force verbose for manual loading
}

envcheck() {
    local env_file="${1:-.env}"
    echo "🔍 Validating $env_file..."
    validate_env_file "$env_file" false  # Force verbose for manual checking
}

envunload() {
    unload_env
}

envshow() {
    echo "🌍 Current Environment Variables"
    echo "==============================="
    for pattern in "${SAFE_ENV_VARS[@]}"; do
        env | grep -E "^${pattern}" | sort
    done
}

# Hook to run on directory change - only in zsh
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd auto_env
fi

# Initialize directory tracking and load .env on shell start if present
export _NIVUUS_LAST_ENV_PWD=""
auto_env

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Editor
export EDITOR='vim'
export VISUAL='vim'

# Language
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Less configuration
export LESS='-R'
export LESSHISTFILE='-'

# =============================================================================
# CONDA INITIALIZATION (OPTIMIZED)
# =============================================================================

# Conda setup (lazy loading for performance - without prompt modification)
if [[ -f "/usr/local/miniforge3/bin/conda" ]]; then
    __conda_setup="$('/usr/local/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
        # Disable conda prompt modification
        conda config --set changeps1 False 2>/dev/null
    else
        if [ -f "/usr/local/miniforge3/etc/profile.d/conda.sh" ]; then
            . "/usr/local/miniforge3/etc/profile.d/conda.sh"
            conda config --set changeps1 False 2>/dev/null
        else
            export PATH="/usr/local/miniforge3/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi

# =============================================================================
# NODE.JS & NVM SETUP
# =============================================================================

# NOTE: NVM configuration is handled in 16-nvm-integration.zsh
# This section is kept for backward compatibility and environment setup

# Ensure Node.js tools are in PATH if NVM is loaded
# if command -v node &> /dev/null; then
#     # Add global npm bin to PATH
#     export PATH="$(npm bin -g 2>/dev/null):$PATH" 2>/dev/null || true
# fi
