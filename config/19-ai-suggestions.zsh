#!/usr/bin/env zsh
# =============================================================================
# AI Command Suggestions - Plugin Loader
# =============================================================================
# Loads the AI suggestions plugin from plugins/ai-suggestions/
# =============================================================================

# Only load once
[[ -n "${NIVUUS_AI_SUGGESTIONS_LOADED}" ]] && return

# Skip if explicitly disabled
[[ "${ENABLE_AI_SUGGESTIONS:-false}" != "true" ]] && return

# Load the plugin
if [[ -f "$NIVUUS_SHELL_DIR/plugins/ai-suggestions/ai-suggestions.plugin.zsh" ]]; then
    source "$NIVUUS_SHELL_DIR/plugins/ai-suggestions/ai-suggestions.plugin.zsh"
else
    echo "⚠️  AI Suggestions plugin not found at: $NIVUUS_SHELL_DIR/plugins/ai-suggestions/"
fi
