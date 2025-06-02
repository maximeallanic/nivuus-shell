# Load modern shell configuration
if [[ -d "/opt/modern-shell" ]]; then
    export ZSH_CONFIG_DIR="/opt/modern-shell"
    # Load all configuration files
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi
