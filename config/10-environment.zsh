# =============================================================================
# SECURE ENVIRONMENT MANAGEMENT
# =============================================================================

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
)

# Secure .env file validation
validate_env_file() {
    local env_file="$1"
    local silent_mode="${2:-true}"  # Silent by default
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
        
        # Skip security warnings in silent mode (startup performance)
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

# Enhanced .env loading with backup
load_env() {
    local env_file="${1:-.env}"
    
    if [[ ! -f $env_file ]]; then
        return 0
    fi
    
    if [[ ! -r $env_file ]]; then
        echo "⚠️  Cannot read $env_file (permission denied)"
        return 1
    fi
    
    # Silent validation for startup performance
    if ! validate_env_file "$env_file" 2>/dev/null; then
        # Silent validation failed - skip loading for startup performance
        return 1
    fi
    
    # Create backup of current environment
    local backup_file="/tmp/.env_backup_$$"
    env | grep -E "^($(IFS='|'; echo "${SAFE_ENV_VARS[*]}"))" > "$backup_file" 2>/dev/null
    
    # Silent loading for better startup performance
    set -o allexport
    source "$env_file"
    set +o allexport
    
    # Store backup location
    export _ENV_BACKUP_FILE="$backup_file"
    # Silent loading - use 'envshow' to see loaded variables
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

# Enhanced auto-env with security
auto_env() {
    # Unload previous environment
    unload_env
    
    # Load new .env if it exists
    if [[ -f .env && -r .env ]]; then
        export _PREV_ENV_FILE="$(pwd)/.env"
        load_env .env
    fi
}

# Manual environment management commands
envload() {
    local env_file="${1:-.env}"
    echo "🔍 Validating $env_file..."
    if ! validate_env_file "$env_file"; then
        echo "❌ Validation failed. Load anyway? (y/N)"
        read -r response
        [[ $response != [yY] ]] && return 1
    fi
    load_env "$env_file"
}

envcheck() {
    local env_file="${1:-.env}"
    echo "🔍 Validating $env_file..."
    validate_env_file "$env_file"
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

# Hook to run on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_env

# Load .env on shell start if present
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
