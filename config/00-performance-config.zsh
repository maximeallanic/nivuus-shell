#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# PERFORMANCE CONFIGURATION
# =============================================================================
# Centralized performance settings for the Nivuus Shell framework
# Modify these variables to tune performance vs features trade-off

# =============================================================================
# PROMPT PERFORMANCE
# =============================================================================

# Git status caching (default: 2 seconds)
# Increase for slower systems, decrease for faster git status updates
export GIT_PROMPT_CACHE_TTL="${GIT_PROMPT_CACHE_TTL:-2}"

# Firebase prompt detection (default: enabled)
# Set to false to disable Firebase project detection in prompt
# Disabling saves ~10-20ms per cd if you use Firebase
export ENABLE_FIREBASE_PROMPT="${ENABLE_FIREBASE_PROMPT:-true}"

# =============================================================================
# NVM PERFORMANCE
# =============================================================================

# NVM auto-use behavior (always enabled for best UX)
# The .nvmrc path caching is automatic and provides significant speedup

# =============================================================================
# SYNTAX HIGHLIGHTING (from previous optimizations)
# =============================================================================

# Syntax highlighting (default: enabled)
# Disable for ~27ms faster startup
export ENABLE_SYNTAX_HIGHLIGHTING="${ENABLE_SYNTAX_HIGHLIGHTING:-true}"

# =============================================================================
# PATH DIAGNOSTICS (from previous optimizations)
# =============================================================================

# PATH diagnostics (default: disabled)
# Enable for debugging PATH issues, costs ~140ms at startup
export ENABLE_PATH_DIAGNOSTICS="${ENABLE_PATH_DIAGNOSTICS:-false}"

# Project detection verbosity (default: silent)
# Enable for debugging, adds ~10-20ms at startup
export ENABLE_PROJECT_DETECTION="${ENABLE_PROJECT_DETECTION:-false}"

# =============================================================================
# PERFORMANCE TIPS
# =============================================================================
#
# If cd is still slow after these optimizations:
# 1. Check if you're in a very large git repository (git status is inherently slow)
# 2. Consider using git worktrees for large monorepos
# 3. Increase GIT_PROMPT_CACHE_TTL to 5 or 10 seconds
# 4. Set ENABLE_FIREBASE_PROMPT=false if you don't use Firebase
#
# To disable all non-essential features for maximum speed:
#   export ENABLE_SYNTAX_HIGHLIGHTING=false
#   export ENABLE_FIREBASE_PROMPT=false
#   export GIT_PROMPT_CACHE_TTL=5
#
# This will give you <50ms cd performance in most scenarios
