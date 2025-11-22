#!/usr/bin/env zsh
# =============================================================================
# AI Command Suggestions - Compact Interactive Menu
# =============================================================================

# Only load once
[[ -n "${NIVUUS_AI_SUGGESTIONS_LOADED}" ]] && return
export NIVUUS_AI_SUGGESTIONS_LOADED=1

# Skip if explicitly disabled
[[ "${ENABLE_AI_SUGGESTIONS:-true}" != "true" ]] && return

# Don't check for gemini at load time (NVM loads lazily)
# We'll check at execution time instead

# =============================================================================
# Configuration
# =============================================================================

typeset -g AI_SUGGESTION_MIN_CHARS="${AI_SUGGESTION_MIN_CHARS:-3}"
typeset -g AI_DEBOUNCE_DELAY="${AI_DEBOUNCE_DELAY:-2}"  # Debounce delay in seconds
typeset -g ENABLE_AI_AUTO_DEBOUNCE="${ENABLE_AI_AUTO_DEBOUNCE:-false}"  # Auto-trigger after typing

# Cache
typeset -gA _AI_CACHE
typeset -gA _AI_CACHE_TIME

# Current inline suggestion
typeset -g _AI_CURRENT_SUGGESTION=""

# Animation state
typeset -g _AI_ANIMATION_DOTS=1

# Current generation process PID
typeset -g _AI_GENERATE_PID=""

# =============================================================================
# Context Collection
# =============================================================================

