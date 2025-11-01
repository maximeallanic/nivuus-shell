#!/bin/bash
# Root-Safe Shell Setup
# ====================

# Allow complete disabling of root-safe mode
if [[ "$DISABLE_ROOT_SAFE" == "1" ]]; then
    # Root-safe mode is completely disabled
    return 0
fi

# Enhanced root detection (covers su, sudo -i, problematic environments, etc.)
is_root_environment() {
    # Direct root checks - if we're actually root, check for problematic conditions
    # Protect whoami call with || true to handle missing/broken whoami
    if [[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]] || [[ "$(whoami 2>/dev/null || true)" == "root" ]]; then
        # Only activate root-safe mode if we're in a truly problematic environment
        [[ -n "$SUDO_USER" && "$PATH" == "/usr/bin:/bin" ]] || \
        [[ "$LANG" == "C" && -z "$DISPLAY" && ! -w "$HOME" ]] || \
        [[ "$PATH" == "/usr/bin:/bin" ]] || \
        [[ "$FORCE_ROOT_SAFE" == "1" ]] || [[ "$MINIMAL_MODE" == "1" ]]
    else
        # Non-root user - only if explicitly forced
        [[ "$FORCE_ROOT_SAFE" == "1" ]] || [[ "$MINIMAL_MODE" == "1" ]]
    fi
}

# Diagnostic function for troubleshooting
root_safe_diagnostics() {
    echo "🔍 Root-Safe Diagnostics:" >&2
    echo "  EUID=$EUID, UID=$UID" >&2
    echo "  USER=$USER, HOME=$HOME" >&2
    echo "  SUDO_USER=${SUDO_USER:-unset}, SUDO_UID=${SUDO_UID:-unset}" >&2
    echo "  LANG=$LANG, LC_ALL=${LC_ALL:-unset}" >&2
    echo "  PATH=$PATH" >&2
    echo "  whoami: $(whoami 2>/dev/null || echo 'failed')" >&2
    echo "  Root environment detected: $(is_root_environment && echo 'YES' || echo 'NO')" >&2
}

# Only apply root-safe configuration when actually running as root
if is_root_environment; then
    # Show diagnostics if debug mode is enabled
    [[ "$DEBUG_MODE" == "true" ]] && root_safe_diagnostics
    
    # Enhanced locale fixes for root
    if [[ -z "$LANG" ]] || [[ "$LANG" == "C" ]] || [[ "$LANG" == "POSIX" ]]; then
        # Force C.UTF-8 for root environments
        export LANG=C.UTF-8
        export LC_ALL=C.UTF-8
        echo "🌍 Root locale fixed: C.UTF-8" >&2
    fi

    # Robust PATH for root - handle missing directories gracefully
    ROOT_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    
    # Add additional paths if they exist
    [[ -d "/opt/bin" ]] && ROOT_PATH="/opt/bin:$ROOT_PATH"
    [[ -d "/usr/games" ]] && ROOT_PATH="$ROOT_PATH:/usr/games"
    
    export PATH="$ROOT_PATH"

    # Disable problematic features for root
    export SKIP_GLOBAL_CONFIG=1
    export MINIMAL_MODE=1
    export FORCE_ROOT_SAFE=1

    # Let the normal prompt handle root display (it already has root detection)
    # The prompt will show a red # for root automatically

    # Completely disable antigen for root
    # export ANTIGEN_DISABLE=1
    # export ANTIGEN_DISABLE_CACHE=1
    # export ANTIGEN_CACHE_DIR="/dev/null"
    # unset ANTIGEN_CACHE
    # unset ANTIGEN_REPO_CACHE
    # unset ANTIGEN_CACHE_DIR
    
    # Prevent any antigen operations
    # export ANTIGEN_CACHE_DIR="/dev/null"
    
    # Prevent NVM auto-install in root
    # export NVM_AUTO_INSTALL=false
    
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
