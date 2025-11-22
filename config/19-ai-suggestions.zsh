#!/usr/bin/env zsh
# =============================================================================
# AI Command Suggestions - Compact Interactive Menu
# =============================================================================

# Only load once
[[ -n "${NIVUUS_AI_SUGGESTIONS_LOADED}" ]] && return
export NIVUUS_AI_SUGGESTIONS_LOADED=1

# Skip if explicitly disabled
[[ "${ENABLE_AI_SUGGESTIONS:-true}" != "true" ]] && return

# Check if gemini is available
if ! command -v gemini &>/dev/null; then
    return
fi

# =============================================================================
# Configuration
# =============================================================================

typeset -g AI_SUGGESTION_MIN_CHARS="${AI_SUGGESTION_MIN_CHARS:-3}"
typeset -g AI_NUM_SUGGESTIONS="${AI_NUM_SUGGESTIONS:-5}"

# Cache
typeset -gA _AI_CACHE
typeset -gA _AI_CACHE_TIME

# =============================================================================
# Context Collection
# =============================================================================

_ai_get_context() {
    local context=""
    context+="Dir: $PWD\n"

    # Recent history
    local hist=$(fc -ln -5 2>/dev/null | sed 's/^[[:space:]]*//' | grep -v "^$" | tail -3 | tr '\n' ';')
    [[ -n "$hist" ]] && context+="Recent: $hist\n"

    # Project type
    [[ -f "package.json" ]] && context+="Project: Node.js\n"
    [[ -f "go.mod" ]] && context+="Project: Go\n"

    # Git
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        [[ -n "$branch" ]] && context+="Git: $branch\n"
    fi

    echo "$context"
}

# =============================================================================
# Generate AI Suggestions
# =============================================================================

_ai_generate() {
    local prefix="$1"
    local cache_key="${prefix}_${PWD}"

    # Check cache (5min TTL)
    if [[ -n "${_AI_CACHE_TIME[$cache_key]}" ]]; then
        local age=$(( EPOCHSECONDS - _AI_CACHE_TIME[$cache_key] ))
        if (( age < 300 )); then
            echo "${_AI_CACHE[$cache_key]}"
            return
        fi
    fi

    local context=$(_ai_get_context)
    local prompt="Complete this command with ${AI_NUM_SUGGESTIONS} alternatives (one per line, no numbering):

Command: $prefix
$context
Completions:"

    local result=$(gemini --model "${GEMINI_MODEL:-gemini-2.5-flash-lite}" -o text "$prompt" 2>&1 | \
        grep -v '^\[' | \
        grep -v '^Loaded' | \
        grep -v '^Cached' | \
        sed 's/^[0-9]*\.\s*//' | \
        grep -E '^[a-zA-Z0-9_/\.\-]' | \
        head -${AI_NUM_SUGGESTIONS})

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
# Compact Interactive Menu
# =============================================================================

_ai_show_menu() {
    local prefix="$BUFFER"

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
        printf "↑/↓: Navigate  Enter: Select  Q/Esc: Quit  1-${#suggestions[@]}: Direct"

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
# Widget and Keybinding
# =============================================================================

# Register widget
zle -N ai-show-menu _ai_show_menu

# Bind multiple variants
bindkey '^[[1;5B' ai-show-menu     # Ctrl+Down (PRIMARY - most intuitive)
bindkey '^2' ai-show-menu          # Ctrl+2 (fallback)
bindkey '^[[13;5~' ai-show-menu    # Ctrl+Enter
bindkey '^[^M' ai-show-menu        # Ctrl+Enter (alt)
bindkey '^ ' ai-show-menu          # Ctrl+Space
bindkey '^@' ai-show-menu          # Ctrl+Space (alt)

# =============================================================================
# Help
# =============================================================================

ai_suggestions_help() {
    cat <<'EOF'
AI Command Suggestions - Compact Interactive Menu

Usage:
  1. Type partial command (3+ chars): git s
  2. Press Ctrl+↓ (or Ctrl+2)
  3. Animated spinner while AI thinks (Ctrl+C to cancel)
  4. Navigate: ↑/↓ arrows or 1-5 numbers
  5. Enter to select, Esc to cancel

Features:
  • Animated spinner during generation
  • Ctrl+C to cancel generation at any time
  • Arrow key navigation (↑/↓)
  • Visual selection (▶ green highlight)
  • Number shortcuts (1-5)
  • Full screen compact mode
  • 5 AI suggestions from Gemini 2.5 Flash Lite

Configuration:
  AI_NUM_SUGGESTIONS=5         # Number of suggestions
  AI_SUGGESTION_MIN_CHARS=3    # Minimum chars
  GEMINI_MODEL=<model>         # Gemini model

Keybindings:
  Ctrl+↓     - Show AI menu (PRIMARY - most intuitive!)
  Ctrl+2     - Alternative (works everywhere)

During generation:
  Ctrl+C     - Cancel generation and return to prompt

Menu navigation:
  ↑/↓        - Navigate suggestions
  Enter      - Select highlighted
  Q or Esc   - Cancel and quit menu
  1-5        - Direct number selection

History navigation (outside menu):
  ↑          - Previous command (prefix search)
  ↓          - Next command (prefix search)
  Ctrl+↓     - AI suggestions menu
  Ctrl+P/N   - Full history (no prefix filter)

EOF
}
