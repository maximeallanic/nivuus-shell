#!/usr/bin/env zsh
# =============================================================================
# Nivuus Prompt - Nord Theme
# =============================================================================
# Format: [SSH] [ROOT] STATUS PATH [FIREBASE] GIT
# Synchronous with Git caching (2s TTL)
# =============================================================================

# Enable prompt substitution
setopt PROMPT_SUBST

# =============================================================================
# Git Prompt Cache
# =============================================================================

typeset -g _GIT_PROMPT_CACHE_DIR=""
typeset -g _GIT_PROMPT_CACHE_TIME=0
typeset -g _GIT_PROMPT_CACHE_VALUE=""

# =============================================================================
# Helper Functions
# =============================================================================

# Check if running in SSH session
is_ssh() {
    [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || "$SESSION_TYPE" == "remote" ]]
}

# Check if running as root
is_root() {
    [[ "$EUID" -eq 0 || "$(whoami)" == "root" ]]
}

# =============================================================================
# Git Prompt with Cache
# =============================================================================

git_prompt_info() {
    # Check if in a git repository
    git rev-parse --git-dir &>/dev/null || return

    local current_dir="$PWD"
    local current_time="$EPOCHSECONDS"
    local cache_ttl="${GIT_PROMPT_CACHE_TTL:-2}"

    # Use cache if valid
    if [[ "$_GIT_PROMPT_CACHE_DIR" == "$current_dir" ]] && \
       (( current_time - _GIT_PROMPT_CACHE_TIME < cache_ttl )); then
        echo "$_GIT_PROMPT_CACHE_VALUE"
        return
    fi

    # Get git branch
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || echo "detached")

    # Check for modifications (using porcelain for reliability)
    local status_icon=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        status_icon="%{%F{167}%}○%{%f%}"  # Red empty circle when dirty
    else
        status_icon="%{%F{143}%}●%{%f%}"  # Green filled circle when clean
    fi

    # Build git prompt with Nord colors
    # git:( in cyan bold, branch in red, ) in cyan bold, space, status icon (✓ or ✗)
    local git_prompt=" %{%B%F{110}%}git:(%{%F{167}%}${branch}%{%B%F{110}%})%{%f%b%} ${status_icon}"

    # Update cache
    _GIT_PROMPT_CACHE_DIR="$current_dir"
    _GIT_PROMPT_CACHE_TIME="$current_time"
    _GIT_PROMPT_CACHE_VALUE="$git_prompt"

    echo "$git_prompt"
}

# =============================================================================
# Firebase Prompt (Optional)
# =============================================================================

prompt_firebase() {
    [[ "${ENABLE_FIREBASE_PROMPT:-true}" != "true" ]] && return

    # Check if we're in a Firebase project (look for .firebaserc or firebase.json)
    local dir="$PWD"
    local firebase_dir=""

    # Search up the directory tree for .firebaserc or firebase.json
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.firebaserc" ]] || [[ -f "$dir/firebase.json" ]]; then
            firebase_dir="$dir"
            break
        fi
        dir="${dir:h}"
    done

    # If not in a Firebase project, return
    [[ -z "$firebase_dir" ]] && return

    local project=""

    # Try to get active project from global config first
    local firebase_config="$HOME/.config/configstore/firebase-tools.json"
    if [[ -f "$firebase_config" ]] && command -v jq &>/dev/null; then
        # Try to get active project for this directory
        project=$(jq -r --arg dir "$firebase_dir" '.activeProjects[$dir] // empty' "$firebase_config" 2>/dev/null)
    fi

    # If no active project found, try .firebaserc
    if [[ -z "$project" ]] && [[ -f "$firebase_dir/.firebaserc" ]]; then
        if command -v jq &>/dev/null; then
            # Try default first, then first available project
            project=$(jq -r '.projects.default // .projects | to_entries[0].value // empty' "$firebase_dir/.firebaserc" 2>/dev/null)
        else
            # Fallback: pure ZSH parsing (no external commands)
            local content=$(<"$firebase_dir/.firebaserc")
            # Try to extract default project first
            if [[ "$content" =~ '"default"[[:space:]]*:[[:space:]]*"([^"]+)"' ]]; then
                project="${match[1]}"
            else
                # Get first project if no default
                if [[ "$content" =~ '"[^"]+"[[:space:]]*:[[:space:]]*"([^"]+)"' ]]; then
                    project="${match[1]}"
                fi
            fi
        fi
    fi

    # Firebase project in orange brackets
    [[ -n "$project" ]] && echo " %{%F{208}%}[${project}]%{%f%}"
}

