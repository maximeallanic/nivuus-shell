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
# EXTERNAL INTEGRATIONS
# =============================================================================

# Atuin shell history (if available)
if [[ -f "$HOME/.atuin/bin/env" ]]; then
    . "$HOME/.atuin/bin/env"
    eval "$(atuin init zsh)"
fi

# =============================================================================
# WELCOME MESSAGE
# =============================================================================

# Show welcome message only for interactive shells
if [[ $- == *i* ]]; then
    echo "🚀 Modern ZSH Configuration loaded successfully!"
    echo "   Run 'aihelp' for AI commands or 'sysinfo' for system information"
fi
