#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# VS CODE INTEGRATION - PRIORITY PATH FIX
# =============================================================================
#
# CRITICAL: Fix PATH immediately to prevent sed/cat errors in VS Code
# This MUST load before any other modules that might need basic commands

# FORCE reset PATH completely if corrupted
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add common development paths
[[ -d "/home/mallanic/google-cloud-sdk/bin" ]] && export PATH="/home/mallanic/google-cloud-sdk/bin:$PATH"
[[ -d "/snap/bin" ]] && export PATH="/snap/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# VS Code environment variables (NVM handled by ultra-lazy loading in 16-nvm-integration.zsh)
if [[ -n "$VSCODE_SHELL_INTEGRATION" ]]; then
    # These will be set when NVM loads on-demand
    export NODE_PATH NVM_BIN NVM_INC
fi
