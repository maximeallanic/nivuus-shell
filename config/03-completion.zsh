# =============================================================================
# ZSH OPTIONS
# =============================================================================

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# Correction - Disabled to prevent annoying prompts
setopt CORRECT
# setopt CORRECT_ALL

# Glob
setopt EXTENDED_GLOB
setopt NOMATCH

# =============================================================================
# ULTRA-FAST COMPLETION SYSTEM
# =============================================================================

# Performance-optimized completion
autoload -Uz compinit
# Only rebuild dump once per day for performance
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit -d ~/.zcompdump
else
    compinit -C -d ~/.zcompdump
fi

# Case insensitive completion with smart matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Simplified completion settings with minimal colors
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*:messages' format '%F{blue}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- No matches found --%f'
zstyle ':completion:*:corrections' format '%F{blue}-- %d (errors: %e) --%f'
zstyle ':completion:*' squeeze-slashes true

# Completion caching for performance
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Simplified completion behaviors
zstyle ':completion:*' rehash true                              # Auto-rehash commands
zstyle ':completion:*' insert-tab pending                       # Insert tab when completing
zstyle ':completion:*' expand 'yes'                            # Expand globs
zstyle ':completion:*' substitute 'yes'                        # Substitute variables
zstyle ':completion:*:default' list-colors 'di=34:ln=35:ex=31' # Minimal file colors

# Process completion with minimal colors
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=34=0'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# SSH/SCP/RSYNC completion
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr

# Directory completion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' special-dirs true

# Man page completion
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true
zstyle ':completion:*:man:*' menu yes select
