#!/usr/bin/env zsh
# =============================================================================
# Git Aliases
# =============================================================================
# Simple, fast git shortcuts
# =============================================================================

# Check if git is installed
if ! command -v git &>/dev/null; then
    return
fi

# =============================================================================
# Basic Operations
# =============================================================================

alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'

# =============================================================================
# Diffs
# =============================================================================

alias gd='git diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'

# =============================================================================
# Branches
# =============================================================================

alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout main 2>/dev/null || git checkout master'

# =============================================================================
# Logs
# =============================================================================

alias gl='git log --graph --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit -10'
alias gla='git log --graph --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --all'
alias gll='git log --graph --pretty=format:"%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

# =============================================================================
# Stash
# =============================================================================

alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'

# =============================================================================
# Remote
# =============================================================================

alias gr='git remote -v'
alias gf='git fetch'
alias gfa='git fetch --all'

# =============================================================================
# Undo/Reset
# =============================================================================

alias gundo='git reset --soft HEAD~1'
alias greset='git reset --hard HEAD'

# =============================================================================
# Clone
# =============================================================================

alias gcl='git clone'
