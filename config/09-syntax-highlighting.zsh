#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# SYNTAX HIGHLIGHTING & AUTOSUGGESTIONS
# =============================================================================

# Only load zsh plugins in zsh shell
if [[ -n "$ZSH_VERSION" ]]; then
    # Load zsh-autosuggestions first to avoid widget conflicts
    # Support multiple installation paths for different distributions
    if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        # Ubuntu/Debian
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [[ -f ~/.local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        # Manual installation
        source ~/.local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [[ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        # System-wide manual installation
        source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        # Homebrew on Apple Silicon
        source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [[ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        # Homebrew on Intel Mac
        source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    elif [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        # Arch Linux
        source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    fi

    # Configure autosuggestions with minimal highlighting
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_USE_ASYNC=false
    ZSH_AUTOSUGGEST_MANUAL_REBIND=1
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

    # Load zsh-syntax-highlighting after autosuggestions to avoid widget conflicts
    # Support multiple installation paths for different distributions
    if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        # Ubuntu/Debian
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ -f ~/.local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        # Manual installation
        source ~/.local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        # System-wide manual installation
        source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        # Homebrew on Apple Silicon
        source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        # Homebrew on Intel Mac
        source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        # Arch Linux
        source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi

    # Configure subtle syntax highlighting colors
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
    ZSH_HIGHLIGHT_STYLES[default]='none'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=green'
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=green'
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=green'
    ZSH_HIGHLIGHT_STYLES[commandseparator]='none'
    ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[path]='underline'
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='none'
    ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='none'
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[command-substitution]='none'
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[process-substitution]='none'
    ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='none'
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='none'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='none'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=yellow'
    ZSH_HIGHLIGHT_STYLES[rc-quote]='none'
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='none'
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='none'
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='none'
    ZSH_HIGHLIGHT_STYLES[assign]='none'
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=blue'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=black'
    ZSH_HIGHLIGHT_STYLES[named-fd]='none'
    ZSH_HIGHLIGHT_STYLES[numeric-fd]='none'
    ZSH_HIGHLIGHT_STYLES[arg0]='fg=green'
fi
