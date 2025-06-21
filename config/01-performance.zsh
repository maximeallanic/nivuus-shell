# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

# CRITICAL: Absolute antigen protection first
if [[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]] || [[ "$(whoami 2>/dev/null)" == "root" ]] || [[ "$USER" == "root" ]] || [[ "$HOME" == "/root" ]] || [[ "$MINIMAL_MODE" == "1" ]] || [[ "$ANTIGEN_DISABLE" == "1" ]]; then
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
    
    # Set minimal safe environment
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    export PS1='[root] %~ # '
    
    # Stop all further processing
    return 0 2>/dev/null || exit 0
fi

# Early antigen protection (before any other processing)
if [[ ! -w "/etc/zsh" ]] 2>/dev/null; then
    export ANTIGEN_CACHE_DIR="${HOME}/.cache/antigen"
    export ANTIGEN_DISABLE_CACHE=1
    mkdir -p "${HOME}/.cache/antigen" 2>/dev/null || true
fi

# Secure Antigen cache setup (only for non-root users)
if [ ! -d "$HOME/.antigen" ]; then
    mkdir -p "$HOME/.antigen"
    chmod 755 "$HOME/.antigen"
fi

# Remove corrupted cache files
[ -f "$HOME/.antigen/init.zsh.zwc" ] && [ ! -r "$HOME/.antigen/init.zsh.zwc" ] && rm -f "$HOME/.antigen/init.zsh.zwc"

# Zsh-specific optimizations
if [[ -n "$ZSH_VERSION" ]]; then
    # Disable global RCS loading for speed
    unsetopt GLOBAL_RCS
    
    # Enable null_glob to avoid "no matches found" errors
    setopt null_glob
fi

# Clean path function
add_to_path() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# Essential paths only
add_to_path "/usr/local/bin"
add_to_path "/usr/local/sbin"
add_to_path "$HOME/.local/bin"
add_to_path "/snap/bin"

# Performance optimization - Skip system config if slow
# export SKIP_GLOBAL_CONFIG=1
