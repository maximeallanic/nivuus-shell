#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# SYNTAX HIGHLIGHTING & AUTOSUGGESTIONS
# =============================================================================
#
# PERFORMANCE NOTE: Syntax highlighting adds ~27ms to startup time.
# Set ENABLE_SYNTAX_HIGHLIGHTING=false to disable (auto-suggestions still work).
# Auto-suggestions add minimal overhead (~5ms) and are always enabled.

# Default to enabled unless explicitly disabled
: ${ENABLE_SYNTAX_HIGHLIGHTING:=true}

# Only load zsh plugins in zsh shell
if [[ -n "$ZSH_VERSION" ]]; then
    # Load zsh-autosuggestions first to avoid widget conflicts
    for plugin_path in \
        /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        ~/.local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    do
        [[ -f "$plugin_path" ]] && source "$plugin_path" && break
    done

    # Configure autosuggestions with minimal highlighting
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_USE_ASYNC=true  # PERFORMANCE: async mode for non-blocking suggestions
    ZSH_AUTOSUGGEST_MANUAL_REBIND=1
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

    # Load zsh-syntax-highlighting after autosuggestions to avoid widget conflicts
    # PERFORMANCE: Only load if enabled (saves ~27ms if disabled)
    if [[ "$ENABLE_SYNTAX_HIGHLIGHTING" == "true" ]]; then
        for plugin_path in \
            /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
            ~/.local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
            /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
            /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
            /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        do
            [[ -f "$plugin_path" ]] && source "$plugin_path" && break
        done

        # Configure subtle syntax highlighting colors (only if plugin loaded)
        if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
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
    fi
fi
