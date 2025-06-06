# =============================================================================
# SUBTLE COLOR SCHEME
# =============================================================================

# Minimal LS_COLORS - only essential colors, no bold/bright
export LS_COLORS="di=34:ln=36:ex=32:*.tar=31:*.gz=31:*.zip=31"

# Reduce colorfulness in common tools
export GREP_COLORS="mt=31"  # Simple red for matches (updated from deprecated GREP_COLOR)
export LESS_TERMCAP_md=$'\e[34m'    # Blue for bold
export LESS_TERMCAP_us=$'\e[4m'     # Underline only
export LESS_TERMCAP_so=$'\e[7m'     # Reverse video
export LESS_TERMCAP_me=$'\e[0m'     # Reset
export LESS_TERMCAP_se=$'\e[0m'     # Reset
export LESS_TERMCAP_ue=$'\e[0m'     # Reset

# Git with minimal colors
export GIT_CONFIG_COUNT=3
export GIT_CONFIG_KEY_0="color.ui"
export GIT_CONFIG_VALUE_0="auto"
export GIT_CONFIG_KEY_1="color.status.changed"
export GIT_CONFIG_VALUE_1="blue"
export GIT_CONFIG_KEY_2="color.status.untracked"
export GIT_CONFIG_VALUE_2="red"
