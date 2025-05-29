# Load modern shell configuration
if [[ -d "/opt/modern-shell" ]]; then
    export ZSH_CONFIG_DIR="/opt/modern-shell"
    source "$ZSH_CONFIG_DIR/zshrc.template"
fi
