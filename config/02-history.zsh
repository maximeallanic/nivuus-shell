#!/usr/bin/env zsh
# =============================================================================
# History Configuration
# =============================================================================
# Optimized for performance and usability
# =============================================================================

# History file location
HISTFILE="$HOME/.zsh_history"

# History size
HISTSIZE=50000
SAVEHIST=50000

# =============================================================================
# History Options
# =============================================================================

# Append to history file
setopt APPEND_HISTORY

# Share history between sessions
setopt SHARE_HISTORY

# Add timestamp to history
setopt EXTENDED_HISTORY

# Remove older duplicate entries
setopt HIST_EXPIRE_DUPS_FIRST

# Don't record duplicates
setopt HIST_IGNORE_DUPS

# Don't record commands starting with space
setopt HIST_IGNORE_SPACE

# Remove superfluous blanks
setopt HIST_REDUCE_BLANKS

# Don't store history/fc commands
setopt HIST_NO_STORE

# Verify history expansion before execution
setopt HIST_VERIFY

# Better history search
setopt HIST_FIND_NO_DUPS
