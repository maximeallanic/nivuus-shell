#!/bin/bash
# Root-Safe Shell Setup
# ====================

# Only apply root-safe configuration when actually running as root
if [[ $EUID -eq 0 ]]; then
    # Fix locale issues for root
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8

    # Minimal safe PATH for root
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    # Disable problematic features for root
    export SKIP_GLOBAL_CONFIG=1
    export MINIMAL_MODE=1

    # Safe shell prompt for root
    export PS1='[root] %~ # '

    # Prevent loading user-specific configs that might fail
    unset ANTIGEN_CACHE
    unset ANTIGEN_REPO_CACHE
fi
