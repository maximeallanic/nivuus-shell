#!/usr/bin/env zsh
# =============================================================================
# Syntax Highlighting - Nord Theme
# =============================================================================
# Command-line syntax highlighting with Nord colors
# =============================================================================

# Only load if enabled
[[ "${ENABLE_SYNTAX_HIGHLIGHTING:-false}" != "true" ]] && return

# =============================================================================
# Load zsh-syntax-highlighting
# =============================================================================

# Try common installation paths
typeset -a highlighting_paths
highlighting_paths=(
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ~/.local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
)

for highlighting_path in $highlighting_paths; do
    if [[ -f "$highlighting_path" ]]; then
        source "$highlighting_path"
        break
    fi
done

# Exit if not loaded
[[ -z "$ZSH_HIGHLIGHT_HIGHLIGHTERS" ]] && return

# =============================================================================
# Nord Theme Colors for Syntax Highlighting (Official)
# =============================================================================
# Based on https://www.nordtheme.com/docs/colors-and-palettes
#
# Polar Night: 236-240 (backgrounds/dark)
# Snow Storm: 253-255 (foregrounds/light)
# Frost: 109 (nord7), 110 (nord8), 67 (nord9), 68 (nord10) - cyan/blue
# Aurora: 167 (nord11), 208 (nord12), 221 (nord13), 143 (nord14), 139 (nord15)
# =============================================================================

# Main highlighter
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# Default text (nord4 - light gray)
ZSH_HIGHLIGHT_STYLES[default]='fg=253'

# Unknown commands (nord11 - red)
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=167,bold'

# Commands (nord8 - cyan)
ZSH_HIGHLIGHT_STYLES[command]='fg=110'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=110'
ZSH_HIGHLIGHT_STYLES[function]='fg=110'
ZSH_HIGHLIGHT_STYLES[alias]='fg=110'

# Keywords and reserved words (nord9 - blue)
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=67'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=67'

# Paths (nord14 - green)
ZSH_HIGHLIGHT_STYLES[path]='fg=143'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=143'
ZSH_HIGHLIGHT_STYLES[path_approx]='fg=143,underline'

# Strings (nord14 - green, official Nord style)
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=143'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=143'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=143'

# Variables (nord15 - purple)
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=139'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=139'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=139'
ZSH_HIGHLIGHT_STYLES[assign]='fg=139'

# Globbing/wildcards (nord13 - yellow)
ZSH_HIGHLIGHT_STYLES[globbing]='fg=221'

# Redirection (nord9 - blue)
ZSH_HIGHLIGHT_STYLES[redirection]='fg=67'

# Command separator (nord3 - dim gray)
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=240'

# Comments (nord3 - dim gray)
ZSH_HIGHLIGHT_STYLES[comment]='fg=240'

# Arguments
ZSH_HIGHLIGHT_STYLES[arg0]='fg=110'

# Brackets matching (Frost colors)
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=110'  # nord8 - cyan
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=67'   # nord9 - blue
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=109'  # nord7 - cyan light
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=68'   # nord10 - dark blue
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=167,bold'  # nord11 - red

# Cursor
ZSH_HIGHLIGHT_STYLES[cursor]='standout'

# =============================================================================
# Pattern Highlighting (Security)
# =============================================================================

# Highlight dangerous commands (nord11 - red)
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf*' 'fg=167,bold')

# Highlight only the word "sudo" (nord12 - orange)
ZSH_HIGHLIGHT_STYLES[precommand]='fg=208'  # sudo, nohup, etc.

# =============================================================================
# Performance Optimization
# =============================================================================

# Disable highlighting for very long buffers (performance)
ZSH_HIGHLIGHT_MAXLENGTH=512
