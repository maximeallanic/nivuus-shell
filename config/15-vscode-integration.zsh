# filepath: /home/mallanic/Projects/Personal/shell/config/vscode-integration.zsh
# =============================================================================
# VS CODE INTEGRATION
# =============================================================================

# VS Code integration for proper PATH and Node.js support
if [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_PID" ]] || [[ -n "$VSCODE_CWD" ]]; then
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
    
    # Ensure common development paths are available
    export PATH="$HOME/.local/bin:$PATH"
    
    # Fix for VS Code integrated terminal PATH issues
    if [[ -n "$VSCODE_SHELL_INTEGRATION" ]]; then
        # Re-export essential environment variables for task execution
        export NODE_PATH
        export NVM_BIN
        export NVM_INC
    fi
fi
