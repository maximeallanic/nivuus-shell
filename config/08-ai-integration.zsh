# =============================================================================
# AI ASSISTANCE INTEGRATION
# =============================================================================

# GitHub Copilot CLI integration (enhanced)
if command -v gh &> /dev/null; then
    # Standard Copilot aliases
    eval "$(gh copilot alias -- zsh)" 2>/dev/null
    
    # Enhanced aliases for better workflow
    alias ai='gh copilot suggest'
    alias explain='gh copilot explain'
    alias fix='gh copilot suggest -t shell'
    alias gitai='gh copilot suggest -t git'
    
    # Quick AI command helper
    ask() {
        if [[ $# -eq 0 ]]; then
            echo "Usage: ask 'your question'"
            echo "Examples:"
            echo "  ask 'how to find files larger than 100MB'"
            echo "  ask 'git command to undo last commit'"
            return 1
        fi
        gh copilot suggest -t shell "$*"
    }
    
    # AI code explanation
    why() {
        if [[ $# -eq 0 ]]; then
            echo "Usage: why 'command to explain'"
            echo "Example: why 'find . -name \"*.js\" -exec grep -l \"console.log\" {} \\;'"
            return 1
        fi
        gh copilot explain "$*"
    }
fi

# =============================================================================
# AI-POWERED ALIASES
# =============================================================================

# GitHub Copilot shortcuts (if available)
if command -v gh &> /dev/null; then
    # Quick AI assistance for shell commands
    alias '??'='gh copilot suggest -t shell'
    alias '?git'='gh copilot suggest -t git'
    alias '?gh'='gh copilot suggest -t gh'
    
    # Interactive AI command generation
    aihelp() {
        echo "🤖 GitHub Copilot CLI Assistant"
        echo "================================"
        echo ""
        echo "Available commands:"
        echo "  ?? 'describe what you want to do'  - Get shell command suggestions"
        echo "  ?git 'git task description'       - Get git command suggestions"
        echo "  ?gh 'github task description'     - Get GitHub CLI suggestions"
        echo "  ask 'question'                    - General command help"
        echo "  why 'command'                     - Explain what a command does"
        echo "  explain 'command'                 - Detailed command explanation"
        echo ""
        echo "Examples:"
        echo "  ?? 'find all large files'"
        echo "  ?git 'undo my last commit'"
        echo "  ask 'how to compress a folder'"
        echo "  why 'tar -xzf file.tar.gz'"
    }
fi
