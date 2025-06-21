#!/bin/bash
# Root-Safe Shell Setup
# ====================

# Improved root detection (covers su, sudo -i, etc.)
is_root_environment() {
    [[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]] || [[ "$(whoami)" == "root" ]] || [[ "$USER" == "root" ]] || [[ "$HOME" == "/root" ]]
}

# Only apply root-safe configuration when actually running as root
if is_root_environment; then
    # Fix locale issues for root
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8

    # Minimal safe PATH for root
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    # Disable problematic features for root
    export SKIP_GLOBAL_CONFIG=1
    export MINIMAL_MODE=1

    # Safe shell prompt for root
    export PS1='[root] %~ # '

    # Completely disable antigen for root
    export ANTIGEN_DISABLE=1
    export ANTIGEN_DISABLE_CACHE=1
    unset ANTIGEN_CACHE
    unset ANTIGEN_REPO_CACHE
    unset ANTIGEN_CACHE_DIR
    
    # Prevent any antigen operations
    export ANTIGEN_CACHE_DIR="/dev/null"
    
    # Prevent NVM auto-install in root
    export NVM_AUTO_INSTALL=false
    
    # Disable other potentially problematic features
    export DISABLE_AUTO_UPDATE=true
    export DISABLE_CORRECTION=true
fi

# Also disable antigen cache writing for non-root users if no write permissions
if [[ ! -w "/etc/zsh" ]] 2>/dev/null && ! is_root_environment; then
    export ANTIGEN_CACHE_DIR="${HOME}/.cache/antigen"
    mkdir -p "${HOME}/.cache/antigen" 2>/dev/null || true
fi

# Global antigen cache fix for all users when /etc/zsh is not writable
if [[ ! -w "/etc/zsh/zshrc.zwc" ]] 2>/dev/null && [[ ! -w "/etc/zsh" ]] 2>/dev/null; then
    export ANTIGEN_CACHE_DIR="${HOME}/.cache/antigen"
    mkdir -p "${HOME}/.cache/antigen" 2>/dev/null || true
fi
