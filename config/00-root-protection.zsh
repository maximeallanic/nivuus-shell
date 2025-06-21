#!/bin/zsh
# =============================================================================
# CRITICAL ROOT PROTECTION - MUST LOAD FIRST
# =============================================================================
# This file provides absolute protection against problematic operations
# when running as root or in restricted environments

# Fix locale issues immediately (before any other operations)
if [[ -z "$LANG" ]] || [[ "$LANG" =~ ^(C|POSIX)$ ]]; then
    export LANG=C.UTF-8
fi
if [[ -z "$LC_ALL" ]] || [[ "$LC_ALL" =~ ^(C|POSIX)$ ]]; then
    export LC_ALL=C.UTF-8
fi

# Robust root detection function
is_root_environment() {
    [[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]] || [[ "$(whoami 2>/dev/null)" == "root" ]] || [[ "$USER" == "root" ]] || [[ "$HOME" == "/root" ]]
}

# Immediate root protection
if is_root_environment; then
    # Set minimal safe environment
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    export PS1='[root] %~ # '
    
    # Completely disable antigen
    export ANTIGEN_DISABLE=1
    export ANTIGEN_DISABLE_CACHE=1
    export ANTIGEN_CACHE_DIR="/dev/null"
    unset ANTIGEN_CACHE
    unset ANTIGEN_REPO_CACHE
    
    # Mock antigen function to prevent any operations
    antigen() {
        return 0
    }
    
    # Disable other problematic features
    export SKIP_GLOBAL_CONFIG=1
    export MINIMAL_MODE=1
    export NVM_AUTO_INSTALL=false
    export DISABLE_AUTO_UPDATE=true
    export DISABLE_CORRECTION=true
fi

# Antigen cache protection for all users
if [[ ! -w "/etc/zsh" ]] 2>/dev/null && ! is_root_environment; then
    export ANTIGEN_CACHE_DIR="${HOME}/.cache/antigen"
    mkdir -p "${HOME}/.cache/antigen" 2>/dev/null || true
fi

# Global antigen mock for restricted environments
if [[ "$MINIMAL_MODE" == "1" ]] || [[ "$ANTIGEN_DISABLE" == "1" ]]; then
    antigen() {
        return 0
    }
fi
