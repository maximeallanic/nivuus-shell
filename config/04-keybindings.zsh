#!/usr/bin/env zsh
# =============================================================================
# Keyboard Shortcuts
# =============================================================================

# Use emacs mode (more intuitive for most users)
bindkey -e

# =============================================================================
# History Navigation
# =============================================================================

# Up/Down arrows: Prefix-based history search
# (Type "git s" then press Up → shows only commands starting with "git s")
bindkey '^[[A' history-search-backward    # Up arrow
bindkey '^[OA' history-search-backward    # Up arrow (alternative)
bindkey '^[[B' history-search-forward     # Down arrow
bindkey '^[OB' history-search-forward     # Down arrow (alternative)

# Ctrl+P/N: Standard history navigation (no prefix filter)
bindkey '^P' up-history
bindkey '^N' down-history

# Ctrl+R for reverse search (interactive)
bindkey '^R' history-incremental-search-backward

# Ctrl+S for forward search (interactive)
bindkey '^S' history-incremental-search-forward

# =============================================================================
# Line Editing
# =============================================================================

# Ctrl+A - beginning of line
bindkey '^A' beginning-of-line

# Ctrl+E - end of line
bindkey '^E' end-of-line

# Ctrl+K - kill to end of line
bindkey '^K' kill-line

# Ctrl+U - kill to beginning of line
bindkey '^U' backward-kill-line

# Ctrl+W - kill word backward
bindkey '^W' backward-kill-word

# Alt+D - kill word forward
bindkey '\ed' kill-word

# Ctrl+Y - yank (paste)
bindkey '^Y' yank

# =============================================================================
# Word Navigation
# =============================================================================

# Ctrl+Left - move backward one word
bindkey '^[[1;5D' backward-word
bindkey '\e[1;5D' backward-word
bindkey '^[Od' backward-word  # Alternative for some terminals

# Ctrl+Right - move forward one word
bindkey '^[[1;5C' forward-word
bindkey '\e[1;5C' forward-word
bindkey '^[Oc' forward-word  # Alternative for some terminals

# Alt+B - backward word (emacs style)
bindkey '\eb' backward-word

# Alt+F - forward word (emacs style)
bindkey '\ef' forward-word

# =============================================================================
# Directory Navigation
# =============================================================================

# Alt+Left - go back in directory stack
bindkey '\e[1;3D' insert-last-word

# Alt+Right - go forward in directory stack
bindkey '\e[1;3C' insert-last-word
