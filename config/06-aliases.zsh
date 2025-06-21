#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# MODERN FAST ALIASES & TOOLS
# =============================================================================

# Modern replacements with subtle colors
if command -v eza &> /dev/null; then
    alias ls='eza --group-directories-first --color=auto'
    alias ll='eza -la --group-directories-first --color=auto --git'
    alias la='eza -a --group-directories-first --color=auto'
    alias l='eza -l --group-directories-first --color=auto'
    alias tree='eza --tree --color=auto'
else
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

# Check for bat (modern cat replacement)
# if command -v bat &> /dev/null; then
#     alias cat='bat --paging=never --style=plain'
#     alias cath='bat --style=header,grid'  # cat with header/line numbers
# elif command -v batcat &> /dev/null; then
#     alias cat='batcat --paging=never --style=plain'
#     alias cath='batcat --style=header,grid'  # cat with header/line numbers
#     alias bat='batcat'  # Create bat alias for consistency
# fi

if command -v fd &> /dev/null; then
    alias fd='fd --hidden --follow --exclude .git'
fi

# Grep alternatives (avoid conflict with function)
if command -v rg &> /dev/null; then
    alias grep='rg'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
    alias rg='rg --smart-case --follow --hidden'
fi

# Enhanced system shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Directory navigation with history
alias d='dirs -v | head -20'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'

# Git shortcuts (lightning fast)
alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gba='git branch -a'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate -10'
alias gla='git log --oneline --graph --decorate --all'

# Package management (smart)
alias apt='sudo apt'
alias install='sudo apt install'
alias update='sudo apt update && sudo apt upgrade'
alias search='apt search'
alias autoremove='sudo apt autoremove'

# Safety with confirmation - rm confirmation disabled
# alias rm='rm -i'  # Disabled to avoid prompts
# alias cp='cp -i'
# alias mv='mv -i'

# Enhanced utilities
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias top='htop'

# Network utilities
alias ports='netstat -tulanp'
alias myip='curl -s https://ifconfig.me'
alias localip='hostname -I'

# Quick file operations
alias mkdir='mkdir -pv'
alias wget='wget -c'

# Safe glob patterns (null_glob option for these commands)
alias clean-logs='rm -f **/*.log **/*.tsbuildinfo **/.eslintcache'
alias clean-cache='rm -rf node_modules/.cache .next/cache .nuxt .cache'
alias clean-build='rm -rf dist build out .next **/*.tsbuildinfo'

# Maintenance aliases
alias healthcheck='zsh_health_check'
alias cleanup='zsh_cleanup'
alias benchmark='zsh_benchmark'
