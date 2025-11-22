#!/usr/bin/env bash
# =============================================================================
# Nivuus Shell - Development Mode
# =============================================================================
# Launch ZSH in dev mode directly from the repo without installation
# No file copying, no compilation - instant testing
# =============================================================================

set -e

# Get repo directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dev mode configuration
export NIVUUS_SHELL_DIR="$REPO_DIR"
export NIVUUS_NO_COMPILE=1
export NIVUUS_DEV_MODE=1

echo "🔧 Nivuus Shell - Development Mode"
echo "📁 Using: $NIVUUS_SHELL_DIR"
echo "⚡ Compilation disabled for fast iteration"
echo ""

# Launch ZSH with dev config
exec zsh
