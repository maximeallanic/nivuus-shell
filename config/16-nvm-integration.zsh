# =============================================================================
# NVM (NODE VERSION MANAGER) CONFIGURATION
# =============================================================================

# NVM Configuration
export NVM_LAZY_LOAD=false          # Disable lazy loading for better VS Code integration
export NVM_AUTO_USE=true            # Automatically use Node version from .nvmrc
export NVM_COMPLETION=true          # Enable command completion

# Initialize NVM
nvm_init() {
    # Check if NVM directory exists
    if [[ ! -d "$HOME/.nvm" ]]; then
        return 1
    fi
    
    # Set NVM directory
    export NVM_DIR="$HOME/.nvm"
    
    # Load NVM script
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        \. "$NVM_DIR/nvm.sh"
    else
        return 1
    fi
    
    # Load bash completion for NVM
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        \. "$NVM_DIR/bash_completion"
    fi
    
    return 0
}

# Auto-switch Node.js version based on .nvmrc
nvm_auto_use() {
    if ! command -v nvm &> /dev/null; then
        return 0
    fi
    
    local nvmrc_path="$(pwd)/.nvmrc"
    
    if [[ -f "$nvmrc_path" ]]; then
        local nvmrc_version="$(cat "$nvmrc_path")"
        local current_version="$(nvm current 2>/dev/null || echo 'none')"
        
        # Only switch if different version
        if [[ "$nvmrc_version" != "$current_version" ]]; then
            if nvm list "$nvmrc_version" &> /dev/null; then
                nvm use --silent "$nvmrc_version"
            else
                echo "📦 Node.js version $nvmrc_version not installed. Installing..."
                nvm install "$nvmrc_version"
                nvm use --silent "$nvmrc_version"
            fi
        fi
    elif [[ "$(nvm current 2>/dev/null)" == "none" ]] || [[ "$(nvm current 2>/dev/null)" == "system" ]]; then
        # Use default version if no .nvmrc and no version selected
        nvm use default --silent 2>/dev/null || nvm use --lts --silent 2>/dev/null || true
    fi
}

# NVM quick installation function
nvm_install() {
    if [[ -d "$HOME/.nvm" ]]; then
        echo "✅ NVM already installed"
        return 0
    fi
    
    echo "📦 Installing NVM..."
    local nvm_version="v0.39.4"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    
    # Reload this script to initialize NVM
    if nvm_init; then
        echo "✅ NVM installed successfully"
        
        # Install latest LTS Node.js
        echo "📦 Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        nvm alias default "lts/*"
        echo "✅ Node.js LTS installed and set as default"
    else
        echo "❌ NVM installation failed"
        return 1
    fi
}

# NVM update function
nvm_update() {
    if [[ ! -d "$HOME/.nvm" ]]; then
        echo "❌ NVM not installed. Run 'nvm_install' first."
        return 1
    fi
    
    echo "🔄 Updating NVM..."
    local nvm_version="v0.39.4"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    
    # Reload NVM
    nvm_init
    echo "✅ NVM updated successfully"
}

# NVM health check
nvm_healthcheck() {
    echo "🔍 NVM Health Check"
    echo "=================="
    
    if [[ -d "$HOME/.nvm" ]]; then
        echo "✅ NVM directory exists: $HOME/.nvm"
    else
        echo "❌ NVM directory not found"
        echo "💡 Run 'nvm_install' to install NVM"
        return 1
    fi
    
    if command -v nvm &> /dev/null; then
        echo "✅ NVM command available"
        echo "📌 NVM version: $(nvm --version 2>/dev/null || echo 'unknown')"
        
        local current_node="$(nvm current 2>/dev/null || echo 'none')"
        echo "📌 Current Node.js: $current_node"
        
        if [[ "$current_node" != "none" ]]; then
            echo "📌 Node.js version: $(node --version 2>/dev/null || echo 'unknown')"
            echo "📌 NPM version: $(npm --version 2>/dev/null || echo 'unknown')"
        fi
        
        echo "📋 Installed Node.js versions:"
        nvm list 2>/dev/null || echo "  (none)"
    else
        echo "❌ NVM command not available"
        echo "💡 Try restarting your terminal or running 'source ~/.zshrc'"
        return 1
    fi
    
    echo "✅ NVM health check completed"
}

# Initialize NVM if available
if nvm_init; then
    # Set up auto-switching on directory change
    if [[ "$NVM_AUTO_USE" == "true" ]]; then
        chpwd_functions+=(nvm_auto_use)
        
        # Check current directory on shell start
        nvm_auto_use
    fi
    
    # Export Node.js related variables for VS Code
    if command -v node &> /dev/null; then
        export NODE_PATH="$(npm root -g 2>/dev/null)"
        export NVM_BIN="$NVM_DIR/versions/node/$(nvm current)/bin"
        export NVM_INC="$NVM_DIR/versions/node/$(nvm current)/include/node"
    fi
fi

# Aliases for convenience
alias nvm-install="nvm_install"
alias nvm-update="nvm_update"
alias nvm-health="nvm_healthcheck"
alias nvm-check="nvm_healthcheck"
