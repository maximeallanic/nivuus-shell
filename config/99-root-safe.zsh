#!/bin/bash
# Root-Safe Shell Setup
# ====================

# Only apply root-safe configuration when actually running as root
if [[ $EUID -eq 0 ]]; then
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

    # Prevent loading user-specific configs that might fail
    unset ANTIGEN_CACHE
    unset ANTIGEN_REPO_CACHE
    
    # Prevent antigen from writing to system locations
    export ANTIGEN_CACHE_DIR="/tmp/antigen-cache-$$"
    export ANTIGEN_DISABLE_CACHE=1
    
    # Prevent NVM auto-install in root
    export NVM_AUTO_INSTALL=false
fi

# Also disable antigen cache writing for non-root users if no write permissions
if [[ ! -w "/etc/zsh" ]] 2>/dev/null; then
    export ANTIGEN_CACHE_DIR="${HOME}/.cache/antigen"
    mkdir -p "${HOME}/.cache/antigen" 2>/dev/null || true
fi
