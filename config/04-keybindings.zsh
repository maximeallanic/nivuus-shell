#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# KEY BINDINGS
# =============================================================================

# Key bindings - only in zsh
if [[ -n "$ZSH_VERSION" ]]; then
    # Emacs-style key bindings
    bindkey -e
    
    # Backspace and Delete fix - ensure proper behavior
    bindkey '^?' backward-delete-char                 # Backspace (DEL character)
    bindkey '^H' backward-delete-char                 # Ctrl+H (traditional backspace)
    bindkey '^[[3~' delete-char                       # Delete key

    # History search
    bindkey '^[[A' up-line-or-beginning-search
    bindkey '^[[B' down-line-or-beginning-search
    bindkey '^R' history-incremental-search-backward
    bindkey '^S' history-incremental-search-forward

    # Navigation
    bindkey '^[[H' beginning-of-line
    bindkey '^[[F' end-of-line
    bindkey '^[[1;5C' forward-word                    # Ctrl+Right arrow - word navigation
    bindkey '^[[1;5D' backward-word                   # Ctrl+Left arrow - word navigation

    # Alternative word navigation bindings for compatibility
    bindkey '^[^[[C' forward-word                     # Alt+Right arrow
    bindkey '^[^[[D' backward-word                    # Alt+Left arrow

    # Tab completion navigation keys
    bindkey '^[[Z' reverse-menu-complete              # Shift+Tab to go backwards
    bindkey '^I' expand-or-complete                   # Tab to complete

    # Autosuggestions key bindings (configured in syntax-highlighting module)
    bindkey '^[' autosuggest-clear                    # Alt to clear suggestion
    bindkey '^[[C' forward-char                       # Right arrow to accept char
    bindkey '^F' autosuggest-accept                   # Ctrl+F to accept suggestion
    bindkey '^ ' autosuggest-accept                   # Ctrl+Space to accept suggestion
fi
