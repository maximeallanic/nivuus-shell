# =============================================================================
# SYNCHRONOUS PROMPT FOR RELIABILITY
# =============================================================================

# Enable colors and synchronous prompt - only in zsh
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U colors && colors
    setopt PROMPT_SUBST
fi

# SSH detection (cached)
is_ssh() {
    [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ "$SESSION_TYPE" == "remote/ssh" ]]
}

# Synchronous git information (blocking but reliable)
git_prompt_info() {
    local git_info=""
    
    # Git check
    if git rev-parse --git-dir &>/dev/null; then
        local branch=""
        local dirty=""
        
        # Get branch name
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        
        # Dirty check (blocking)
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            dirty="%{$reset_color%}%{$fg_bold[blue]%})%{$reset_color%}%{$fg[red]%}x%{$reset_color%}"
        else
            dirty="%{$reset_color%}%{$fg_bold[blue]%})%{$reset_color%}"
        fi
        
        git_info=" %{$fg_bold[blue]%}git:(%{$fg[red]%}$branch$dirty"
    fi
    
    echo "$git_info"
}

# Firebase detection without caching (synchronous)
prompt_firebase() {
    local current_dir=$(pwd)
    
    # Get Firebase project synchronously
    local fb_project=""
    if [[ -f ~/.config/configstore/firebase-tools.json ]]; then
        fb_project=$(jq -r --arg dir "$current_dir" '.activeProjects[$dir] // empty' ~/.config/configstore/firebase-tools.json 2>/dev/null)
    fi
    
    if [[ -n $fb_project ]]; then
        echo " %F{yellow}[$fb_project]%f"
    fi
}

# Synchronous prompt building - only in zsh
if [[ -n "$ZSH_VERSION" ]]; then
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
        
        # Firebase and Git (synchronous)
        prompt_parts+=("\$(prompt_firebase)\$(git_prompt_info) ")
        
        echo "${(j::)prompt_parts}"
    }

    # Set the ultimate prompt
    PROMPT=$(build_prompt)

    # Ensure our prompt is not overridden by external tools
    export VIRTUAL_ENV_DISABLE_PROMPT=1
    export CONDA_CHANGEPS1=false
fi
