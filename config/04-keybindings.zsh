# =============================================================================
# KEY BINDINGS
# =============================================================================

# Emacs-style key bindings
bindkey -e

# History search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# Navigation
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char

# Tab completion navigation keys
bindkey '^[[Z' reverse-menu-complete                # Shift+Tab to go backwards
bindkey '^I' expand-or-complete                     # Tab to complete

# Autosuggestions key bindings (configured in syntax-highlighting module)
bindkey '^[' autosuggest-clear                    # Alt to clear suggestion
bindkey '^[[C' forward-char                       # Right arrow to accept char
bindkey '^[[1;5C' autosuggest-accept              # Ctrl+Right to accept suggestion
bindkey '^ ' autosuggest-accept                   # Ctrl+Space to accept suggestion
