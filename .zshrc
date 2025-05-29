# =============================================================================
# MODERN ZSH CONFIGURATION
# Ultra-fast, modular, and intelligent shell environment
# =============================================================================

# Get the directory of this configuration
export ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

# Load all configuration modules in order
for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
    [[ -r "$config_file" ]] && source "$config_file"
done

# =============================================================================
# CONDITIONAL LOADING
# =============================================================================

# Load additional local configs if they exist
[ -f ~/.zsh_local ] && source ~/.zsh_local
[ -f ~/.aliases ] && source ~/.aliases

# =============================================================================
# WELCOME MESSAGE
# =============================================================================

# Welcome message disabled for silent startup
# Use 'zsh_info' command to see configuration details
