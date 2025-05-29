# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

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
