#!/usr/bin/env zsh
# =============================================================================
# Terminal Title Management
# =============================================================================
# Automatically sets terminal title with current directory and running command
# =============================================================================

# Only load once
[[ -n "${NIVUUS_TERMINAL_TITLE_LOADED}" ]] && return
export NIVUUS_TERMINAL_TITLE_LOADED=1

# =============================================================================
# Configuration
# =============================================================================

# Check if terminal supports title setting
# Most modern terminals do (xterm, gnome-terminal, konsole, iTerm2, etc.)
case "$TERM" in
    xterm*|rxvt*|screen*|tmux*|alacritty*|kitty*|wezterm*)
        NIVUUS_TITLE_ENABLED=true
        ;;
    *)
        NIVUUS_TITLE_ENABLED=false
        ;;
esac

# Don't set titles if disabled
[[ "$NIVUUS_TITLE_ENABLED" != "true" ]] && return

# =============================================================================
# Helper Functions
# =============================================================================

# Set terminal title using escape sequences
# Args: $1 = title text
_set_terminal_title() {
    local title="$1"

    # Escape sequence: OSC 0 ; title BEL
    # \033]0; = Start title sequence (OSC 0)
    # \007 = Bell character (BEL) - ends sequence
    # This sets both window title and icon/tab title
    print -Pn "\033]0;${title}\007"
}

# Get shortened directory path for display
_get_display_path() {
    # Get just the directory name (basename)
    echo "${PWD:t}"
}

# Get emoji based on directory context
_get_directory_emoji() {
    # Home directory
    if [[ "$PWD" == "$HOME" ]]; then
        echo "💻"
        return
    fi

    # Git repository
    if git rev-parse --git-dir &>/dev/null; then
        echo "🔧"
        return
    fi

    # Normal directory
    echo "📁"
}

# =============================================================================
# Hook Functions
# =============================================================================

# Called before each prompt (when returning to shell)
_terminal_title_precmd() {
    local emoji=$(_get_directory_emoji)
    local dir_path=$(_get_display_path)
    _set_terminal_title "$emoji $dir_path"
}

# Called before executing a command
_terminal_title_preexec() {
    local command="$1"
    local emoji=$(_get_directory_emoji)
    local dir_path=$(_get_display_path)

    # Truncate very long commands
    if (( ${#command} > 50 )); then
        command="${command:0:47}..."
    fi

    _set_terminal_title "$emoji $dir_path → $command"
}

# =============================================================================
# Register Hooks
# =============================================================================

autoload -U add-zsh-hook
add-zsh-hook precmd _terminal_title_precmd
add-zsh-hook preexec _terminal_title_preexec

# Set initial title
_terminal_title_precmd
