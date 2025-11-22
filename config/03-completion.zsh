#!/usr/bin/env zsh
# =============================================================================
# Completion System
# =============================================================================
# TRUE lazy loading - compinit loads on first TAB press
# =============================================================================

typeset -g ZCOMPDUMP="$HOME/.zcompdump"

# Lazy load compinit on first completion attempt
_nivuus_lazy_compinit() {
    # Remove this temporary function
    unfunction _nivuus_lazy_compinit

    # Load completion system
    autoload -Uz compinit

    # Only regenerate once per day
    if [[ -n "$ZCOMPDUMP"(#qN.mh+24) ]]; then
        compinit -d "$ZCOMPDUMP"
    else
        compinit -C -d "$ZCOMPDUMP"
    fi

    # Compile zcompdump if not already compiled (async)
    if [[ -s "$ZCOMPDUMP" && (! -s "${ZCOMPDUMP}.zwc" || "$ZCOMPDUMP" -nt "${ZCOMPDUMP}.zwc") ]]; then
        zcompile "$ZCOMPDUMP" &!
    fi

    # Apply completion styling
    _nivuus_setup_completion_styles

    # Trigger the completion that was originally requested
    zle expand-or-complete
}

# Create widget for lazy loading
zle -N _nivuus_lazy_compinit

# Bind TAB to lazy loader (will be replaced after first use)
bindkey '^I' _nivuus_lazy_compinit

# =============================================================================
# Completion Options and Styling
# =============================================================================
# These are set immediately so they're ready when compinit loads

setopt ALWAYS_TO_END        # Move cursor to end after completion
setopt AUTO_MENU            # Show completion menu on tab
setopt COMPLETE_IN_WORD     # Complete from both ends of word
setopt NO_MENU_COMPLETE     # Don't autoselect first completion

# Function to apply completion styles (called after compinit loads)
_nivuus_setup_completion_styles() {
    # Case-insensitive completion
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

    # Use menu selection
    zstyle ':completion:*' menu select

    # Cache completions
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path "$HOME/.cache/zsh/completion"

    # Group matches
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
    zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
    zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

    # Colors in completion
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

    # Process completion
    zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
}
