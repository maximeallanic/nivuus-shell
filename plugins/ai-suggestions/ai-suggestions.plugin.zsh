#!/usr/bin/env zsh
# =============================================================================
# AI Command Suggestions - Gemini Integration (zsh-async)
# =============================================================================
# Real-time intelligent command suggestions with 2s debounce
# =============================================================================

# Only load once
[[ -n "${NIVUUS_AI_SUGGESTIONS_LOADED}" ]] && return
export NIVUUS_AI_SUGGESTIONS_LOADED=1

# Skip if explicitly disabled
[[ "${ENABLE_AI_SUGGESTIONS:-false}" != "true" ]] && return

# =============================================================================
# Dependencies
# =============================================================================

# Load zsh-async library (bundled)
source "${0:A:h}/lib/async.zsh"

# =============================================================================
# Configuration
# =============================================================================

typeset -gi AI_SUGGESTION_DEBOUNCE_TIME=2     # seconds
typeset -gi AI_SUGGESTION_CACHE_TTL=300       # 5 minutes
typeset -gi AI_SUGGESTION_MIN_CHARS=3         # Min buffer length
typeset -g AI_SUGGESTION_COLOR='240'          # Nord3 dim gray
typeset -g AI_SUGGESTION_INDENT='> '          # Indent prefix (configure to match your prompt)

# =============================================================================
# State Management
# =============================================================================

typeset -g _AI_CURRENT_SUGGESTION=""
typeset -g _AI_DISPLAY_VISIBLE=false
typeset -gA _AI_CACHE
typeset -gA _AI_CACHE_TIME
typeset -g _AI_LAST_BUFFER=""
typeset -g _AI_NAVIGATION_MODE=false
typeset -g _AI_SPINNER_VISIBLE=false

# Spinner animation frames (Braille dots)
typeset -ga _AI_SPINNER_FRAMES
_AI_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
typeset -gi _AI_SPINNER_INDEX=0

# =============================================================================
# Context Collection
# =============================================================================

_ai_collect_context() {
    local context=""

    # Working directory (basename for privacy)
    context+="Directory: ${PWD:t}\n"

    # Recent history (last 5 commands)
    local history=$(fc -ln -5 2>/dev/null | sed 's/^/  /')
    if [[ -n "$history" ]]; then
        context+="Recent commands:\n$history\n"
    fi

    # Project type detection (quick file checks)
    if [[ -f package.json ]]; then
        context+="Project: Node.js"
        [[ -f package-lock.json ]] && context+=" (npm)"
        [[ -f yarn.lock ]] && context+=" (yarn)"
        [[ -f pnpm-lock.yaml ]] && context+=" (pnpm)"
        context+="\n"
    fi
    [[ -f Cargo.toml ]] && context+="Project: Rust\n"
    [[ -f go.mod ]] && context+="Project: Go\n"
    [[ -f requirements.txt ]] || [[ -f setup.py ]] && context+="Project: Python\n"
    [[ -f .firebaserc ]] && context+="Project: Firebase\n"

    # Git context (with error handling)
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
        context+="Git branch: $branch\n"

        # Check if dirty
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            context+="Git status: Modified\n"
        fi
    fi

    echo "$context"
}

# =============================================================================
# Cache Management
# =============================================================================

_ai_generate_cache_key() {
    local buffer="$1"
    local pwd="$PWD"
    local git_branch=""

    # Include git branch for context
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    fi

    # Create composite key: pwd:branch:buffer
    local key="${pwd}:${git_branch}:${buffer}"

    # Sanitize (replace special chars with underscore)
    echo "${key//[^a-zA-Z0-9_:]/_}"
}

_ai_get_cached_suggestion() {
    local key="$1"
    local current_time=$EPOCHSECONDS

    # Check if cache exists
    if [[ -n "${_AI_CACHE[$key]}" ]]; then
        local cache_time=${_AI_CACHE_TIME[$key]}
        local age=$(( current_time - cache_time ))

        # Check TTL
        if (( age < AI_SUGGESTION_CACHE_TTL )); then
            echo "${_AI_CACHE[$key]}"
            return 0
        else
            # Expired - remove from cache
            unset "_AI_CACHE[$key]"
            unset "_AI_CACHE_TIME[$key]"
        fi
    fi

    return 1
}

