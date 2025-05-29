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

# Correction
setopt CORRECT
setopt CORRECT_ALL

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

# Enhanced completion settings with colors
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '%B%F{green}-- %d --%f%b'
zstyle ':completion:*:messages' format '%B%F{purple}-- %d --%f%b'
zstyle ':completion:*:warnings' format '%B%F{red}-- No matches found --%f%b'
zstyle ':completion:*:corrections' format '%B%F{yellow}-- %d (errors: %e) --%f%b'
zstyle ':completion:*' squeeze-slashes true

# Completion caching for performance
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Advanced completion behaviors
zstyle ':completion:*' rehash true                              # Auto-rehash commands
zstyle ':completion:*' insert-tab pending                       # Insert tab when completing
zstyle ':completion:*' expand 'yes'                            # Expand globs
zstyle ':completion:*' substitute 'yes'                        # Substitute variables
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}  # Colored file listings

# Process completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
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
