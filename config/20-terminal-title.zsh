#!/usr/bin/env zsh
# =============================================================================
# Terminal Title Management (with AI)
# =============================================================================
# Automatically sets terminal title with current directory and running command
# Optionally uses Gemini AI for creative titles (exponential backoff)
# =============================================================================

# Only load once
[[ -n "${NIVUUS_TERMINAL_TITLE_LOADED}" ]] && return
export NIVUUS_TERMINAL_TITLE_LOADED=1

# =============================================================================
# Configuration
# =============================================================================

# Check if terminal supports title setting
case "$TERM" in
    xterm*|rxvt*|screen*|tmux*|alacritty*|kitty*|wezterm*)
        NIVUUS_TITLE_ENABLED=true
        ;;
    *)
        NIVUUS_TITLE_ENABLED=false
        ;;
esac

# Don't set titles if disabled
[[ "$NIVUUS_TITLE_ENABLED" != "true" ]] && return

# AI Titles Configuration (only if enabled)
if [[ "${ENABLE_AI_TERMINAL_TITLES:-false}" == "true" ]]; then
    export AI_TITLE_MODEL="${AI_TITLE_MODEL:-gemini-2.5-flash-lite}"
    export AI_TITLE_CACHE_TTL="${AI_TITLE_CACHE_TTL:-3600}"  # 1 hour
    export AI_TITLE_MAX_LENGTH="${AI_TITLE_MAX_LENGTH:-60}"
    export AI_TITLE_CACHE_DIR="${AI_TITLE_CACHE_DIR:-$HOME/.cache/nivuus-shell/ai-titles}"

    # Create cache directory
    mkdir -p "$AI_TITLE_CACHE_DIR" 2>/dev/null

    # State variables for exponential backoff
    typeset -g _AI_TITLE_COMMAND_COUNT=0
    typeset -g _AI_TITLE_NEXT_TRIGGER=1
    typeset -g _AI_TITLE_CURRENT=""  # Store current AI title
    typeset -gA _AI_TITLE_TRIGGER_SEQUENCE=(
        1  1    # 1st command
        2  2    # 2nd
        3  3    # 3rd
        4  5    # 5th
        5  10   # 10th
        6  20   # 20th
        7  50   # 50th
        8  100  # 100th
        9  200  # 200th
        10 500  # 500th
    )
fi

# =============================================================================
# Helper Functions
# =============================================================================

# Set terminal title using escape sequences
_set_terminal_title() {
    local title="$1"
    # OSC 0 ; title BEL
    print -Pn "\033]0;${title}\007"
}

# Get shortened directory path for display
_get_display_path() {
    echo "${PWD:t}"
}

# Get emoji based on directory context
_get_directory_emoji() {
    if [[ "$PWD" == "$HOME" ]]; then
        echo "💻"
    elif git rev-parse --git-dir &>/dev/null; then
        echo "🔧"
    else
        echo "📁"
    fi
}

# =============================================================================
# AI Title Functions (only loaded if AI titles enabled)
# =============================================================================

