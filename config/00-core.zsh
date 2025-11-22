#!/usr/bin/env zsh
# =============================================================================
# Core ZSH Settings
# =============================================================================
# Minimal, fast core configuration
# =============================================================================

# Load Nord theme
source "$NIVUUS_SHELL_DIR/themes/nord.zsh"

# =============================================================================
# Basic Options
# =============================================================================

# Disable beep
setopt NO_BEEP

# Allow comments in interactive shell
setopt INTERACTIVE_COMMENTS

# Change directory without cd
setopt AUTO_CD

# Push directory to stack automatically
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Better globbing
setopt EXTENDED_GLOB
setopt GLOB_DOTS

# Disable flow control (Ctrl+S/Ctrl+Q)
setopt NO_FLOW_CONTROL

# =============================================================================
# Directory Stack
# =============================================================================

DIRSTACKSIZE=10

# =============================================================================
# Color Support
# =============================================================================

# Enable colors
autoload -U colors && colors

# Colored output for ls
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    export CLICOLOR=1
    alias ls='ls -G'
else
    # Linux
    alias ls='ls --color=auto'
fi

# Colored grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# =============================================================================
# Disable Python/Conda Prompt Modifications
# =============================================================================

export VIRTUAL_ENV_DISABLE_PROMPT=1
export CONDA_CHANGEPS1=false
