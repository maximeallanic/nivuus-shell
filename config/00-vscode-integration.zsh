#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# VS CODE INTEGRATION - PRIORITY LOADING
# =============================================================================

# CRITICAL: Fix PATH immediately to prevent sed/cat errors in VS Code
# This MUST load before any other modules that might need basic commands

# FORCE reset PATH completely (system PATH is corrupted)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add Google Cloud SDK if it exists
[[ -d "/home/mallanic/google-cloud-sdk/bin" ]] && export PATH="/home/mallanic/google-cloud-sdk/bin:$PATH"

# Add snap binaries if available (common on Ubuntu/Debian)
[[ -d "/snap/bin" ]] && export PATH="/snap/bin:$PATH"

# Ensure ~/.local/bin is available early  
export PATH="$HOME/.local/bin:$PATH"
# VS Code specific integration
if [[ -n "$VSCODE_INJECTION" ]] || [[ -n "$TERM_PROGRAM" && "$TERM_PROGRAM" = "vscode" ]] || [[ -n "$VSCODE_PID" ]] || [[ -n "$VSCODE_CWD" ]]; then
    # NVM should already be loaded by system zshenv, just ensure proper Node.js version
    if command -v nvm &> /dev/null; then
        # Auto-use Node version from .nvmrc if available
        if [[ -f ".nvmrc" ]]; then
            nvm use --silent 2>/dev/null || true
        elif [[ "$(nvm current 2>/dev/null)" == "none" ]] || [[ "$(nvm current 2>/dev/null)" == "system" ]]; then
            # Fallback to default or latest LTS if no version is active
            nvm use default --silent 2>/dev/null || nvm use --lts --silent 2>/dev/null || true
        fi
    fi
    
    # Fix for VS Code integrated terminal PATH issues
    if [[ -n "$VSCODE_SHELL_INTEGRATION" ]]; then
        # Re-export essential environment variables for task execution
        export NODE_PATH
        export NVM_BIN
        export NVM_INC
    fi
fi
