#!/bin/bash
# Root-Safe Shell Setup
# ====================

# Fix locale issues for root
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Minimal safe PATH for root
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Disable problematic features for root
export SKIP_GLOBAL_CONFIG=1
export MINIMAL_MODE=1

# Safe shell prompt for root
# if [[ $EUID -eq 0 ]]; then
#     export PS1='[root] %~ # '
# fi

# Prevent loading user-specific configs that might fail
unset ANTIGEN_CACHE
unset ANTIGEN_REPO_CACHE
