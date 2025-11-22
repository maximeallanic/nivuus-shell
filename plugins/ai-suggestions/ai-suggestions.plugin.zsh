#!/usr/bin/env zsh
# =============================================================================
# AI Command Suggestions - Gemini Integration
# =============================================================================
# Real-time intelligent command suggestions with 2s debounce
# =============================================================================

# Only load once
[[ -n "${NIVUUS_AI_SUGGESTIONS_LOADED}" ]] && return
export NIVUUS_AI_SUGGESTIONS_LOADED=1

# Skip if explicitly disabled
[[ "${ENABLE_AI_SUGGESTIONS:-false}" != "true" ]] && return

# =============================================================================
# Cleanup Old Temp Files
# =============================================================================

# Clean up orphaned temp files from crashed/killed shells
# Only remove files older than 1 hour that don't belong to current PID
{
    find /tmp -maxdepth 1 -name 'nivuus-ai-*' -mmin +60 -type f 2>/dev/null | \
    grep -v "$$" | \
    xargs rm -f 2>/dev/null
} &>/dev/null &!

# =============================================================================
# Configuration
# =============================================================================

typeset -gi AI_SUGGESTION_DEBOUNCE_TIME=2     # seconds
typeset -gi AI_SUGGESTION_CACHE_TTL=300       # 5 minutes
typeset -gi AI_SUGGESTION_MIN_CHARS=3         # Min buffer length
typeset -gi AI_SUGGESTION_SPINNER_TIMEOUT=5   # Max spinner duration (seconds)
typeset -g AI_SUGGESTION_COLOR='240'          # Nord3 dim gray
typeset -g AI_SUGGESTION_INDENT='> '          # Indent prefix (configure to match your prompt)

# =============================================================================
# Dependencies
# =============================================================================

# No special dependencies needed (background jobs are built-in)

# =============================================================================
# State Management
# =============================================================================

typeset -g _AI_CURRENT_SUGGESTION=""
typeset -g _AI_PENDING_SUGGESTION=""
typeset -g _AI_PENDING_POSTDISPLAY=""
typeset -g _AI_DISPLAY_VISIBLE=false
typeset -gA _AI_CACHE
typeset -gA _AI_CACHE_TIME
typeset -g _AI_SUGGESTION_PID=""
typeset -g _AI_SPINNER_PID=""
typeset -g _AI_LAST_BUFFER=""
typeset -g _AI_SUGGESTION_PIPE="/tmp/nivuus-ai-suggestion-$$"
typeset -gi _AI_UPDATES_PENDING=0
typeset -gi _AI_ALARM_ACTIVE=0
typeset -g _AI_NAVIGATION_MODE=false
typeset -g _AI_SPINNER_START_TIME=""

# Spinner animation frames (Braille dots)
typeset -ga _AI_SPINNER_FRAMES
_AI_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

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

    # Skip heavy operations like tree for faster responses
    # Uncomment below if you want directory structure (slower but more context)
    # if command -v tree &>/dev/null; then
    #     local tree_output=$(tree -L 1 -a -I '.git|node_modules' --noreport 2>/dev/null | head -10)
    #     [[ -n "$tree_output" ]] && context+="Files:\n$tree_output\n"
    # fi

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

_ai_get_prompt_width() {
    # Calculate visual width of the prompt
    # Use RPROMPT if available, otherwise expand PROMPT
    local prompt_text="${PROMPT}"

    # Expand prompt sequences
    local prompt_expanded="${(%)prompt_text}"

    # Strip all ANSI and ZSH prompt codes
    # Remove %{...%} blocks (ZSH invisible sequences)
    local prompt_plain="${prompt_expanded//\%\{*\%\}/}"
    # Remove ESC[...m (color codes)
    prompt_plain="${prompt_plain//$'\e'\[[0-9;]#m/}"
    # Remove ESC[...~ (other sequences)
    prompt_plain="${prompt_plain//$'\e'\[[0-9]#~/}"
    # Remove other ESC sequences
    prompt_plain="${prompt_plain//$'\e'\[*\]/}"

    # Return the visual width
    local width="${#prompt_plain}"

    # Debug output (always show for now to help debug alignment)
    echo "[DEBUG] Prompt width calculation:" >&2
    echo "[DEBUG]   Expanded: '$prompt_expanded'" >&2
    echo "[DEBUG]   Plain: '$prompt_plain'" >&2
    echo "[DEBUG]   Width: $width" >&2

    echo "$width"
}

