#!/usr/bin/env zsh
# =============================================================================
# Nivuus Shell - Main Configuration
# =============================================================================
# Modern, fast, AI-powered ZSH shell with Nord theme
# Performance target: <300ms startup
# Last updated: January 2025
# =============================================================================

# Performance measurement
typeset -g NIVUUS_START_TIME=$EPOCHREALTIME

# =============================================================================
# Installation Directory
# =============================================================================

export NIVUUS_SHELL_DIR="${NIVUUS_SHELL_DIR:-$HOME/.nivuus-shell}"

# Development mode: use current directory if config exists
if [[ -f "${0:A:h}/config/00-core.zsh" ]]; then
    NIVUUS_SHELL_DIR="${0:A:h}"
fi

# =============================================================================
# Feature Toggles
# =============================================================================

export ENABLE_SYNTAX_HIGHLIGHTING="${ENABLE_SYNTAX_HIGHLIGHTING:-true}"
export ENABLE_PROJECT_DETECTION="${ENABLE_PROJECT_DETECTION:-true}"
export ENABLE_FIREBASE_PROMPT="${ENABLE_FIREBASE_PROMPT:-true}"
export ENABLE_AI_SUGGESTIONS="${ENABLE_AI_SUGGESTIONS:-true}"
export GIT_PROMPT_CACHE_TTL="${GIT_PROMPT_CACHE_TTL:-2}"

# =============================================================================
# Load Configuration Modules
# =============================================================================

typeset -a config_files
config_files=(
    00-core.zsh
    01-environment.zsh
    02-history.zsh
    03-completion.zsh
    04-keybindings.zsh
    05-prompt.zsh
    06-git.zsh
    07-navigation.zsh
    08-vim.zsh
    09-nodejs.zsh
    10-ai.zsh
    11-files.zsh
    12-network.zsh
    13-system.zsh
    14-functions.zsh
    15-aliases.zsh
    16-syntax.zsh
    17-colorization.zsh
    18-autosuggestions.zsh
    19-ai-suggestions.zsh
    20-autoupdate.zsh
    20-terminal-title.zsh
    99-cleanup.zsh
)

for config_file in $config_files; do
    config_path="$NIVUUS_SHELL_DIR/config/$config_file"
    [[ -f "$config_path" ]] && source "$config_path"
done

# =============================================================================
# User Local Configuration
# =============================================================================

[[ -f "$HOME/.zsh_local" ]] && source "$HOME/.zsh_local"

# =============================================================================
# Performance Report
# =============================================================================

if [[ -n "$EPOCHREALTIME" ]] && [[ -n "$NIVUUS_START_TIME" ]]; then
    typeset -g NIVUUS_END_TIME=$EPOCHREALTIME
    typeset -g NIVUUS_LOAD_TIME=$(( ($NIVUUS_END_TIME - $NIVUUS_START_TIME) * 1000 ))

    if (( ${NIVUUS_LOAD_TIME} > 500 )); then
        echo "⚠️  Nivuus Shell: ${NIVUUS_LOAD_TIME}ms (target: <300ms)"
    fi
fi
