# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

# Root-safe mode detection
if [[ $EUID -eq 0 ]] || [[ -n "$MINIMAL_MODE" ]]; then
    # Minimal root-safe configuration
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    export PS1='[root] %~ # '
    return 0
fi

# Secure Antigen cache setup
if [ ! -d "$HOME/.antigen" ]; then
    mkdir -p "$HOME/.antigen"
    chmod 755 "$HOME/.antigen"
fi

# Remove corrupted cache files
[ -f "$HOME/.antigen/init.zsh.zwc" ] && [ ! -r "$HOME/.antigen/init.zsh.zwc" ] && rm -f "$HOME/.antigen/init.zsh.zwc"

# Disable global RCS loading for speed
unsetopt GLOBAL_RCS

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