_ai_start_spinner() {
    # Start animated spinner in background
    local spinner_file="/tmp/nivuus-ai-spinner-$$"
    local parent_pid=$$

    # Record start time for timeout detection
    _AI_SPINNER_START_TIME=$EPOCHSECONDS

    {
        local frame_index=0
        local num_frames=${#_AI_SPINNER_FRAMES[@]}

        while true; do
            local spinner_char="${_AI_SPINNER_FRAMES[$((frame_index % num_frames))]}"

            # Write current frame to file
            echo "$spinner_char" > "$spinner_file"

            # Signal parent to update display
            kill -USR1 $parent_pid 2>/dev/null

            frame_index=$((frame_index + 1))
            sleep 0.1  # Update every 100ms
        done
    } &!

    _AI_SPINNER_PID=$!
}

_ai_stop_spinner() {
    if [[ -n "$_AI_SPINNER_PID" ]]; then
        kill $_AI_SPINNER_PID 2>/dev/null
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Stopped spinner PID=$_AI_SPINNER_PID" >&2
        _AI_SPINNER_PID=""

        # Clean up spinner file
        rm -f "/tmp/nivuus-ai-spinner-$$"
    fi

    # Clear start time
    _AI_SPINNER_START_TIME=""
}

_ai_clear_display() {
    # Clear even if not visible (aggressive cleanup)
    if [[ "$_AI_DISPLAY_VISIBLE" == "true" ]] || [[ -n "$RPROMPT" ]]; then
        # Debug
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Clearing display" >&2

        # Stop spinner if running
        _ai_stop_spinner

        # Clear RPROMPT
        RPROMPT=""

        # Refresh display
        zle reset-prompt 2>/dev/null

        # Update state
        _AI_CURRENT_SUGGESTION=""
        _AI_DISPLAY_VISIBLE=false
        _AI_PENDING_POSTDISPLAY=""
    fi
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
        return
    fi

    # Don't fetch for empty or very short buffers
    [[ -z "$buffer" ]] && return
    [[ ${#buffer} -lt $AI_SUGGESTION_MIN_CHARS ]] && return

    # Generate cache key
    local cache_key=$(_ai_generate_cache_key "$buffer")

    # Check cache first
    local cached=$(_ai_get_cached_suggestion "$cache_key")
    if [[ -n "$cached" ]]; then
        # Write to temp file for widget to read
        echo "$cached" > "$_AI_SUGGESTION_PIPE"
        # Trigger display widget via signal
        kill -USR1 $$
        return
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

    # Fetch from API (in background to not block)
    local suggestion_pipe="$_AI_SUGGESTION_PIPE"
    local parent_pid=$$
    {
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Starting background fetch..." >&2
        # Filter out warnings/errors/status messages and get first actual suggestion
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

        # Cache and write to file if we got a result
        if [[ -n "$suggestion" ]]; then
            _ai_set_cached_suggestion "$cache_key" "$suggestion"
            # Write to temp file for hook to pick up
            [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Writing suggestion to: $suggestion_pipe" >&2
            echo "$suggestion" > "$suggestion_pipe"
            [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Sending USR1 to PID: $parent_pid" >&2
            # Trigger display by sending signal
            kill -USR1 $parent_pid 2>/dev/null
        fi
    } &!
}

# =============================================================================
# Debounce Logic
# =============================================================================

_ai_schedule_suggestion() {
    local buffer="$BUFFER"

    # Don't schedule if buffer hasn't changed
    [[ "$buffer" == "$_AI_LAST_BUFFER" ]] && return
    _AI_LAST_BUFFER="$buffer"

    # Kill previous background job
    if [[ -n "$_AI_SUGGESTION_PID" ]]; then
        kill $_AI_SUGGESTION_PID 2>/dev/null
        _AI_SUGGESTION_PID=""
    fi

    # Don't schedule for very short buffers (and clear any existing suggestion)
    if [[ ${#buffer} -lt $AI_SUGGESTION_MIN_CHARS ]]; then
        _ai_clear_display
        return
    fi

    # Start new background job with sleep
    local parent_pid=$$
    {
        sleep $AI_SUGGESTION_DEBOUNCE_TIME

        # Create marker file to trigger spinner
        echo "start_spinner" > "/tmp/nivuus-ai-start-spinner-$$"
        kill -USR1 $parent_pid 2>/dev/null

        # Fetch suggestion
        _ai_fetch_suggestion "$buffer"
    } &!

    _AI_SUGGESTION_PID=$!
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

        # Clear RPROMPT explicitly
        RPROMPT=""

        # Refresh
        zle reset-prompt
    else
        # No suggestion - expand-or-complete (Tab behavior)
        zle expand-or-complete
    fi
}

# Widget to update POSTDISPLAY (called from TRAPUSR1)
_ai_update_display_widget() {
    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] ai-update-display called, POSTDISPLAY='$POSTDISPLAY', PENDING='$_AI_PENDING_POSTDISPLAY'" >&2

    # Check for conflict with other plugins
    if [[ -n "$POSTDISPLAY" ]] && [[ ! "$POSTDISPLAY" =~ ^$'\n' ]]; then
        # Another plugin owns POSTDISPLAY, don't interfere
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] POSTDISPLAY conflict detected, skipping" >&2
        return
    fi

    # Update POSTDISPLAY with pending content
    if [[ -n "$_AI_PENDING_POSTDISPLAY" ]]; then
        POSTDISPLAY="$_AI_PENDING_POSTDISPLAY"
        _AI_PENDING_POSTDISPLAY=""
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] POSTDISPLAY updated" >&2
        zle -R 2>/dev/null
    fi
}

# Hook function called before each line redraw
_ai_on_line_pre_redraw() {
    # Update POSTDISPLAY if there's pending content from TRAPUSR1
    if [[ -n "$_AI_PENDING_POSTDISPLAY" ]]; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Applying pending POSTDISPLAY from hook" >&2
        POSTDISPLAY="$_AI_PENDING_POSTDISPLAY"
        _AI_PENDING_POSTDISPLAY=""
        _AI_DISPLAY_VISIBLE=true
    fi

    # Don't trigger on empty buffer (happens on Ctrl+C, Enter, etc.)
    [[ -z "$BUFFER" ]] && return

    # Reset navigation mode if buffer is being edited (user typing)
    # This allows AI suggestions to resume after navigating history
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

# Widget to reset navigation mode (called on buffer edit)
_ai_reset_navigation() {
    _AI_NAVIGATION_MODE=false
}

# =============================================================================
# Widget Registration
# =============================================================================

# Register custom widget for accepting suggestions
zle -N ai-accept-suggestion _ai_accept_suggestion

# Register widget for updating display from TRAPUSR1
zle -N ai-update-display _ai_update_display_widget

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

# Trap USR1 to update POSTDISPLAY
TRAPUSR1() {
    [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] TRAPUSR1 called" >&2

    # Skip if ZLE not active
    if [[ ! -o ZLE ]]; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] ZLE not active, skipping" >&2
        return
    fi

    # Check for suggestion FIRST (higher priority than spinner)
    if [[ -f "$_AI_SUGGESTION_PIPE" ]]; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Found suggestion file" >&2
        local suggestion=$(<"$_AI_SUGGESTION_PIPE")
        rm -f "$_AI_SUGGESTION_PIPE"

        if [[ -n "$suggestion" ]]; then
            [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Got suggestion: '$suggestion'" >&2
            _ai_stop_spinner

            # Store suggestion
            _AI_CURRENT_SUGGESTION="$suggestion"
            _AI_DISPLAY_VISIBLE=true

            # Simple approach: echo above and move cursor back
            # \e[A moves cursor up one line to return to the command line
            print -P "\n%F{${AI_SUGGESTION_COLOR}}💡 Suggestion: ${suggestion}%f\e[A"

            # Force ZLE to refresh so the prompt is interactive again
            zle && zle -R
        fi
        return
    fi

    # Check for spinner marker to start spinner
    local start_spinner_file="/tmp/nivuus-ai-start-spinner-$$"
    if [[ -f "$start_spinner_file" ]]; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Starting spinner" >&2
        rm -f "$start_spinner_file"
        _ai_start_spinner
        return
    fi

    # Check for spinner update
    local spinner_file="/tmp/nivuus-ai-spinner-$$"
    if [[ -f "$spinner_file" ]]; then
        [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Updating spinner" >&2
        # Check spinner timeout
        if [[ -n "$_AI_SPINNER_START_TIME" ]]; then
            local elapsed=$(( EPOCHSECONDS - _AI_SPINNER_START_TIME ))
            if (( elapsed > AI_SUGGESTION_SPINNER_TIMEOUT )); then
                [[ "${AI_DEBUG:-false}" == "true" ]] && echo "[DEBUG] Spinner timeout after ${elapsed}s" >&2
                _ai_stop_spinner
                _ai_clear_display
                return
            fi
        fi

        local spinner_char=$(<"$spinner_file")

        # Display spinner in RPROMPT
        RPROMPT="%F{${AI_SUGGESTION_COLOR}}${spinner_char}%f"

        # Just refresh display (don't redraw prompt)
        zle -R 2>/dev/null
        return
    fi
}

# Trap SIGINT (Ctrl+C) to clean up properly
TRAPINT() {
    # Stop any running background jobs
    if [[ -n "$_AI_SUGGESTION_PID" ]]; then
        kill $_AI_SUGGESTION_PID 2>/dev/null
        _AI_SUGGESTION_PID=""
    fi
    _ai_stop_spinner

    # Clean up marker files
    rm -f "/tmp/nivuus-ai-start-spinner-$$"
    rm -f "$_AI_SUGGESTION_PIPE"

    # Return default SIGINT behavior
    return $(( 128 + 2 ))
}

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

    # Kill any running background job
    if [[ -n "$_AI_SUGGESTION_PID" ]]; then
        kill $_AI_SUGGESTION_PID 2>/dev/null
        _AI_SUGGESTION_PID=""
    fi

    # Stop spinner
    _ai_stop_spinner

    # Reset all state
    _AI_CURRENT_SUGGESTION=""
    _AI_LAST_BUFFER=""
    _AI_NAVIGATION_MODE=false
    _AI_PENDING_POSTDISPLAY=""
}

# Update context before showing prompt (optional)
_ai_precmd() {
    # Could refresh context here if needed
    :
}

# Cleanup on shell exit
_ai_zshexit() {
    _ai_stop_spinner
    # Clean up all temp files for this PID
    rm -f "/tmp/nivuus-ai-"*"-$$" 2>/dev/null
    rm -f "$_AI_SUGGESTION_PIPE" 2>/dev/null
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _ai_chpwd
add-zsh-hook preexec _ai_preexec
add-zsh-hook precmd _ai_precmd
add-zsh-hook zshexit _ai_zshexit

# =============================================================================
# Help
# =============================================================================

ai_suggestions_help() {
    /bin/cat <<'EOF'
AI Command Suggestions (Nivuus Shell)

As you type, intelligent command suggestions appear below your prompt
after a 2-second delay.

Keybindings:
  ↓ (Down Arrow)  - Accept and use the suggestion
  Any key         - Continue typing (suggestion updates)

Features:
  • Context-aware: Uses directory, git status, recent history
  • Cached: Fast responses for similar queries (5 min TTL)
  • Nord theme: Suggestions in dim gray (Nord3)

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
  • Async requests don't block typing
  • Skips very short inputs

EOF
}
