# Load modern shell configuration
if [[ -d "/opt/modern-shell" ]]; then
    export ZSH_CONFIG_DIR="/opt/modern-shell"
    # Load all configuration files
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi

# NVM loading is now handled by ultra-lazy loading in config/16-nvm-integration.zsh
# DO NOT load nvm.sh here - it breaks the <300ms startup target!
# NVM will be loaded automatically on first use of nvm/node/npm/npx commands
