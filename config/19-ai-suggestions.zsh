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
typeset -g AI_NUM_SUGGESTIONS="${AI_NUM_SUGGESTIONS:-3}"
typeset -g AI_DEBOUNCE_DELAY="${AI_DEBOUNCE_DELAY:-2}"  # Debounce delay in seconds
typeset -g ENABLE_AI_AUTO_DEBOUNCE="${ENABLE_AI_AUTO_DEBOUNCE:-false}"  # Auto-trigger after typing
typeset -g AI_INLINE_MODE="${AI_INLINE_MODE:-true}"  # Show inline suggestion instead of menu

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

    # For inline mode, only generate 1 suggestion for speed
    local num_suggestions=${AI_NUM_SUGGESTIONS}
    if [[ "${AI_INLINE_MODE}" == "true" ]]; then
        num_suggestions=1
    fi

    local context=$(_ai_get_context)
    local prompt="You are an expert shell command completion assistant with FULL context visibility. Analyze the rich context below and generate ${num_suggestions} highly relevant, executable commands.

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
# Animated Spinner
# =============================================================================

_ai_spinner() {
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=1

    while true; do
        # Always show spinner frame (1-indexed for ZSH arrays)
        printf '\r🤖 %s Generating suggestions... (Ctrl+C to cancel)  ' "${frames[$i]}"
        sleep 0.08
        ((i++))
        # Loop back to 1 when reaching end
        [[ $i -gt ${#frames[@]} ]] && i=1
    done
}

# =============================================================================
# Loading Animation
# =============================================================================

_ai_animate_dots() {
    # Cycle through 1, 2, 3 dots
    (( _AI_ANIMATION_DOTS = (_AI_ANIMATION_DOTS % 3) + 1 ))
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
# Inline Suggestion Display
# =============================================================================

_ai_show_inline() {
    local prefix="$BUFFER"

    # Cancel any pending debounce timer and animation
    _ai_cancel_debounce
    _ai_cancel_animation

    # Min chars check
    if [[ ${#prefix} -lt $AI_SUGGESTION_MIN_CHARS ]]; then
        return
    fi

    # Calculate padding for alignment
    local clean_prompt=$(print -Pn "$PROMPT" | sed $'s/\e\\[[0-9;]*m//g')
    local prompt_length=${#clean_prompt}
    local padding_length=$((prompt_length - 3))
    [[ $padding_length -lt 0 ]] && padding_length=0
    local padding=$(printf ' %.0s' {1..$padding_length})

    # Show loading message (non-blocking)
    zle -M "${padding}🤖 Generating AI suggestion... (Enter to cancel)"
    zle -R

    # Generate in background (non-blocking)
    local temp_file=$(mktemp)
    {
        _ai_generate "$prefix" 2>&1 | head -1 > "$temp_file"
        # Signal completion by creating a marker file
        touch "${temp_file}.done"
    } &!
    _AI_GENERATE_PID=$!

    # Poll for completion with minimal intervals for responsiveness
    local max_wait=200  # 4 seconds total (200 * 0.02s)
    local count=0

    while (( count < max_wait )); do
        # Check if process finished
        if [[ -f "${temp_file}.done" ]]; then
            break
        fi

        # Check if process is still running
        if ! kill -0 $_AI_GENERATE_PID 2>/dev/null; then
            break
        fi

        # Minimal sleep (20ms) for better responsiveness
        # Note: ZLE events can't interrupt widget execution,
        # but shorter sleep means faster detection when widget restarts
        sleep 0.02
        ((count++))
    done

    # Get result
    wait $_AI_GENERATE_PID 2>/dev/null
    local suggestion=""

    if [[ -f "$temp_file" ]]; then
        suggestion=$(cat "$temp_file")
    fi

    # Cleanup
    rm -f "$temp_file" "${temp_file}.done"
    _AI_GENERATE_PID=""

    # Check for errors
    if [[ "$suggestion" == ERROR:* ]]; then
        suggestion=""
    fi

    # Store suggestion
    _AI_CURRENT_SUGGESTION="$suggestion"

    # Display result
    if [[ -n "$suggestion" ]]; then
        zle -M "${padding}🤖 $suggestion (Ctrl+↓ to accept)"
        zle -R
    else
        zle -M ""
        zle -R
    fi
}

_ai_accept_inline() {
    # Accept the AI suggestion if present
    if [[ -n "$_AI_CURRENT_SUGGESTION" ]]; then
        BUFFER="$_AI_CURRENT_SUGGESTION"
        CURSOR=${#BUFFER}
        _AI_CURRENT_SUGGESTION=""
        zle -M ""
    fi
}

_ai_clear_inline() {
    _AI_CURRENT_SUGGESTION=""
    zle -M ""
}

# Cancel any ongoing generation
_ai_cancel_generation() {
    # Kill the generation process if it's running
    if [[ -n "$_AI_GENERATE_PID" ]]; then
        kill $_AI_GENERATE_PID 2>/dev/null
        wait $_AI_GENERATE_PID 2>/dev/null
        _AI_GENERATE_PID=""
    fi

    # Clear any displayed messages
    zle -M "" 2>/dev/null

    # Clear current suggestion
    _AI_CURRENT_SUGGESTION=""

    # Cancel any scheduled animations
    _ai_cancel_animation
}

# =============================================================================
# Compact Interactive Menu
# =============================================================================

_ai_show_menu() {
    local prefix="$BUFFER"

    # Cancel any pending debounce timer immediately
    _ai_cancel_debounce

    # Min chars check
    if [[ ${#prefix} -lt $AI_SUGGESTION_MIN_CHARS ]]; then
        zle -M "Need at least ${AI_SUGGESTION_MIN_CHARS} characters"
        return
    fi

    # Move to new line and start spinner
    echo ""

    # Disable job control messages for background processes
    setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

    # Start spinner in background (disowned to avoid job messages)
    {
        _ai_spinner
    } &!
    local spinner_pid=$!

    # Generate AI suggestions in background (to allow interruption)
    local temp_file=$(mktemp)
    {
        _ai_generate "$prefix" > "$temp_file"
    } &!
    local generate_pid=$!

    # Wait for generation with ability to interrupt with Ctrl+C
    local interrupted=0
    trap "interrupted=1" INT

    while kill -0 $generate_pid 2>/dev/null; do
        if (( interrupted )); then
            # User pressed Ctrl+C - cleanup and exit
            kill $generate_pid 2>/dev/null
            kill $spinner_pid 2>/dev/null
            wait $generate_pid 2>/dev/null
            wait $spinner_pid 2>/dev/null
            printf '\r\033[K'
            rm -f "$temp_file"
            trap - INT
            zle reset-prompt
            return
        fi
        sleep 0.1
    done

    trap - INT

    # Get results
    wait $generate_pid 2>/dev/null
    local ai_output=$(cat "$temp_file")
    rm -f "$temp_file"

    # Stop spinner
    kill $spinner_pid 2>/dev/null
    wait $spinner_pid 2>/dev/null
    printf '\r\033[K'  # Clear spinner line

    # Parse suggestions
    local -a suggestions
    if [[ -n "$ai_output" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && suggestions+=("$line")
        done <<< "$ai_output"
    fi

    # No suggestions
    if (( ${#suggestions[@]} == 0 )); then
        zle -M "No suggestions found"
        return
    fi

    # Interactive menu
    local selected=1
    local key

    while true; do
        # Clear and redraw menu
        printf '\033[2J\033[H'  # Clear screen, move to top

        echo "🤖 AI Suggestions for: \033[1;36m$prefix\033[0m"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Display suggestions
        local i=1
        for suggestion in "${suggestions[@]}"; do
            if [[ $i -eq $selected ]]; then
                printf "  \033[1;32m▶ %s\033[0m\n" "$suggestion"
            else
                printf "    %s\n" "$suggestion"
            fi
            ((i++))
        done

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf "↑/↓: Navigate  Enter: Select  Q/Esc: Quit  1-3: Direct"

        # Read key silently
        local key=""
        read -s -k 1 key

        # Handle escape sequences (arrow keys)
        if [[ "$key" == $'\x1b' ]]; then
            # Read next character (could be '[' or 'O' depending on terminal)
            local c1=""
            if read -s -t 0.3 -k 1 c1 2>/dev/null; then
                if [[ "$c1" == "[" || "$c1" == "O" ]]; then
                    # Read the direction character
                    local c2=""
                    if read -s -t 0.3 -k 1 c2 2>/dev/null; then
                        case "$c2" in
                            A)
                                # Up arrow - move selection up and redraw
                                ((selected > 1)) && ((selected--))
                                continue
                                ;;
                            B)
                                # Down arrow - move selection down and redraw
                                ((selected < ${#suggestions[@]})) && ((selected++))
                                continue
                                ;;
                        esac
                    fi
                fi
            fi

            # Just Esc key or unrecognized sequence - quit
            printf '\033[2J\033[H'
            zle reset-prompt
            return
        fi

        # Handle other keys
        if [[ "$key" == $'\n' || "$key" == $'\r' ]]; then
            # Enter - select current
            BUFFER="${suggestions[$selected]}"
            CURSOR=${#BUFFER}
            printf '\033[2J\033[H'
            zle reset-prompt
            return
        elif [[ "$key" =~ ^[1-9]$ ]]; then
            # Number key - direct selection
            if [[ $key -le ${#suggestions[@]} ]]; then
                BUFFER="${suggestions[$key]}"
                CURSOR=${#BUFFER}
                printf '\033[2J\033[H'
                zle reset-prompt
                return
            fi
        elif [[ "$key" == "q" || "$key" == "Q" ]]; then
            # Q to quit
            printf '\033[2J\033[H'
            zle reset-prompt
            return
        fi
    done
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
    # Call inline or menu widget based on mode
    if [[ "${AI_INLINE_MODE}" == "true" ]]; then
        zle && zle ai-show-inline
    else
        zle && zle ai-show-menu
    fi
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
    # Clear any existing inline suggestion
    _AI_CURRENT_SUGGESTION=""
    zle -M ""

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
zle -N ai-show-menu _ai_show_menu
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

# Bind for inline mode
bindkey '^[[1;5B' ai-accept-inline  # Ctrl+Down - Accept AI suggestion
bindkey '^[[Z' ai-clear-inline      # Shift+Tab - Clear suggestion

# Bind multiple variants for manual triggering (menu mode)
bindkey '^2' ai-show-menu          # Ctrl+2
bindkey '^[[13;5~' ai-show-menu    # Ctrl+Enter
bindkey '^[^M' ai-show-menu        # Ctrl+Enter (alt)
bindkey '^ ' ai-show-menu          # Ctrl+Space
bindkey '^@' ai-show-menu          # Ctrl+Space (alt)

# =============================================================================
# Help
# =============================================================================

ai_suggestions_help() {
    cat <<'EOF'
AI Command Suggestions - Inline & Interactive Modes

Mode 1: Inline (Default with Auto-Debounce)
  Enable: export ENABLE_AI_AUTO_DEBOUNCE=true
          export AI_INLINE_MODE=true
  1. Type partial command (3+ chars): git s
  2. Wait 2 seconds (debounce delay)
  3. Suggestion appears at bottom: "🤖 git status (Ctrl+↓ to accept)"
  4. Press Ctrl+↓ to accept suggestion
  5. Press Enter to cancel generation and execute your command
  6. Continue typing to clear and reset timer

Mode 2: Interactive Menu (Manual)
  Trigger: Ctrl+↓ (or Ctrl+2)
  1. Type partial command (3+ chars): git s
  2. Press Ctrl+↓
  3. Navigate: ↑/↓ arrows or 1-3 numbers
  4. Enter to select, Esc to cancel

Mode 3: Interactive Menu (Auto-Debounce)
  Enable: export ENABLE_AI_AUTO_DEBOUNCE=true
          export AI_INLINE_MODE=false
  1. Type partial command (3+ chars): git s
  2. Wait 2 seconds
  3. Full menu appears automatically

Features:
  • ULTRA-RICH context for maximum relevance
  • Animated spinner during generation
  • Ctrl+C to cancel generation at any time
  • Arrow key navigation (↑/↓)
  • Visual selection (▶ green highlight)
  • Number shortcuts (1-3)
  • Full screen compact mode
  • 3 highly contextual AI suggestions from Gemini

Context provided to AI (ultra-enriched):
  • ALL files in directory (up to 50)
  • Recent command history (last 20 commands)
  • Git status + FULL diff (100 lines)
  • Project files content (package.json scripts, go.mod, Cargo.toml, requirements.txt)
  • README.md preview (20 lines)
  • Full environment (USER, SHELL, HOME, PATH)
  • Project type detection (Node.js, Go, Rust, Python)

Configuration:
  AI_NUM_SUGGESTIONS=3            # Number of suggestions
  AI_SUGGESTION_MIN_CHARS=3       # Minimum chars
  AI_DEBOUNCE_DELAY=2             # Debounce delay in seconds
  ENABLE_AI_AUTO_DEBOUNCE=false   # Auto-trigger after typing
  AI_INLINE_MODE=true             # Show inline (true) or menu (false)
  GEMINI_MODEL=<model>            # Gemini model

Keybindings:
  Ctrl+↓     - Accept inline AI suggestion
  Shift+Tab  - Clear inline AI suggestion
  Ctrl+2     - Show AI menu manually
  Ctrl+Space - Show AI menu manually

During generation:
  Enter      - Cancel generation and execute your command
  Ctrl+C     - Cancel generation and return to prompt
  Ctrl+L     - Cancel generation and clear screen

Menu navigation:
  ↑/↓        - Navigate suggestions
  Enter      - Select highlighted
  Q or Esc   - Cancel and quit menu
  1-3        - Direct number selection

History navigation (outside menu):
  ↑          - Previous command (prefix search)
  ↓          - Next command (prefix search)
  Ctrl+↓     - AI suggestions menu
  Ctrl+P/N   - Full history (no prefix filter)

EOF
}