if [[ "${ENABLE_AI_TERMINAL_TITLES:-false}" == "true" ]]; then

    _ai_title_cache_key() {
        local cmd="$1"
        local dir="$2"
        local context="$3"
        echo -n "${cmd}|${dir}|${context}" | md5sum | cut -d' ' -f1
    }

    _ai_title_cache_get() {
        local cache_key="$1"
        local cache_file="$AI_TITLE_CACHE_DIR/$cache_key"

        if [[ -f "$cache_file" ]]; then
            local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
            local current_time=$(date +%s)

            if (( current_time - file_time < AI_TITLE_CACHE_TTL )); then
                cat "$cache_file"
                return 0
            fi
        fi
        return 1
    }

    _ai_title_cache_set() {
        local cache_key="$1"
        local content="$2"
        local cache_file="$AI_TITLE_CACHE_DIR/$cache_key"
        mkdir -p "$AI_TITLE_CACHE_DIR" 2>/dev/null
        echo "$content" > "$cache_file" 2>/dev/null
    }

    _ai_title_get_context() {
        local context=""

        if [[ -f "package.json" ]]; then
            context="Node.js"
        elif [[ -f "go.mod" ]]; then
            context="Go"
        elif [[ -f "Cargo.toml" ]]; then
            context="Rust"
        elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
            context="Python"
        elif [[ -f "Makefile" ]]; then
            context="Make"
        elif [[ -f "docker-compose.yml" ]]; then
            context="Docker"
        fi

        if git rev-parse --git-dir &>/dev/null 2>&1; then
            local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
            [[ -n "$context" ]] && context+=", "
            context+="git:$branch"
        fi

        echo "$context"
    }

    _ai_should_generate_title() {
        (( _AI_TITLE_COMMAND_COUNT++ ))

        if (( _AI_TITLE_COMMAND_COUNT == _AI_TITLE_NEXT_TRIGGER )); then
            for level trigger in ${(kv)_AI_TITLE_TRIGGER_SEQUENCE}; do
                if (( trigger > _AI_TITLE_COMMAND_COUNT )); then
                    _AI_TITLE_NEXT_TRIGGER=$trigger
                    return 0
                fi
            done
            _AI_TITLE_NEXT_TRIGGER=$(( _AI_TITLE_COMMAND_COUNT + _AI_TITLE_COMMAND_COUNT / 2 ))
            return 0
        fi

        return 1
    }

    _ai_get_terminal_title() {
        local cmd="$1"
        local dir_name="$2"

        local context=$(_ai_title_get_context)

        # Check for API key
        if [[ -z "$GOOGLE_API_KEY" ]]; then
            local config_file="$HOME/.gemini-cli/config.json"
            if [[ -f "$config_file" ]]; then
                GOOGLE_API_KEY=$(grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | cut -d'"' -f4)
            fi
        fi

        [[ -z "$GOOGLE_API_KEY" ]] && return 1

        # Get entire session command history (limited to last 50 to avoid API limits)
        local recent_history=$(fc -ln -50 | tr '\n' ';' | sed 's/;$//' | cut -c1-500)

        # Check cache first (cache by directory + context, not command)
        local cache_key=$(_ai_title_cache_key "$recent_history" "$dir_name" "$context")
        local cached_title=""
        if cached_title=$(_ai_title_cache_get "$cache_key"); then
            echo "$cached_title"
            return 0
        fi

        # Build prompt for session context title
        local prompt="Output ONLY a terminal title (emoji + text, max 30 chars). No preamble! Based on these commands: $recent_history. Create a fun, creative title that captures what I'm doing. Be playful!"
        local escaped_prompt="${prompt//\"/\\\"}"
        local json="{\"contents\":[{\"parts\":[{\"text\":\"$escaped_prompt\"}]}],\"generationConfig\":{\"temperature\":1.2,\"maxOutputTokens\":25}}"

        # Call API with timeout
        local api_url="https://generativelanguage.googleapis.com/v1beta/models/${AI_TITLE_MODEL}:generateContent?key=${GOOGLE_API_KEY}"
        local api_response=$(timeout 3 curl -s -X POST "$api_url" \
            -H 'Content-Type: application/json' \
            -d "$json" 2>/dev/null)

        # Extract title - take last non-empty line (skips any preamble)
        local result=$(echo "$api_response" | \
            grep -o '"text"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 | \
            sed 's/\\n/\n/g' | \
            grep -v '^[[:space:]]*$' | \
            tail -1 | \
            sed 's/^\*\*\(.*\)\*\*$/\1/' | \
            sed 's/^"\(.*\)"$/\1/' | \
            sed 's/^[[:space:]]*//' | \
            cut -c1-30)

        if [[ -n "$result" ]]; then
            _ai_title_cache_set "$cache_key" "$result"
            echo "$result"
            return 0
        fi

        return 1
    }

    # User commands
    ai-title-clear-cache() {
        local count=$(ls -1 "$AI_TITLE_CACHE_DIR" 2>/dev/null | wc -l)
        command rm -rf "$AI_TITLE_CACHE_DIR"/*
        mkdir -p "$AI_TITLE_CACHE_DIR"
        echo "✓ Cleared $count cached AI titles"
    }

    ai-title-stats() {
        local cache_count=$(ls -1 "$AI_TITLE_CACHE_DIR" 2>/dev/null | wc -l)
        local cache_size=$(du -sh "$AI_TITLE_CACHE_DIR" 2>/dev/null | cut -f1)

        echo "AI Terminal Titles Statistics"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Commands run: $_AI_TITLE_COMMAND_COUNT"
        echo "Next AI generation: command #$_AI_TITLE_NEXT_TRIGGER"
        echo ""
        echo "Cached titles: $cache_count"
        echo "Cache size: $cache_size"
        echo "Cache TTL: ${AI_TITLE_CACHE_TTL}s ($(( AI_TITLE_CACHE_TTL / 60 )) minutes)"
        echo "Model: $AI_TITLE_MODEL"
        echo "Max length: $AI_TITLE_MAX_LENGTH characters"
        echo ""
        echo "Trigger sequence: 1, 2, 3, 5, 10, 20, 50, 100, 200, 500..."
    }

    ai-title-reset-counter() {
        _AI_TITLE_COMMAND_COUNT=0
        _AI_TITLE_NEXT_TRIGGER=1
        echo "✓ Reset command counter"
    }

fi

# =============================================================================
# Hook Functions
# =============================================================================

_terminal_title_precmd() {
    if [[ "${ENABLE_AI_TERMINAL_TITLES:-false}" == "true" ]]; then
        # Show stored AI title (without command)
        if [[ -n "$_AI_TITLE_CURRENT" ]]; then
            _set_terminal_title "$_AI_TITLE_CURRENT"
            return
        fi
    fi

    # Fallback to emoji
    local emoji=$(_get_directory_emoji)
    local dir_path=$(_get_display_path)
    _set_terminal_title "$emoji $dir_path"
}

_terminal_title_preexec() {
    local command="$1"
    local emoji=$(_get_directory_emoji)
    local dir_path=$(_get_display_path)

    # Truncate very long commands for display
    local display_cmd="$command"
    if (( ${#display_cmd} > 30 )); then
        display_cmd="${display_cmd:0:27}..."
    fi

    if [[ "${ENABLE_AI_TERMINAL_TITLES:-false}" == "true" ]]; then
        # Generate new AI title if backoff says so
        if _ai_should_generate_title; then
            local new_title=$(_ai_get_terminal_title "$command" "$dir_path")
            if [[ -n "$new_title" ]]; then
                _AI_TITLE_CURRENT="$new_title"
            fi
        fi

        # Show AI title + command, or emoji if no AI title yet
        if [[ -n "$_AI_TITLE_CURRENT" ]]; then
            _set_terminal_title "$_AI_TITLE_CURRENT - $display_cmd"
        else
            _set_terminal_title "$emoji $dir_path → $display_cmd"
        fi
    else
        # AI disabled, use emoji
        _set_terminal_title "$emoji $dir_path → $display_cmd"
    fi
}

_terminal_title_chpwd() {
    _terminal_title_precmd
}

# =============================================================================
# Register Hooks
# =============================================================================

autoload -U add-zsh-hook
add-zsh-hook precmd _terminal_title_precmd
add-zsh-hook preexec _terminal_title_preexec
add-zsh-hook chpwd _terminal_title_chpwd

# Set initial title
_terminal_title_precmd
