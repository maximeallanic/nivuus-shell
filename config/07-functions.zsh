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

# Smart grep function
gr() {
    if command -v rg &> /dev/null; then
        rg "$1"
    else
        grep -r "$1" . 2>/dev/null
    fi
}

# Process search with fuzzy matching
psg() {
    ps aux | grep -E "(^USER|$1)" | grep -v grep
}

# Project type detection and smart setup
detect_project() {
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
    
    # Show directory contents intelligently
    if command -v eza &> /dev/null; then
        eza --icons --group-directories-first -x
    else
        ls -CF
    fi
    
    # Detect project type
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
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Create nvm function that loads NVM on first use
nvm() {
    unfunction nvm
    load_nvm
    nvm "$@"
}

# Create node function that loads NVM on first use
node() {
    unfunction node
    load_nvm
    node "$@"
}

# Create npm function that loads NVM on first use
npm() {
    unfunction npm
    load_nvm
    npm "$@"
}
