#!/usr/bin/env zsh
# =============================================================================
# Nord Theme - Color Palette
# =============================================================================
# Official Nord color scheme for terminal
# https://www.nordtheme.com/
# =============================================================================

# Enable color support (if available)
if (( $+commands[autoload] )) || typeset -f autoload >/dev/null 2>&1; then
    autoload -U colors && colors
fi

# =============================================================================
# Polar Night (Dark backgrounds/accents)
# =============================================================================

export NORD0="#2E3440"   # Background
export NORD1="#3B4252"   # Lighter background
export NORD2="#434C5E"   # Selection background
export NORD3="#4C566A"   # Comments, invisibles, line highlighting

# =============================================================================
# Snow Storm (Light foreground/text)
# =============================================================================

export NORD4="#D8DEE9"   # Default foreground
export NORD5="#E5E9F0"   # Lighter foreground
export NORD6="#ECEFF4"   # Lightest foreground

# =============================================================================
# Frost (Blue/Cyan accents)
# =============================================================================

export NORD7="#8FBCBB"   # Teal/Cyan light → PATH
export NORD8="#88C0D0"   # Cyan → GIT PREFIX
export NORD9="#81A1C1"   # Blue light
export NORD10="#5E81AC"  # Blue → SSH HOSTNAME

# =============================================================================
# Aurora (Colorful accents)
# =============================================================================

export NORD11="#BF616A"  # Red → ERROR, GIT BRANCH, ROOT
export NORD12="#D08770"  # Orange
export NORD13="#EBCB8B"  # Yellow → FIREBASE
export NORD14="#A3BE8C"  # Green → SUCCESS
export NORD15="#B48EAD"  # Purple/Magenta

# =============================================================================
# ZSH Color Mappings (for prompt usage)
# =============================================================================

# Convert hex to ANSI 256 colors (approximation)
typeset -gA NORD_COLORS
NORD_COLORS=(
    # Polar Night
    bg_main      "236"    # ~NORD0
    bg_light     "237"    # ~NORD1
    bg_select    "238"    # ~NORD2
    comment      "240"    # ~NORD3

    # Snow Storm
    fg_main      "253"    # ~NORD4
    fg_light     "254"    # ~NORD5
    fg_bright    "255"    # ~NORD6

    # Frost
    cyan_light   "109"    # ~NORD7 (path)
    cyan         "110"    # ~NORD8 (git prefix)
    blue_light   "109"    # ~NORD9
    blue         "67"     # ~NORD10 (ssh)

    # Aurora
    red          "167"    # ~NORD11 (error, branch, root)
    orange       "173"    # ~NORD12
    yellow       "221"    # ~NORD13 (firebase)
    green        "143"    # ~NORD14 (success)
    magenta      "139"    # ~NORD15
)

# =============================================================================
# Helper Functions
# =============================================================================

# Get Nord color for ZSH prompt
nord_color() {
    echo "%F{${NORD_COLORS[$1]}}"
}

# Reset color
nord_reset() {
    echo "%f"
}

# =============================================================================
# Semantic Color Variables (for prompt usage)
# =============================================================================

export NORD_PATH=$(nord_color cyan_light)
export NORD_SUCCESS=$(nord_color green)
export NORD_ERROR=$(nord_color red)
export NORD_SSH=$(nord_color blue)
export NORD_ROOT=$(nord_color red)
export NORD_GIT_PREFIX=$(nord_color cyan)
export NORD_GIT_BRANCH=$(nord_color red)
export NORD_FIREBASE=$(nord_color yellow)
export NORD_RESET=$(nord_reset)

# =============================================================================
# LS_COLORS with Nord theme
# =============================================================================

export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32'

# =============================================================================
# Grep Colors
# =============================================================================

export GREP_COLOR='1;32'    # Green for matches
export GREP_COLORS="mt=${NORD_COLORS[green]}:fn=${NORD_COLORS[cyan]}:ln=${NORD_COLORS[yellow]}"
