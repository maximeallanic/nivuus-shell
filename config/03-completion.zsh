#!/usr/bin/env zsh
# =============================================================================
# Completion System
# =============================================================================
# Lazy loaded for performance
# =============================================================================

# Initialize completion system
autoload -Uz compinit

# Compile completion dump for faster loading
typeset -g ZCOMPDUMP="$HOME/.zcompdump"

# Only regenerate once per day
if [[ -n "$ZCOMPDUMP"(#qN.mh+24) ]]; then
    compinit -d "$ZCOMPDUMP"
else
    compinit -C -d "$ZCOMPDUMP"
fi

# Compile zcompdump if not already compiled
if [[ -s "$ZCOMPDUMP" && (! -s "${ZCOMPDUMP}.zwc" || "$ZCOMPDUMP" -nt "${ZCOMPDUMP}.zwc") ]]; then
    zcompile "$ZCOMPDUMP"
fi

# =============================================================================
# Completion Options
# =============================================================================

setopt ALWAYS_TO_END        # Move cursor to end after completion
setopt AUTO_MENU            # Show completion menu on tab
setopt COMPLETE_IN_WORD     # Complete from both ends of word
setopt NO_MENU_COMPLETE     # Don't autoselect first completion

# =============================================================================
# Completion Styling
# =============================================================================

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