_ai_get_context() {
    local context=""

    # Working directory
    context+="Dir: $PWD\n"

    # ALL files in current directory (limited to 50 to avoid huge repos)
    local files=$(ls -1 2>/dev/null | head -50 | tr '\n' ', ' | sed 's/,$//')
    [[ -n "$files" ]] && context+="Files (all): $files\n"

    # Recent command history (last 20 commands)
    local hist=$(fc -ln -25 2>/dev/null | sed 's/^[[:space:]]*//' | grep -v "^$" | tail -20 | tr '\n' ';')
    [[ -n "$hist" ]] && context+="Recent commands: $hist\n"

    # Environment variables
    context+="User: $USER\n"
    context+="Shell: $SHELL\n"
    context+="Home: $HOME\n"

    # Full PATH (truncated if too long)
    local path_truncated=$(echo "$PATH" | cut -c1-200)
    [[ ${#PATH} -gt 200 ]] && path_truncated="$path_truncated..."
    context+="PATH: $path_truncated\n"

    # Project type detection with file contents
    if [[ -f "package.json" ]]; then
        context+="Project: Node.js\n"
        local pkg_scripts=$(grep -A20 '"scripts"' package.json 2>/dev/null | head -25)
        [[ -n "$pkg_scripts" ]] && context+="package.json scripts:\n$pkg_scripts\n"
    fi

    if [[ -f "go.mod" ]]; then
        context+="Project: Go\n"
        local go_content=$(head -15 go.mod 2>/dev/null)
        [[ -n "$go_content" ]] && context+="go.mod:\n$go_content\n"
    fi

    if [[ -f "Cargo.toml" ]]; then
        context+="Project: Rust\n"
        local cargo_content=$(head -20 Cargo.toml 2>/dev/null)
        [[ -n "$cargo_content" ]] && context+="Cargo.toml:\n$cargo_content\n"
    fi

    if [[ -f "requirements.txt" ]]; then
        context+="Project: Python\n"
        local req_content=$(head -15 requirements.txt 2>/dev/null)
        [[ -n "$req_content" ]] && context+="requirements.txt:\n$req_content\n"
    fi

    # README preview
    if [[ -f "README.md" ]]; then
        local readme_preview=$(head -20 README.md 2>/dev/null)
        [[ -n "$readme_preview" ]] && context+="README.md preview:\n$readme_preview\n"
    fi

    # Git detailed status with diff
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        [[ -n "$branch" ]] && context+="Git branch: $branch\n"

        # Full git status
        local git_status=$(git status --short 2>/dev/null | head -30)
        [[ -n "$git_status" ]] && context+="Git status:\n$git_status\n"

        # Git diff of modified files (limited to 100 lines)
        local git_diff=$(git diff 2>/dev/null | head -100)
        [[ -n "$git_diff" ]] && context+="Git diff (first 100 lines):\n$git_diff\n"
    fi

    echo "$context"
}

# =============================================================================
# Generate AI Suggestions
# =============================================================================

_ai_generate() {
    local prefix="$1"
    local cache_key="${prefix}_${PWD}"

    # Find gemini at execution time (in case NVM loaded after module load)
    local gemini_cmd
    if command -v gemini &>/dev/null; then
        gemini_cmd="$(command -v gemini)"
    else
        # Try common NVM paths
        for nvm_path in ~/.nvm/versions/node/*/bin/gemini; do
            if [[ -x "$nvm_path" ]]; then
                gemini_cmd="$nvm_path"
                break
            fi
        done
    fi

    # No gemini found
    if [[ -z "$gemini_cmd" ]]; then
        echo "ERROR: gemini not found" >&2
        return 1
    fi

    # Check cache (5min TTL)
    if [[ -n "${_AI_CACHE_TIME[$cache_key]}" ]]; then
        local age=$(( EPOCHSECONDS - _AI_CACHE_TIME[$cache_key] ))
        if (( age < 300 )); then
            echo "${_AI_CACHE[$cache_key]}"
            return
        fi
    fi

    # Inline mode always generates 1 suggestion for speed
    local num_suggestions=1

    local context=$(_ai_get_context)
    local prompt="You are an expert shell command completion assistant with FULL context visibility. Analyze the rich context below and generate ${num_suggestions} highly relevant, executable command.

CRITICAL OUTPUT RULES - FOLLOW EXACTLY:
- Output ONLY raw executable shell commands (bash/zsh)
- ONE command per line
- NO markdown code blocks (no \`\`\`), NO backticks, NO formatting
- NO explanations, NO numbering, NO bullets, NO prefixes
- NO text before or after commands
- Each line must be a raw command that can be copy-pasted to terminal
- Example correct output:
  git status
  ls -lah
  cd /tmp

CONTEXT ANALYSIS STRATEGY:
You have access to extensive context - USE IT INTELLIGENTLY:
- Files: ALL files in directory (reference specific files when relevant)
- Git diff: See EXACT changes to suggest precise git commands
- Project files: package.json scripts, dependencies, build configs
- README: Project documentation and usage hints
- Command history: Recent workflow patterns (last 20 commands)
- Environment: Full PATH, user, shell environment

SMART SUGGESTIONS:
- For git commands: analyze the diff and status to suggest specific files/hunks
- For project commands: use package.json scripts, Makefile targets, cargo commands
- For file operations: reference actual files that exist
- For history-based: continue the workflow pattern from recent commands

FULL CONTEXT:
$context

User input to complete: $prefix

Generate ${num_suggestions} most relevant commands:"

    local result=$("$gemini_cmd" --model "${GEMINI_MODEL:-gemini-2.0-flash}" -o text "$prompt" 2>&1 | \
        grep -v '^\[' | \
        grep -v '^Loaded' | \
        grep -v '^Cached' | \
        grep -v '^```' | \
        sed 's/^[0-9]*\.\s*//' | \
        sed 's/^-\s*//' | \
        sed 's/^[\*]\s*//' | \
        sed 's/^`\(.*\)`$/\1/' | \
        grep -v '^[[:space:]]*$' | \
        grep -v -iE '^(explanation|example|correct|output|translate|generate|here|the|this|that|rules|commands|input):' | \
        grep -E '^[a-zA-Z0-9_/\.\-\$\{\}]' | \
        head -${num_suggestions})

    if [[ -n "$result" ]]; then
        _AI_CACHE[$cache_key]="$result"
        _AI_CACHE_TIME[$cache_key]="$EPOCHSECONDS"
    fi

    echo "$result"
}


# =============================================================================
# Loading Animation
# =============================================================================

_ai_animate_dots() {
    # Stop if no active generation
    if [[ -z "$_AI_GENERATE_PID" ]]; then
        return
    fi

    # Cycle through 1, 2, 3 dots
    (( _AI_ANIMATION_DOTS = (_AI_ANIMATION_DOTS % 3) + 1 ))

    # Update RPROMPT with new dots
    _ai_update_loading_animation
    zle && zle reset-prompt

    # Schedule next animation frame (1 second from now)
    sched +1 _ai_animate_dots
}

_ai_cancel_animation() {
    # Cancel all scheduled animation jobs
    local -a job_ids
    local line job_num

    while IFS= read -r line; do
        if [[ "$line" == *"_ai_animate_dots"* ]]; then
            job_num=$(echo "$line" | awk '{print $1}')
            if [[ -n "$job_num" ]]; then
                job_ids+=($job_num)
            fi
        fi
    done < <(sched 2>/dev/null)

    for job_num in $job_ids; do
        sched -$job_num 2>/dev/null
    done
}

# =============================================================================
# Inline Suggestion Display (Async with POSTDISPLAY)
# =============================================================================

# Global variable for temp file (shared with async checker)
typeset -g _AI_TEMP_FILE=""
typeset -g _AI_SAVED_RPROMPT=""

_ai_show_inline() {
    local prefix="$BUFFER"

    # Cancel any pending debounce timer and animation
    _ai_cancel_debounce
    _ai_cancel_animation
    _ai_cancel_generation

    # Min chars check
    if [[ ${#prefix} -lt $AI_SUGGESTION_MIN_CHARS ]]; then
        return
    fi

    # Show loading message with Nord colors (cyan)
    # Save current RPROMPT and replace with suggestion message
    _AI_SAVED_RPROMPT="$RPROMPT"
    _AI_ANIMATION_DOTS=1
    _ai_update_loading_animation
    zle reset-prompt

    # Start animation (updates every 0.5 seconds)
    sched +1 _ai_animate_dots

    # Generate in background with SIGUSR1 notification
    _AI_TEMP_FILE=$(mktemp)

    # Generate in background and signal when done
    {
        _ai_generate "$prefix" 2>&1 | head -1 > "$_AI_TEMP_FILE"
        # Send SIGUSR1 to parent shell to trigger update
        kill -USR1 $$ 2>/dev/null
    } &!
    _AI_GENERATE_PID=$!
}

# Update loading animation in RPROMPT
_ai_update_loading_animation() {
    local dots=""
    case $_AI_ANIMATION_DOTS in
        1) dots=".  " ;;  # 1 dot + 2 spaces
        2) dots=".. " ;;  # 2 dots + 1 space
        3) dots="..." ;;  # 3 dots + 0 space
    esac
    RPROMPT="%F{110}🤖 Generating${dots} (Enter to cancel)%f"
}

# Called by TRAPUSR1 when generation completes
_ai_handle_completion() {
    # Cancel animation first
    _ai_cancel_animation

    # Get result
    local suggestion=""
    if [[ -f "$_AI_TEMP_FILE" ]]; then
        suggestion=$(cat "$_AI_TEMP_FILE" 2>/dev/null)
        rm -f "$_AI_TEMP_FILE"
    fi
    _AI_TEMP_FILE=""
    _AI_GENERATE_PID=""

    # Check for errors
    if [[ "$suggestion" == ERROR:* ]] || [[ -z "$suggestion" ]]; then
        suggestion=""
    fi

    # Store suggestion
    _AI_CURRENT_SUGGESTION="$suggestion"

    # Display result with Nord colors
    if [[ -n "$suggestion" ]]; then
        # Green for suggestion, light gray for instruction
        RPROMPT="%F{143}🤖 $suggestion%F{254} (Ctrl+↓)%f"
    else
        # Restore original RPROMPT
        RPROMPT="$_AI_SAVED_RPROMPT"
    fi

    # Force prompt redraw
    zle && zle reset-prompt
}

# Register ZLE widget for completion handler
zle -N _ai_handle_completion

# Trap SIGUSR1 to handle completion
TRAPUSR1() {
    # Call the completion handler widget if we're in ZLE
    zle && zle _ai_handle_completion
}

_ai_accept_inline() {
    # Accept the AI suggestion if present
    if [[ -n "$_AI_CURRENT_SUGGESTION" ]]; then
        BUFFER="$_AI_CURRENT_SUGGESTION"
        CURSOR=${#BUFFER}
        _AI_CURRENT_SUGGESTION=""
        # Restore original RPROMPT
        RPROMPT="$_AI_SAVED_RPROMPT"
        zle reset-prompt
    fi
}

_ai_clear_inline() {
    _AI_CURRENT_SUGGESTION=""
    # Restore original RPROMPT
    RPROMPT="$_AI_SAVED_RPROMPT"
    zle reset-prompt
}

# Cancel any ongoing generation
_ai_cancel_generation() {
    # Kill the generation process if it's running
    if [[ -n "$_AI_GENERATE_PID" ]]; then
        kill $_AI_GENERATE_PID 2>/dev/null
        wait $_AI_GENERATE_PID 2>/dev/null
        _AI_GENERATE_PID=""
    fi

    # Cleanup temp files
    if [[ -n "$_AI_TEMP_FILE" ]]; then
        rm -f "$_AI_TEMP_FILE"
        _AI_TEMP_FILE=""
    fi

    # Restore original RPROMPT
    if [[ -n "$_AI_SAVED_RPROMPT" ]]; then
        RPROMPT="$_AI_SAVED_RPROMPT"
        zle reset-prompt 2>/dev/null
    fi

    # Clear current suggestion
    _AI_CURRENT_SUGGESTION=""

    # Cancel any scheduled animations
    _ai_cancel_animation
}


# =============================================================================
# Debounce System (using zsh/sched)
# =============================================================================

# Load scheduling module
zmodload zsh/sched 2>/dev/null

_ai_cancel_debounce() {
    # Get list of scheduled jobs and their IDs
    local -a job_ids
    local line job_num

    # Parse sched output to find our trigger jobs
    while IFS= read -r line; do
        if [[ "$line" == *"_ai_debounce_trigger"* ]]; then
            # Extract job number (first field, strip leading spaces)
            job_num=$(echo "$line" | awk '{print $1}')
            if [[ -n "$job_num" ]]; then
                job_ids+=($job_num)
            fi
        fi
    done < <(sched 2>/dev/null)

    # Cancel all found jobs
    for job_num in $job_ids; do
        sched -$job_num 2>/dev/null
    done
}

_ai_debounce_trigger() {
    # This runs after the debounce delay (scheduled via sched)
    # Call inline widget
    zle && zle ai-show-inline
}

_ai_start_debounce() {
    # Skip if auto-debounce is disabled
    [[ "${ENABLE_AI_AUTO_DEBOUNCE}" != "true" ]] && return

    # Skip if buffer is too short
    [[ ${#BUFFER} -lt $AI_SUGGESTION_MIN_CHARS ]] && return

    # Cancel any existing debounce timer
    _ai_cancel_debounce

    # Schedule the trigger function
    sched "+${AI_DEBOUNCE_DELAY}" _ai_debounce_trigger
}

# Hook into self-insert to trigger debounce on typing
_ai_debounce_self_insert() {
    # Clear any existing inline suggestion and restore RPROMPT
    _AI_CURRENT_SUGGESTION=""
    if [[ -n "$_AI_SAVED_RPROMPT" ]]; then
        RPROMPT="$_AI_SAVED_RPROMPT"
    fi

    zle .self-insert
    _ai_start_debounce
}

# Cancel debounce on accept-line (Enter)
_ai_debounce_accept_line() {
    # Cancel any pending debounce timer
    _ai_cancel_debounce

    # Cancel any ongoing AI generation
    _ai_cancel_generation

    # Execute the command in the buffer
    zle .accept-line
}

# Cancel debounce on send-break (Ctrl+C)
_ai_debounce_send_break() {
    _ai_cancel_debounce
    _ai_cancel_generation
    zle .send-break
}

# Cancel debounce on clear-screen (Ctrl+L)
_ai_debounce_clear_screen() {
    _ai_cancel_debounce
    _ai_cancel_generation
    zle .clear-screen
}

# =============================================================================
# Widget and Keybinding
# =============================================================================

# Register widgets
zle -N ai-show-inline _ai_show_inline
zle -N ai-accept-inline _ai_accept_inline
zle -N ai-clear-inline _ai_clear_inline

# Register debounce widgets (only if auto-debounce is enabled)
if [[ "${ENABLE_AI_AUTO_DEBOUNCE}" == "true" ]]; then
    zle -N self-insert _ai_debounce_self_insert
    zle -N accept-line _ai_debounce_accept_line
    zle -N send-break _ai_debounce_send_break
    zle -N clear-screen _ai_debounce_clear_screen
else
    # Even without auto-debounce, we need to cancel manual generations
    _ai_accept_line_no_debounce() {
        _ai_cancel_generation
        zle .accept-line
    }

    _ai_send_break_no_debounce() {
        _ai_cancel_generation
        zle .send-break
    }

    _ai_clear_screen_no_debounce() {
        _ai_cancel_generation
        zle .clear-screen
    }

    zle -N accept-line _ai_accept_line_no_debounce
    zle -N send-break _ai_send_break_no_debounce
    zle -N clear-screen _ai_clear_screen_no_debounce
fi

# Keybindings for inline mode
bindkey '^[[1;5B' ai-accept-inline  # Ctrl+Down - Accept AI suggestion
bindkey '^[[Z' ai-clear-inline      # Shift+Tab - Clear suggestion
bindkey '^2' ai-show-inline         # Ctrl+2 - Manual trigger
bindkey '^ ' ai-show-inline         # Ctrl+Space - Manual trigger
bindkey '^@' ai-show-inline         # Ctrl+Space (alt) - Manual trigger

# =============================================================================
# Help
# =============================================================================

ai_suggestions_help() {
    cat <<'EOF'
AI Command Suggestions - Inline Mode

How it works:
  1. Type partial command (3+ chars): git s
  2. Either wait 2 seconds (auto-debounce) or press Ctrl+2/Ctrl+Space
  3. Suggestion appears after cursor in colors: "🤖 git status (Ctrl+↓ to accept)"
  4. Press Ctrl+↓ to accept suggestion
  5. Press Enter to cancel generation and execute your typed command
  6. Continue typing to clear and reset timer

Features:
  • Nord color scheme (cyan for generating, green for suggestions)
  • NO latency - Enter key responds instantly during generation
  • Async generation - never blocks your typing
  • ULTRA-RICH context for maximum relevance
  • Automatic cleanup on typing/accepting/canceling

Context provided to AI (ultra-enriched):
  • ALL files in directory (up to 50)
  • Recent command history (last 20 commands)
  • Git status + FULL diff (100 lines)
  • Project files content (package.json scripts, go.mod, Cargo.toml, requirements.txt)
  • README.md preview (20 lines)
  • Full environment (USER, SHELL, HOME, PATH)
  • Project type detection (Node.js, Go, Rust, Python)

Configuration:
  AI_SUGGESTION_MIN_CHARS=3       # Minimum chars to trigger
  AI_DEBOUNCE_DELAY=2             # Debounce delay in seconds
  ENABLE_AI_AUTO_DEBOUNCE=false   # Auto-trigger after typing pause
  GEMINI_MODEL=<model>            # Gemini model (default: gemini-2.0-flash)

Keybindings:
  Ctrl+↓     - Accept inline AI suggestion
  Shift+Tab  - Clear inline AI suggestion
  Ctrl+2     - Trigger AI suggestion manually
  Ctrl+Space - Trigger AI suggestion manually

During generation:
  Enter      - Cancel generation and execute your command (NO LATENCY)
  Ctrl+C     - Cancel generation and return to prompt
  Ctrl+L     - Cancel generation and clear screen
  Type       - Clear suggestion and reset debounce timer

Colors (Nord palette):
  Cyan (110)       - "Generating..." message
  Green (143)      - Suggested command
  Light gray (254) - Instructions "(Ctrl+↓ to accept)"

EOF
}
