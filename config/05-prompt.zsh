# =============================================================================
# ASYNC PROMPT FOR ULTRA PERFORMANCE
# =============================================================================

# Enable colors and async prompt
autoload -U colors && colors
setopt PROMPT_SUBST

# SSH detection (cached)
is_ssh() {
    [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ "$SESSION_TYPE" == "remote/ssh" ]]
}

# Async git information (lightning fast)
git_prompt_info() {
    local git_info=""
    
    # Quick git check
    if git rev-parse --git-dir &>/dev/null; then
        local branch=""
        local dirty=""
        
        # Get branch name efficiently
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        
        # Quick dirty check (non-blocking)
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            dirty="%{$reset_color%}%{$fg_bold[blue]%})%{$reset_color%}%{$fg[red]%}x%{$reset_color%}"
        else
            dirty="%{$reset_color%}%{$fg_bold[blue]%})%{$reset_color%}"
        fi
        
        git_info=" %{$fg_bold[blue]%}git:(%{$fg[red]%}$branch$dirty"
    fi
    
    echo "$git_info"
}

# Enhanced Firebase detection with caching
prompt_firebase() {
    local cache_file="/tmp/.firebase_cache_$(pwd | tr '/' '_')"
    local current_dir=$(pwd)
    
    # Use cache if recent (5 minutes)
    if [[ -f $cache_file && $cache_file -nt $current_dir && $(($(date +%s) - $(stat -c %Y $cache_file))) -lt 300 ]]; then
        cat "$cache_file" 2>/dev/null
        return
    fi
    
    # Get Firebase project with timeout
    local fb_project=""
    if [[ -f ~/.config/configstore/firebase-tools.json ]]; then
        fb_project=$(timeout 0.1 jq -r --arg dir "$current_dir" '.activeProjects[$dir] // empty' ~/.config/configstore/firebase-tools.json 2>/dev/null)
    fi
    
    if [[ -n $fb_project ]]; then
        echo " %F{yellow}[$fb_project]%f" > "$cache_file"
        echo " %F{yellow}[$fb_project]%f"
    else
        echo "" > "$cache_file"
    fi
}

# Ultra-fast prompt building
build_prompt() {
    local prompt_parts=()
    
    # SSH indicator
    if is_ssh; then
        prompt_parts+=("%{$fg_bold[grey]%}[%{$fg_bold[blue]%}\$(hostname)%{$fg_bold[grey]%}]%{$reset_color%} ")
    fi
    
    # Root indicator
    if [[ "$(whoami)" == "root" ]]; then
        prompt_parts+=("%{$fg[red]%}#%{$reset_color%} ")
    fi
    
    # Status indicator
    prompt_parts+=("%(?:%{$fg_bold[green]%}>:%{$fg_bold[red]%}>) ")
    
    # Path
    prompt_parts+=("%{$fg[cyan]%}%~%{$reset_color%}")
    
    # Firebase and Git (async)
    prompt_parts+=("\$(prompt_firebase)\$(git_prompt_info) ")
    
    echo "${(j::)prompt_parts}"
}

# Set the ultimate prompt
PROMPT=$(build_prompt)

# Ensure our prompt is not overridden by external tools
export VIRTUAL_ENV_DISABLE_PROMPT=1
export CONDA_CHANGEPS1=false
