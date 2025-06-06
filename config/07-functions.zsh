# =============================================================================
# INTELLIGENT FUNCTIONS & PROJECT DETECTION
# =============================================================================

# Smart find function
f() {
    if command -v fd &> /dev/null; then
        fd "$1"
    else
        find . -name "*$1*" 2>/dev/null
    fi
}

# Smart search function (renamed to avoid alias conflict)
smart_grep() {
    if command -v rg &> /dev/null; then
        rg "$@"
    else
        grep -r "$@" . 2>/dev/null
    fi
}

# Process search with fuzzy matching
psg() {
    ps aux | grep -E "(^USER|$1)" | grep -v grep
}

# Project type detection and smart setup
detect_project() {
    # Track current directory to avoid unnecessary operations
    local current_dir="$(pwd)"
    
    # Check if directory actually changed
    if [[ -n "$_NIVUUS_LAST_PROJECT_PWD" && "$current_dir" == "$_NIVUUS_LAST_PROJECT_PWD" ]]; then
        return 0  # Same directory, do nothing
    fi
    
    # Update last directory
    export _NIVUUS_LAST_PROJECT_PWD="$current_dir"
    
    local project_type=""
    
    if [[ -f package.json ]]; then
        project_type="Node.js"
        echo "📦 $project_type project detected"
        if [[ -f yarn.lock ]]; then
            echo "   Package manager: Yarn"
        elif [[ -f pnpm-lock.yaml ]]; then
            echo "   Package manager: PNPM"
        else
            echo "   Package manager: NPM"
        fi
    elif [[ -f requirements.txt ]] || [[ -f pyproject.toml ]] || [[ -f setup.py ]]; then
        project_type="Python"
        echo "🐍 $project_type project detected"
    elif [[ -f Cargo.toml ]]; then
        project_type="Rust"
        echo "🦀 $project_type project detected"
    elif [[ -f go.mod ]]; then
        project_type="Go"
        echo "🐹 $project_type project detected"
    elif [[ -f Dockerfile ]]; then
        project_type="Docker"
        echo "🐳 $project_type project detected"
    fi
    
    # Auto-suggestions based on project
    case $project_type in
        "Node.js")
            echo "   Suggested commands: npm install, npm start, npm test"
            ;;
        "Python")
            echo "   Suggested commands: pip install -r requirements.txt, python main.py"
            ;;
        "Rust")
            echo "   Suggested commands: cargo build, cargo run, cargo test"
            ;;
        "Go")
            echo "   Suggested commands: go mod download, go run ., go test"
            ;;
    esac
}

# Smart directory change with project detection
smart_cd() {
    builtin cd "$@"
    
    # Initialize project directory tracking if not set
    if [[ -z "$_NIVUUS_LAST_PROJECT_PWD" ]]; then
        export _NIVUUS_LAST_PROJECT_PWD=""
    fi
    
    # Detect project type (will only show output if directory actually changed)
    detect_project
}

# Enhanced directory history
cd() {
    smart_cd "$@"
}

# Quick directory jumper (z-like functionality)
j() {
    local dir
    if [[ $# -eq 0 ]]; then
        dir=$(dirs -v | fzf --height 20% --reverse | awk '{print $2}')
        [[ -n $dir ]] && cd "$dir"
    else
        # Simple pattern matching for now
        dir=$(find ~ -type d -name "*$1*" 2>/dev/null | head -1)
        [[ -n $dir ]] && cd "$dir"
    fi
}

# File size analyzer
analyze_size() {
    echo "📊 Directory Size Analysis"
    echo "========================="
    du -sh * 2>/dev/null | sort -hr | head -10
    echo ""
    echo "💾 Disk Usage:"
    df -h . | tail -1
}

# Git status enhancer
gstat() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "📋 Git Repository Status"
        echo "======================="
        git status --short --branch
        echo ""
        echo "📈 Recent commits:"
        git log --oneline --graph --decorate -5
    else
        echo "❌ Not a git repository"
    fi
}

# System information
sysinfo() {
    echo "💻 System Information"
    echo "===================="
    echo "🖥️  Hostname: $(hostname)"
    echo "👤 User: $(whoami)"
    echo "📅 Date: $(date)"
    echo "⏰ Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    echo "💾 Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "💿 Disk: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')"
    echo "🔥 CPU: $(nproc) cores"
    echo "📦 Shell: $SHELL ($ZSH_VERSION)"
}

# =============================================================================
# NVM LAZY LOADING (PERFORMANCE BOOST)
# =============================================================================

# NVM lazy loading function
load_nvm() {
    # Skip if NVM is already loaded
    if command -v nvm &> /dev/null; then
        return 0
    fi
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Auto-load default or LTS Node.js version
    if command -v nvm &> /dev/null; then
        # Try to use .nvmrc if present, otherwise use default or LTS
        if [[ -f ".nvmrc" ]]; then
            nvm use --silent 2>/dev/null || nvm use default --silent 2>/dev/null || nvm use --lts --silent 2>/dev/null
        else
            nvm use default --silent 2>/dev/null || nvm use --lts --silent 2>/dev/null
        fi
    fi
}

# Load NVM if not already available
if ! command -v npm &> /dev/null; then
    load_nvm
fi
