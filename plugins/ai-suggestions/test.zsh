#!/usr/bin/env zsh
# Quick test script for ai-suggestions plugin

echo "Testing AI Suggestions Plugin..."
echo

# Set test mode (disable actual API calls for now)
export ENABLE_AI_SUGGESTIONS=true
export AI_DEBUG=true

# Source the plugin
source "${0:A:h}/ai-suggestions.plugin.zsh"

# Check if plugin loaded
if [[ -n "$NIVUUS_AI_SUGGESTIONS_LOADED" ]]; then
    echo "✓ Plugin loaded successfully"
else
    echo "✗ Plugin failed to load"
    exit 1
fi

# Check if async worker is running
# async provides async_job function, if it exists the library loaded correctly
if typeset -f async_job &>/dev/null; then
    echo "✓ zsh-async library loaded"

    # Try to get worker status
    if async_job ai_suggestions : 2>/dev/null; then
        echo "✓ Async worker is responsive"
    else
        echo "⚠ Async worker may not be fully initialized (non-critical)"
    fi
else
    echo "✗ zsh-async library not loaded"
    exit 1
fi

# Check if functions are defined
functions_to_check=(
    "_ai_collect_context"
    "_ai_generate_cache_key"
    "_ai_fetch_suggestion"
    "_ai_schedule_suggestion"
    "_ai_accept_suggestion"
    "_ai_async_callback"
    "_ai_debounced_fetch"
    "ai_suggestions_help"
)

for func in $functions_to_check; do
    if typeset -f "$func" &>/dev/null; then
        echo "✓ Function $func defined"
    else
        echo "✗ Function $func missing"
        exit 1
    fi
done

# Check if widgets are registered (only in interactive mode)
if [[ -o interactive ]]; then
    widgets_to_check=(
        "ai-accept-suggestion"
        "ai-up-line"
        "ai-down-line"
    )

    for widget in $widgets_to_check; do
        if zle -l | grep -q "^$widget\$"; then
            echo "✓ Widget $widget registered"
        else
            echo "✗ Widget $widget not registered"
            exit 1
        fi
    done
else
    echo "⚠ Skipping widget checks (non-interactive shell)"
fi

# Test context collection
echo
echo "Testing context collection..."
context=$(_ai_collect_context)
if [[ -n "$context" ]]; then
    echo "✓ Context collected:"
    echo "$context" | sed 's/^/  /'
else
    echo "✗ Context collection failed"
    exit 1
fi

# Test cache key generation
echo
echo "Testing cache key generation..."
cache_key=$(_ai_generate_cache_key "git status")
if [[ -n "$cache_key" ]]; then
    echo "✓ Cache key generated: $cache_key"
else
    echo "✗ Cache key generation failed"
    exit 1
fi

echo
echo "All tests passed! ✓"
echo
echo "Note: To test actual suggestions, ensure gemini CLI is installed and configured."
echo "Then enable the plugin in your shell and type a command."