# =============================================================================
# Build Complete Prompt
# =============================================================================

# Synchronous prompt building
build_prompt() {
    local prompt_parts=()

    # SSH indicator
    if is_ssh; then
        prompt_parts+=("%{%B%F{240}%}[%{%B%F{67}%}\$(hostname)%{%B%F{240}%}]%{%f%b%} ")
    fi

    # Root indicator
    if is_root; then
        prompt_parts+=("%{%F{167}%}#%{%f%} ")
    fi

    # Status indicator
    prompt_parts+=("%(?:%{%B%F{143}%}>:%{%B%F{167}%}>) ")

    # Path
    prompt_parts+=("%{%F{109}%}%~%{%f%}")

    # Firebase and Git (synchronous)
    prompt_parts+=("\$(prompt_firebase)\$(git_prompt_info) ")

    echo "${(j::)prompt_parts}"
}

# =============================================================================
# Background Jobs Info (Right Prompt)
# =============================================================================

background_jobs_info() {
    # Use ZSH native job tracking (more reliable than jobs command)
    local running=0
    local stopped=0
    local running_names=()
    local stopped_names=()

    # Iterate over job states
    for job_id state in ${(kv)jobstates}; do
        # Parse state: jobstates format is "state:pid=status"
        # State can be: running, suspended, done
        local job_state="${state%%:*}"

        case "$job_state" in
            running)
                ((running++))
                # Get job text (command name)
                local job_text="${jobtexts[$job_id]}"
                # Truncate to first word (command name)
                running_names+=(${job_text%% *})
                ;;
            suspended)
                ((stopped++))
                local job_text="${jobtexts[$job_id]}"
                stopped_names+=(${job_text%% *})
                ;;
        esac
    done

    local total=$((running + stopped))
    [[ $total -eq 0 ]] && return

    local output=""

    # If 2 jobs or less, show names
    if (( total <= 2 )); then
        if (( running > 0 )); then
            local names="${(j: :)running_names}"
            # Truncate if too long
            [[ ${#names} -gt 20 ]] && names="${names:0:17}..."
            output+="%{%F{143}%}▶ %{%f%}%{%F{246}%}${names}%{%f%}"
        fi

        if (( stopped > 0 )); then
            [[ -n "$output" ]] && output+=" "
            local names="${(j: :)stopped_names}"
            [[ ${#names} -gt 20 ]] && names="${names:0:17}..."
            output+="%{%F{167}%}⏸ %{%f%}%{%F{246}%}${names}%{%f%}"
        fi
    else
        # Show counts
        if (( running > 0 )); then
            output+="%{%F{143}%}▶ ${running}%{%f%}"
        fi

        if (( stopped > 0 )); then
            [[ -n "$output" ]] && output+=" "
            output+="%{%F{167}%}⏸ ${stopped}%{%f%}"
        fi
    fi

    echo "$output"
}

# =============================================================================
# Set Prompt
# =============================================================================

# Main prompt
PROMPT=$(build_prompt)

# Right prompt with background jobs
RPROMPT='$(background_jobs_info)'

# Continuation prompt
PROMPT2="${NORD_PATH}%_>${NORD_RESET} "

# Selection prompt
PROMPT3="${NORD_PATH}?#${NORD_RESET} "

# Execution trace prompt
PROMPT4="${NORD_PATH}+%N:%i>${NORD_RESET} "
