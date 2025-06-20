# =============================================================================
# HISTORY CONFIGURATION
# =============================================================================

# History file and size
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# History options (optimized) - only in zsh
if [[ -n "$ZSH_VERSION" ]]; then
    setopt SHARE_HISTORY
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_FIND_NO_DUPS
    setopt HIST_SAVE_NO_DUPS
    setopt HIST_REDUCE_BLANKS
    setopt HIST_VERIFY
    setopt NO_BANG_HIST  # Disable history expansion with !

    # Enhanced history search
    autoload -U up-line-or-beginning-search
    autoload -U down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
fi