_ai_set_cached_suggestion() {
    local key="$1"
    local suggestion="$2"

    _AI_CACHE[$key]="$suggestion"
    _AI_CACHE_TIME[$key]=$EPOCHSECONDS
}

# =============================================================================
# Display Management
# =============================================================================

_ai_start_spinner() {
    [[ "$_AI_SPINNER_VISIBLE" == "true" ]] && return

    _AI_SPINNER_VISIBLE=true
    _AI_SPINNER_INDEX=0

    # Show initial spinner frame
    local spinner_char="${_AI_SPINNER_FRAMES[1]}"
    RPROMPT="%F{${AI_SUGGESTION_COLOR}}${spinner_char}%f"
    zle -R 2>/dev/null
}

_ai_update_spinner() {
    [[ "$_AI_SPINNER_VISIBLE" != "true" ]] && return

    # Rotate to next frame
    _AI_SPINNER_INDEX=$(( (_AI_SPINNER_INDEX + 1) % ${#_AI_SPINNER_FRAMES[@]} ))
    local spinner_char="${_AI_SPINNER_FRAMES[$((_AI_SPINNER_INDEX + 1))]}"

    RPROMPT="%F{${AI_SUGGESTION_COLOR}}${spinner_char}%f"
    zle -R 2>/dev/null
}

_ai_stop_spinner() {
    [[ "$_AI_SPINNER_VISIBLE" != "true" ]] && return

    _AI_SPINNER_VISIBLE=false
    RPROMPT=""
    zle -R 2>/dev/null
}

_ai_clear_display() {
    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Clearing display" >&2

    _ai_stop_spinner
    _AI_CURRENT_SUGGESTION=""
    _AI_DISPLAY_VISIBLE=false

    zle reset-prompt 2>/dev/null
}

# =============================================================================
# API Integration
# =============================================================================

_ai_fetch_suggestion() {
    local buffer="$1"

    # Debug
    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "\n[DEBUG] Fetch called for buffer='$buffer'" >&2

    # Check if gemini is available
    if ! command -v gemini &>/dev/null; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] gemini not found" >&2
        return 1
    fi

    # Don't fetch for empty or very short buffers
    [[ -z "$buffer" ]] && return 1
    [[ ${#buffer} -lt $AI_SUGGESTION_MIN_CHARS ]] && return 1

    # Generate cache key
    local cache_key=$(_ai_generate_cache_key "$buffer")

    # Check cache first
    local cached=$(_ai_get_cached_suggestion "$cache_key")
    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    # Collect context
    local context=$(_ai_collect_context)

    # Build prompt for Gemini (optimized for speed - short and direct)
    local prompt="Complete this shell command. Output ONLY the command, no explanation.

Input: $buffer
Context: $context
Command:"

    # Default model if not set
    local model="${GEMINI_MODEL:-gemini-2.0-flash-exp}"

    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Using model: $model" >&2

    # Fetch from API and filter output
    local suggestion=$(gemini --model "$model" -o text "$prompt" 2>&1 | \
        grep -v '^\[WARN\]' | \
        grep -v '^\[ERROR\]' | \
        grep -v '^Error:' | \
        grep -v '^Warning:' | \
        grep -v '^Loaded cached credentials\.' | \
        grep -v '^Loading' | \
        grep -v '^Connecting' | \
        grep -v '^Using model' | \
        grep -E '^[a-zA-Z0-9_/\.\-]' | \
        head -1 | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Got suggestion: '$suggestion'" >&2

    # Cache and return if we got a result
    if [[ -n "$suggestion" ]]; then
        _ai_set_cached_suggestion "$cache_key" "$suggestion"
        echo "$suggestion"
        return 0
    fi

    return 1
}

# =============================================================================
# Async Worker Management
# =============================================================================

# Wrapper function for async job (runs in worker)
_ai_debounced_fetch() {
    local buffer="$1"
    sleep $AI_SUGGESTION_DEBOUNCE_TIME
    _ai_fetch_suggestion "$buffer"
}

_ai_async_callback() {
    local job="$1"
    local return_code="$2"
    local suggestion="$3"
    local exec_time="$4"
    local error="$5"
    local next_call="$6"

    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Async callback: job=$job, code=$return_code, suggestion='$suggestion'" >&2

    # Stop spinner
    _ai_stop_spinner

    # Handle errors
    if [[ $return_code -ne 0 ]] || [[ -z "$suggestion" ]]; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] No suggestion or error" >&2
        return
    fi

    # Store suggestion
    _AI_CURRENT_SUGGESTION="$suggestion"
    _AI_DISPLAY_VISIBLE=true

    # Display suggestion below prompt
    # \e[A moves cursor up one line to return to the command line
    print -P "\n%F{${AI_SUGGESTION_COLOR}}💡 Suggestion: ${suggestion}%f\e[A"

    # Force ZLE refresh
    zle && zle -R
}

# Initialize async worker
_ai_init_worker() {
    async_start_worker ai_suggestions -u -n
    async_register_callback ai_suggestions _ai_async_callback

    # Register helper functions in the worker environment
    # This ensures the worker can call these functions
    async_worker_eval ai_suggestions "$(typeset -f _ai_collect_context)"
    async_worker_eval ai_suggestions "$(typeset -f _ai_generate_cache_key)"
    async_worker_eval ai_suggestions "$(typeset -f _ai_get_cached_suggestion)"
    async_worker_eval ai_suggestions "$(typeset -f _ai_set_cached_suggestion)"
    async_worker_eval ai_suggestions "$(typeset -f _ai_fetch_suggestion)"
    async_worker_eval ai_suggestions "$(typeset -f _ai_debounced_fetch)"

    # Export configuration and cache to worker
    async_worker_eval ai_suggestions "typeset -gA _AI_CACHE"
    async_worker_eval ai_suggestions "typeset -gA _AI_CACHE_TIME"
    async_worker_eval ai_suggestions "typeset -gi AI_SUGGESTION_CACHE_TTL=$AI_SUGGESTION_CACHE_TTL"
    async_worker_eval ai_suggestions "typeset -gi AI_SUGGESTION_MIN_CHARS=$AI_SUGGESTION_MIN_CHARS"
    async_worker_eval ai_suggestions "typeset -gi AI_SUGGESTION_DEBOUNCE_TIME=$AI_SUGGESTION_DEBOUNCE_TIME"
    async_worker_eval ai_suggestions "export GEMINI_MODEL='${GEMINI_MODEL:-gemini-2.0-flash-exp}'"
    async_worker_eval ai_suggestions "export AI_DEBUG='${AI_DEBUG:-false}'"
}

# =============================================================================
# Debounce Logic
# =============================================================================

_ai_schedule_suggestion() {
    local buffer="$BUFFER"

    # Don't schedule if buffer hasn't changed
    [[ "$buffer" == "$_AI_LAST_BUFFER" ]] && return
    _AI_LAST_BUFFER="$buffer"

    # Cancel any pending jobs
    async_flush_jobs ai_suggestions 2>/dev/null

    # Don't schedule for very short buffers (and clear any existing suggestion)
    if [[ ${#buffer} -lt $AI_SUGGESTION_MIN_CHARS ]]; then
        _ai_clear_display
        return
    fi

    # Start spinner immediately
    _ai_start_spinner

    # Schedule async job with debounce
    # The sleep happens in the worker, so it doesn't block the main shell
    # We use a wrapper to properly handle the debounce + fetch
    async_job ai_suggestions _ai_debounced_fetch "$buffer"
}

# =============================================================================
# Widget Handlers
# =============================================================================

_ai_accept_suggestion() {
    if [[ -n "$_AI_CURRENT_SUGGESTION" ]]; then
        # Accept the suggestion
        BUFFER="$_AI_CURRENT_SUGGESTION"
        CURSOR=${#BUFFER}  # Move cursor to end

        # Clear state
        _AI_CURRENT_SUGGESTION=""
        _AI_DISPLAY_VISIBLE=false

        # Refresh
        zle reset-prompt
    else
        # No suggestion - expand-or-complete (Tab behavior)
        zle expand-or-complete
    fi
}

# Hook function called before each line redraw
_ai_on_line_pre_redraw() {
    # Don't trigger on empty buffer (happens on Ctrl+C, Enter, etc.)
    [[ -z "$BUFFER" ]] && return

    # Reset navigation mode if buffer is being edited (user typing)
    if [[ "$_AI_NAVIGATION_MODE" == "true" ]]; then
        # Check if buffer changed from last recorded state (user started typing)
        if [[ -n "$_AI_LAST_BUFFER" ]] && [[ "$BUFFER" != "$_AI_LAST_BUFFER" ]]; then
            [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Buffer edited, exiting navigation mode" >&2
            _AI_NAVIGATION_MODE=false
        else
            # Still in navigation, skip AI suggestions
            return
        fi
    fi

    # Clear display if buffer changed significantly (not just appended)
    if [[ -n "$_AI_CURRENT_SUGGESTION" ]] && [[ -n "$_AI_LAST_BUFFER" ]]; then
        # Check if current buffer is NOT a prefix of last buffer (user edited/deleted)
        if [[ "$BUFFER" != "$_AI_LAST_BUFFER"* ]]; then
            [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Buffer changed, clearing display" >&2
            _ai_clear_display
        fi
    fi

    # Schedule suggestion request (debounced)
    _ai_schedule_suggestion
}

# Navigation wrappers to clear AI during history navigation
_ai_up_line_wrapper() {
    # Clear AI suggestions before navigating
    _ai_clear_display
    _AI_NAVIGATION_MODE=true

    # Call original widget
    zle up-line-or-beginning-search
}

_ai_down_line_wrapper() {
    # Clear AI suggestions before navigating
    _ai_clear_display
    _AI_NAVIGATION_MODE=true

    # Call original widget
    zle down-line-or-beginning-search
}

# =============================================================================
# Widget Registration
# =============================================================================

# Register custom widget for accepting suggestions
zle -N ai-accept-suggestion _ai_accept_suggestion

# Register navigation wrappers
zle -N ai-up-line _ai_up_line_wrapper
zle -N ai-down-line _ai_down_line_wrapper

# Keybindings: Up/Down for history navigation, Tab for accepting AI
bindkey '^[[A' ai-up-line      # Up arrow
bindkey '^[[B' ai-down-line    # Down arrow
bindkey '^P' ai-up-line        # Ctrl+P
bindkey '^N' ai-down-line      # Ctrl+N

# Tab to accept AI suggestions (classic autocomplete key)
bindkey '^I' ai-accept-suggestion  # Tab

# Register the line-pre-redraw hook to detect buffer changes
autoload -U add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _ai_on_line_pre_redraw

# =============================================================================
# Hooks
# =============================================================================

# Clear suggestion when changing directories
_ai_chpwd() {
    _ai_clear_display
    _AI_LAST_BUFFER=""
}

# Clear suggestion before command execution
_ai_preexec() {
    # Clear display IMMEDIATELY before command execution
    _ai_clear_display
    _AI_DISPLAY_VISIBLE=false

    # Cancel any pending async jobs
    async_flush_jobs ai_suggestions 2>/dev/null

    # Reset all state
    _AI_CURRENT_SUGGESTION=""
    _AI_LAST_BUFFER=""
    _AI_NAVIGATION_MODE=false
}

# Update context before showing prompt (optional)
_ai_precmd() {
    # Could refresh context here if needed
    :
}

# Cleanup on shell exit
_ai_zshexit() {
    # Stop async worker
    async_stop_worker ai_suggestions 2>/dev/null
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _ai_chpwd
add-zsh-hook preexec _ai_preexec
add-zsh-hook precmd _ai_precmd
add-zsh-hook zshexit _ai_zshexit

# =============================================================================
# Initialization
# =============================================================================

# Initialize async worker
_ai_init_worker

# =============================================================================
# Help
# =============================================================================

ai_suggestions_help() {
    /bin/cat <<'EOF'
AI Command Suggestions (Nivuus Shell)

As you type, intelligent command suggestions appear below your prompt
after a 2-second delay.

Keybindings:
  Tab             - Accept and use the suggestion
  Any key         - Continue typing (suggestion updates)

Features:
  • Context-aware: Uses directory, git status, recent history
  • Cached: Fast responses for similar queries (5 min TTL)
  • Nord theme: Suggestions in dim gray (Nord3)
  • Async: Non-blocking via zsh-async

Configuration:
  Debounce: 2 seconds
  Min chars: 3
  Cache TTL: 5 minutes
  Color: Nord3 (fg=240)

Enable/Disable:
  export ENABLE_AI_SUGGESTIONS=true   # Enable
  export ENABLE_AI_SUGGESTIONS=false  # Disable
  source ~/.zshrc                      # Apply changes

Performance:
  • Uses cache to minimize API calls
  • Async requests don't block typing (zsh-async)
  • Skips very short inputs

EOF
}
