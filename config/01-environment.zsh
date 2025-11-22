#!/usr/bin/env zsh
# =============================================================================
# Environment Variables
# =============================================================================

# Editor
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"

# Pager
export PAGER="${PAGER:-less}"
export LESS="-R -F -X"

# Language
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# PATH setup
# Ensure basic system paths are included
if [[ -z "$PATH" ]] || [[ "$PATH" == "" ]]; then
    path=(
        /usr/local/sbin
        /usr/local/bin
        /usr/sbin
        /usr/bin
        /sbin
        /bin
    )
fi

typeset -U path  # Keep PATH entries unique

# Add custom directories to PATH if they exist
[[ -d "$NIVUUS_SHELL_DIR/bin" ]] && path=("$NIVUUS_SHELL_DIR/bin" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)

# Add NVM default version to PATH (for npm global packages)
# This ensures npm global commands work even before NVM lazy-loads
if [[ -d "$HOME/.nvm" ]] && [[ -f "$HOME/.nvm/alias/default" ]]; then
    local nvm_default_alias=$(<"$HOME/.nvm/alias/default")
    # Find the actual version directory (e.g., "22" -> "v22.21.0")
    local nvm_version_dir=($HOME/.nvm/versions/node/v${nvm_default_alias}*(N[1]))
    if [[ -n "$nvm_version_dir" ]] && [[ -d "$nvm_version_dir/bin" ]]; then
        path=("$nvm_version_dir/bin" $path)
    fi
fi

export PATH
