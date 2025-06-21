#!/usr/bin/env zsh
# shell: zsh
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
        source "$NVM_DIR/nvm.sh"
    else
        return 1
    fi
    
    # Load bash completion for NVM
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        source "$NVM_DIR/bash_completion"
    fi
    
    return 0
}

# Auto-switch Node.js version based on .nvmrc or package.json
nvm_auto_use() {
    if ! command -v nvm &> /dev/null; then
        return 0
    fi
    
    # Track current directory to avoid unnecessary operations
    local current_dir
    current_dir="$(pwd)"
    
    # Check if directory actually changed
    if [[ -n "$_NIVUUS_LAST_PWD" && "$current_dir" == "$_NIVUUS_LAST_PWD" ]]; then
        return 0  # Same directory, do nothing
    fi
    
    # Update last directory
    export _NIVUUS_LAST_PWD="$current_dir"
    
    local nvmrc_path
    nvmrc_path="$current_dir/.nvmrc"
    local package_json_path
    package_json_path="$current_dir/package.json"
    local current_version
    current_version="$(nvm current 2>/dev/null || echo 'none')"
    
    # Priority 1: Check for .nvmrc file
    if [[ -f "$nvmrc_path" ]]; then
        local nvmrc_version
        nvmrc_version="$(cat "$nvmrc_path")"
        
        # Only switch if different version
        if [[ "$nvmrc_version" != "$current_version" ]]; then
            if nvm list "$nvmrc_version" &> /dev/null; then
                if nvm use "$nvmrc_version" --silent; then
                    echo "📦 Node.js $nvmrc_version loaded from .nvmrc"
                    nvm_fix_path
                else
                    echo "⚠️  Failed to activate Node.js $nvmrc_version"
                fi
            else
                echo "📦 Node.js version $nvmrc_version not installed."
                # Only auto-install if explicitly enabled
                if [[ "$NVM_AUTO_INSTALL" == "true" ]] || [[ -f "$HOME/.nvm_auto_install" ]]; then
                    echo "📦 Installing Node.js version $nvmrc_version..."
                    if nvm install "$nvmrc_version"; then
                        if nvm use "$nvmrc_version" --silent; then
                            echo "📦 Node.js $nvmrc_version installed and loaded"
                            nvm_fix_path
                        else
                            echo "⚠️  Failed to activate installed Node.js $nvmrc_version"
                        fi
                    else
                        echo "⚠️  Failed to install Node.js $nvmrc_version"
                    fi
                else
                    echo "   Run 'nvm install $nvmrc_version' to install it"
                    echo "   Or set NVM_AUTO_INSTALL=true to enable automatic installation"
                fi
            fi
        fi
    # Priority 2: Check for package.json and ensure Node.js is loaded
    elif [[ -f "$package_json_path" ]]; then
        # Check if we need to switch based on package.json requirements
        if required_major_version=$(get_package_json_node_version); then
            # Get current major version
            local current_major
            current_major=""
            if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
                current_major=$(echo "$current_version" | sed 's/v//' | cut -d. -f1)
            fi
            
            # Switch if current major version doesn't match required
            if [[ "$current_major" != "$required_major_version" ]]; then
                echo "📦 Node.js v${required_major_version}.x required for package.json"
                
                # Check if version is available first
                if nvm list | grep -q "v${required_major_version}"; then
                    # Version is available, just switch to it
                    if nvm use "${required_major_version}"; then
                        echo "✅ Node.js v${required_major_version}.x activated"
                        nvm_fix_path
                    fi
                else
                    # Version not installed
                    if [[ "$NVM_AUTO_INSTALL" == "true" ]] || [[ -f "$HOME/.nvm_auto_install" ]]; then
                        echo "📦 Installing Node.js v${required_major_version}.x..."
                        if nvm install "${required_major_version}" 2>/dev/null; then
                            if nvm use "${required_major_version}"; then
                                echo "✅ Node.js v${required_major_version}.x installed and activated"
                                nvm_fix_path
                            fi
                        fi
                    else
                        echo "   Node.js v${required_major_version}.x not installed"
                        echo "   Run 'nvm install ${required_major_version}' to install it"
                        echo "   Or set NVM_AUTO_INSTALL=true to enable automatic installation"
                    fi
                fi
            else
                echo "✅ Node.js v${current_major}.x already matches requirement"
            fi
        else
            # No engines specified, ensure Node.js is loaded
            if [[ "$current_version" == "none" ]] || [[ "$current_version" == "system" ]]; then
                echo "📦 Loading Node.js for project..."
                
                if nvm use default 2>/dev/null; then
                    echo "✅ Node.js default version loaded"
                    nvm_fix_path
                elif nvm use --lts 2>/dev/null; then
                    echo "✅ Node.js LTS version loaded"
                    nvm_fix_path
                else
                    echo "📦 Installing Node.js LTS..."
                    if nvm install --lts 2>/dev/null && nvm use --lts 2>/dev/null; then
                        nvm alias default "lts/*" 2>/dev/null
                        echo "✅ Node.js LTS installed and loaded"
                        nvm_fix_path
                    else
                        echo "⚠️  Failed to install Node.js LTS"
                    fi
                fi
                
                # Verify that node is actually available after any switch
                if ! command -v node &> /dev/null; then
                    echo "🔧 Fixing Node.js PATH..."
                    nvm_fix_path
                    
                    # If still not available, suggest reload
                    if ! command -v node &> /dev/null; then
                        echo "⚠️  Node.js not available - run 'nvm-reload'"
                    fi
                fi
            fi
        fi
        
        # Show package manager info only if Node.js is now available
        if command -v node &> /dev/null; then
            # echo "📦 Node.js project detected"  # Commented out to reduce verbosity
            if [[ -f "yarn.lock" ]]; then
                # echo "   Package manager: Yarn"
                # echo "   Suggested commands: yarn install, yarn start, yarn test"
                :  # No-op
            elif [[ -f "pnpm-lock.yaml" ]]; then
                # echo "   Package manager: PNPM"
                # echo "   Suggested commands: pnpm install, pnpm start, pnpm test"
                :  # No-op
            else
                # echo "   Package manager: NPM"
                # echo "   Suggested commands: npm install, npm start, npm test"
                :  # No-op
            fi
        fi
    # Priority 3: No project files, ensure we have a default version
    elif [[ "$current_version" == "none" ]] || [[ "$current_version" == "system" ]]; then
        # Use default version if no .nvmrc, no package.json and no version selected
        if nvm use default --silent 2>/dev/null; then
            # Silent load, no message needed for non-project directories
            true
        elif nvm use --lts --silent 2>/dev/null; then
            # Silent load, no message needed for non-project directories
            true
        fi
    fi
}

# Show Node.js project status
nvm_project_status() {
    if is_node_project; then
        # echo "📦 Node.js Project Detected"  # Commented out to reduce verbosity
        # echo "========================="   # Commented out to reduce verbosity
        
        if [[ -f ".nvmrc" ]]; then
            echo "📌 Required Node.js version (.nvmrc): $(cat .nvmrc)"
        fi
        
        if [[ -f "package.json" ]]; then
            # Try to get engines.node with better parsing
            local engines_raw engines_display
            if command -v node &> /dev/null; then
                engines_raw=$(node -p "
                    try {
                        const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
                        pkg.engines?.node || '';
                    } catch (e) {
                        '';
                    }
                " 2>/dev/null)
            else
                engines_raw=$(grep -A 10 '"engines"' package.json 2>/dev/null | grep '"node"' | sed -E 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | head -1)
            fi
            
            if [[ -n "$engines_raw" && "$engines_raw" != "undefined" ]]; then
                engines_display="$engines_raw"
                
                # Show which major version would be selected
                local major_version
                if major_version=$(get_package_json_node_version); then
                    engines_display="$engines_raw (→ v${major_version}.x)"
                fi
            else
                engines_display="Not specified"
            fi
            
            echo "📌 Package.json Node.js engines: $engines_display"
        fi
        
        local current_node
        current_node="$(nvm current 2>/dev/null || echo 'none')"
        echo "📌 Current Node.js: $current_node"
        
        if [[ "$current_node" != "none" ]]; then
            echo "📌 Node.js version: $(node --version 2>/dev/null || echo 'unknown')"
            echo "📌 NPM version: $(npm --version 2>/dev/null || echo 'unknown')"
            
            # Check if current version matches package.json requirement
            if [[ -f "package.json" ]]; then
                local required_major
                if required_major=$(get_package_json_node_version); then
                    local current_major
                    current_major="$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)"
                    if [[ "$current_major" == "$required_major" ]]; then
                        echo "✅ Version matches package.json requirement"
                    else
                        echo "⚠️  Version mismatch! Required: v${required_major}.x, Current: v${current_major}.x"
                    fi
                fi
            fi
        else
            echo "⚠️  No Node.js version active!"
        fi
    else
        echo "ℹ️  Not a Node.js project"
    fi
}

# Extract Node.js version from package.json engines field
get_package_json_node_version() {
    if [[ ! -f "package.json" ]]; then
        return 1
    fi
    
    local engines_node
    # Try to extract engines.node using different methods
    if command -v node &> /dev/null; then
        # If node is available, use it to parse JSON
        engines_node=$(node -p "
            try {
                const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
                pkg.engines?.node || '';
            } catch (e) {
                '';
            }
        " 2>/dev/null)
    else
        # Fallback to basic grep/sed parsing
        engines_node=$(grep -A 10 '"engines"' package.json 2>/dev/null | grep '"node"' | sed -E 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | head -1)
    fi
    
    if [[ -n "$engines_node" && "$engines_node" != "undefined" ]]; then
        # Convert version range to specific version
        # Handle common patterns: ">=18.0.0", "^18.0.0", "~18.0.0", "18", "18.x"
        local clean_version
        clean_version=$(echo "$engines_node" | sed -E 's/[>=^~]//g' | sed -E 's/\.x$/.0/' | sed -E 's/^([0-9]+)$/\1.0.0/' | sed -E 's/^([0-9]+\.[0-9]+)$/\1.0/')
        
        # Extract major version for LTS matching
        local major_version
        major_version="$(echo "$clean_version" | cut -d. -f1)"
        
        echo "$major_version"
        return 0
    fi
    
    return 1
}

# Force NVM reinitialization and fix common issues
nvm_force_reload() {
    local silent_mode
    silent_mode="${1:-false}"
    
    if [[ "$silent_mode" != "true" ]]; then
        echo "🔄 Force reloading NVM..."
    fi
    
    # Re-source NVM
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        if [[ "$silent_mode" != "true" ]]; then
            echo "✅ NVM script reloaded"
        fi
    fi
    
    # Get current version
    local current_version
    current_version="$(nvm current 2>/dev/null || echo 'none')"
    if [[ "$silent_mode" != "true" ]]; then
        echo "📌 Current Node.js after reload: $current_version"
    fi
    
    # If still none, try to activate appropriate version for current directory
    if [[ "$current_version" == "none" ]] || [[ "$current_version" == "system" ]]; then
        local activated=false
        
        # Check if we're in a project directory
        if [[ -f "package.json" ]]; then
            if required_major_version=$(get_package_json_node_version); then
                if nvm use "${required_major_version}" 2>/dev/null; then
                    current_version="$(nvm current 2>/dev/null)"
                    if [[ "$silent_mode" != "true" ]]; then
                        echo "✅ Activated Node.js v${required_major_version}.x for project: $current_version"
                    fi
                    activated=true
                fi
            fi
        elif [[ -f ".nvmrc" ]]; then
            local nvmrc_version
            nvmrc_version="$(cat .nvmrc)"
            if nvm use "$nvmrc_version" 2>/dev/null; then
                current_version="$(nvm current 2>/dev/null)"
                if [[ "$silent_mode" != "true" ]]; then
                    echo "✅ Activated Node.js from .nvmrc: $current_version"
                fi
                activated=true
            fi
        fi
        
        # Fallback to default/LTS if no project-specific version
        if [[ "$activated" == "false" ]]; then
            if nvm use default 2>/dev/null; then
                current_version="$(nvm current 2>/dev/null)"
                if [[ "$silent_mode" != "true" ]]; then
                    echo "✅ Activated default version: $current_version"
                fi
            elif nvm use --lts 2>/dev/null; then
                current_version="$(nvm current 2>/dev/null)"
                if [[ "$silent_mode" != "true" ]]; then
                    echo "✅ Activated LTS version: $current_version"
                fi
            fi
        fi
    fi
    
    # Fix PATH if needed
    if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
        if [[ "$silent_mode" == "true" ]]; then
            nvm_fix_path_silent
        else
            nvm_fix_path
        fi
    fi
    
    # Final verification
    if command -v node &> /dev/null; then
        if [[ "$silent_mode" != "true" ]]; then
            echo "✅ Node.js is now available: $(node --version)"
            echo "✅ NPM is now available: $(npm --version)"
        fi
    else
        if [[ "$silent_mode" != "true" ]]; then
            echo "⚠️  Node.js still not available after reload"
        fi
    fi
}

# Fix Node.js PATH if needed (silent version)
nvm_fix_path_silent() {
    if command -v nvm &> /dev/null; then
        local current_version
        current_version="$(nvm current 2>/dev/null)"
        
        # If no version is active, try to activate default/LTS first
        if [[ "$current_version" == "none" ]] || [[ "$current_version" == "system" ]]; then
            if nvm use default 2>&1; then
                current_version="$(nvm current 2>/dev/null)"
            elif nvm use --lts 2>&1; then
                current_version="$(nvm current 2>/dev/null)"
            else
                return 1
            fi
        fi
        
        # Now fix the PATH
        if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
            local node_bin_path
            node_bin_path="$NVM_DIR/versions/node/$current_version/bin"
            if [[ -d "$node_bin_path" ]]; then
                # Remove any existing node paths to avoid duplicates
                PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/node/' | tr '\n' ':' | sed 's/:$//')
                export PATH
                # Add current node version to PATH at the beginning
                export PATH="$node_bin_path:$PATH"
                
                # Force update of the current shell's PATH
                hash -r 2>/dev/null || true
                
                return 0
            fi
        fi
    fi
    return 1
}

# Fix Node.js PATH if needed
nvm_fix_path() {
    if command -v nvm &> /dev/null; then
        local current_version
        current_version="$(nvm current 2>/dev/null)"
        
        # If no version is active, try to activate default/LTS first
        if [[ "$current_version" == "none" ]] || [[ "$current_version" == "system" ]]; then
            if nvm use default 2>&1; then
                current_version="$(nvm current 2>/dev/null)"
                echo "🔧 Activated default Node.js version: $current_version"
            elif nvm use --lts 2>&1; then
                current_version="$(nvm current 2>/dev/null)"
                echo "🔧 Activated LTS Node.js version: $current_version"
            else
                echo "⚠️  No valid Node.js version to add to PATH"
                return 1
            fi
        fi
        
        # Now fix the PATH
        if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
            local node_bin_path
            node_bin_path="$NVM_DIR/versions/node/$current_version/bin"
            if [[ -d "$node_bin_path" ]]; then
                # Remove any existing node paths to avoid duplicates
                PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/node/' | tr '\n' ':' | sed 's/:$//')
                export PATH
                # Add current node version to PATH at the beginning
                export PATH="$node_bin_path:$PATH"
                
                # Force update of the current shell's PATH
                hash -r 2>/dev/null || true
                
                echo "🔧 Node.js PATH updated for version $current_version"
                echo "🔧 Node.js bin path: $node_bin_path"
                
                # Verify the fix worked
                if command -v node &> /dev/null; then
                    echo "✅ Node.js is now available: $(node --version)"
                    echo "✅ NPM is now available: $(npm --version)"
                    return 0
                else
                    echo "⚠️  Node.js still not available after PATH update"
                    echo "🔧 Current PATH (first 5 entries):"
                    echo "$PATH" | tr ':' '\n' | head -5
                    return 1
                fi
            else
                echo "⚠️  Node.js bin directory not found: $node_bin_path"
                return 1
            fi
        else
            echo "⚠️  No valid Node.js version to add to PATH"
            return 1
        fi
    else
        echo "⚠️  NVM command not available"
        return 1
    fi
}

# Check if current directory is a Node.js project
is_node_project() {
    [[ -f "package.json" ]] || [[ -f ".nvmrc" ]] || [[ -f "yarn.lock" ]] || [[ -f "pnpm-lock.yaml" ]] || [[ -d "node_modules" ]]
}

# NVM quick installation function
nvm_install() {
    if [[ -d "$HOME/.nvm" ]]; then
        echo "✅ NVM already installed"
        return 0
    fi
    
    echo "📦 Installing NVM..."
    local nvm_version
    nvm_version="v0.39.4"
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
    local nvm_version
    nvm_version="v0.39.4"
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
        
        local current_node
        current_node="$(nvm current 2>/dev/null || echo 'none')"
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

# Force NVM initialization
# Try multiple initialization strategies to ensure NVM loads properly

# Strategy 1: Check if NVM_DIR is already set and try to reload
if [[ -n "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        source "$NVM_DIR/bash_completion"
    fi
fi

# Strategy 2: Initialize NVM if not already done
if ! command -v nvm &> /dev/null; then
    nvm_init 2>/dev/null || true
fi

# Strategy 3: Fallback - Direct initialization from standard paths
if ! command -v nvm &> /dev/null; then
    for nvm_dir in "$HOME/.nvm" "/usr/local/nvm" "/opt/nvm"; do
        if [[ -s "$nvm_dir/nvm.sh" ]]; then
            export NVM_DIR="$nvm_dir"
            source "$nvm_dir/nvm.sh"
            if [[ -s "$nvm_dir/bash_completion" ]]; then
                source "$nvm_dir/bash_completion"
            fi
            break
        fi
    done
fi

# Set up auto-switching functionality if NVM is available
if command -v nvm &> /dev/null; then
    # Ensure a Node.js version is always loaded by default
    current_node="$(nvm current 2>/dev/null || echo 'none')"
    
    # Only try to activate if no version is currently active AND no node binary is available
    if [[ "$current_node" == "none" ]] || [[ "$current_node" == "system" ]] || ! command -v node &> /dev/null; then
        # Check if we already have Node.js available (might be globally installed)
        if command -v node &> /dev/null; then
            # Node.js is available, just not through NVM - that's fine
            true
        else
            # Try to activate existing Node.js versions first
            echo "📦 Activating Node.js for shell session..."
            if nvm use default --silent 2>/dev/null; then
                echo "✅ Node.js default version loaded"
            elif nvm use --lts --silent 2>/dev/null; then
                echo "✅ Node.js LTS version loaded"
            elif nvm use node --silent 2>/dev/null; then
                echo "✅ Node.js stable version loaded"
            else
                # Only install if user explicitly wants it (check for a flag file)
                if [[ -f "$HOME/.nvm_auto_install" ]] || [[ "$NVM_AUTO_INSTALL" == "true" ]]; then
                    echo "📦 Installing Node.js LTS for default use..."
                    if nvm install --lts && nvm use --lts; then
                        nvm alias default "lts/*"
                        echo "✅ Node.js LTS installed and loaded"
                    fi
                else
                    echo "⚠️  No Node.js versions available. Run 'nvm install --lts' to install"
                    echo "   Or set NVM_AUTO_INSTALL=true to enable automatic installation"
                fi
            fi
        fi
        
        # Fix PATH if needed and Node.js was activated
        if command -v nvm &> /dev/null && [[ "$(nvm current 2>/dev/null)" != "none" ]]; then
            node_version="$(nvm current 2>/dev/null)"
            if [[ "$node_version" != "none" && "$node_version" != "system" ]] && ! command -v node &> /dev/null; then
                node_bin_path="$NVM_DIR/versions/node/$node_version/bin"
                if [[ -d "$node_bin_path" ]]; then
                    export PATH="$node_bin_path:$PATH"
                    hash -r 2>/dev/null || true
                    echo "🔧 Node.js PATH updated for version $node_version"
                fi
            fi
        fi
        
        # Final verification (only show if we tried to activate something)
        if command -v node &> /dev/null; then
            node_ver="$(node --version 2>/dev/null)"
            npm_ver="$(npm --version 2>/dev/null)"
            echo "✅ Node.js is now available: $node_ver"
            [[ -n "$npm_ver" ]] && echo "✅ NPM is now available: $npm_ver"
        fi
    else
        # Node.js already active - silent check
        # Even if already active, ensure commands are available
        if ! command -v node &> /dev/null; then
            node_bin_path="$NVM_DIR/versions/node/$current_node/bin"
            if [[ -d "$node_bin_path" ]]; then
                export PATH="$node_bin_path:$PATH"
                hash -r 2>/dev/null || true
            fi
        fi
    fi
    
    # Set up auto-switching on directory change
    if [[ "$NVM_AUTO_USE" == "true" ]]; then
        # Remove any existing nvm_auto_use from chpwd_functions to avoid duplicates
        chpwd_functions=("${chpwd_functions[@]:#nvm_auto_use}")
        chpwd_functions+=(nvm_auto_use)
        
        # Initialize directory tracking and check current directory on shell start
        export _NIVUUS_LAST_PWD=""
        
        # Force immediate check of current directory on shell startup
        nvm_auto_use
        
        # If we're in a project but no Node.js is active, force reload
        if [[ -f "package.json" || -f ".nvmrc" ]] && ! command -v node &> /dev/null; then
            nvm_force_reload true  # Silent mode
        fi
    fi
    
    # Debug: Show NVM status on shell start (optional)
    if [[ "$SHELL_DEBUG" == "true" ]]; then
        echo "🔧 NVM initialized: $(nvm current 2>/dev/null || echo 'none')"
    fi
else
    # If NVM still not available, show helpful message once per session
    if [[ -z "$_NVM_WARNING_SHOWN" ]]; then
        echo "⚠️  NVM not available. Run 'nvm_healthcheck' for diagnostics."
        export _NVM_WARNING_SHOWN=1
    fi
fi

# Export Node.js related variables for VS Code (only if NVM is available)
if command -v nvm &> /dev/null && command -v node &> /dev/null; then
    NODE_PATH="$(npm root -g 2>/dev/null)"
    export NODE_PATH
    NVM_BIN="$NVM_DIR/versions/node/$(nvm current)/bin"
    export NVM_BIN
    NVM_INC="$NVM_DIR/versions/node/$(nvm current)/include/node"
    export NVM_INC
fi

# NVM debug function
nvm_debug() {
    echo "🔍 NVM Debug Information"
    echo "======================="
    echo "📌 NVM_DIR: ${NVM_DIR:-'not set'}"
    echo "📌 NVM command available: $(command -v nvm &> /dev/null && echo 'yes' || echo 'no')"
    echo "📌 Current directory: $(pwd)"
    echo "📌 Package.json exists: $([[ -f 'package.json' ]] && echo 'yes' || echo 'no')"
    echo "📌 .nvmrc exists: $([[ -f '.nvmrc' ]] && echo 'yes' || echo 'no')"
    
    if command -v nvm &> /dev/null; then
        echo "📌 Current Node.js: $(nvm current 2>/dev/null || echo 'none')"
        echo "📌 Available versions:"
        nvm list --no-colors 2>/dev/null | head -10 || echo "  (none)"
    else
        echo "📌 NVM not initialized"
        if [[ -d "$HOME/.nvm" ]]; then
            echo "📌 NVM directory exists: $HOME/.nvm"
            echo "📌 NVM script exists: $([[ -f "$HOME/.nvm/nvm.sh" ]] && echo 'yes' || echo 'no')"
        else
            echo "📌 NVM directory missing: $HOME/.nvm"
        fi
    fi
    
    echo "📌 PATH contains node: $(echo "$PATH" | grep -q node && echo 'yes' || echo 'no')"
    echo "📌 Which node: $(which node 2>/dev/null || echo 'not found')"
    echo "📌 Which npm: $(which npm 2>/dev/null || echo 'not found')"
}

# Simple function to force Node.js activation
nvm_force_node() {
    echo "🔄 Forcing Node.js activation..."
    
    # Try default first
    if nvm use default; then
        echo "✅ Node.js default version activated"
    elif nvm use --lts; then
        echo "✅ Node.js LTS version activated" 
    elif nvm use node; then
        echo "✅ Node.js stable version activated"
    else
        echo "⚠️  Failed to activate any Node.js version"
        return 1
    fi
    
    # Verify it worked
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        echo "✅ Success! Node.js $(node --version) and NPM $(npm --version) are now available"
        return 0
    else
        echo "⚠️  Node.js activation failed - commands not available"
        return 1
    fi
}

# Aliases for convenience
alias nvm-install="nvm_install"
alias nvm-update="nvm_update"
alias nvm-health="nvm_healthcheck"
alias nvm-check="nvm_healthcheck"
alias nvm-status="nvm_project_status"
alias nvm-debug="nvm_debug"
alias nvm-fix="nvm_fix_path"
alias nvm-reload="nvm_force_reload"
alias nvm-auto-install='bash "${${(%):-%x}:A:h:h}/scripts/nvm-auto-install.sh"'

# Show helpful message on first shell start
if [[ -z "$_NIVUUS_NVM_WELCOME_SHOWN" ]] && command -v nvm &> /dev/null; then
    export _NIVUUS_NVM_WELCOME_SHOWN=1
    if [[ "$NVM_AUTO_INSTALL" != "true" ]] && [[ ! -f "$HOME/.nvm_auto_install" ]]; then
        # echo ""
        # echo "💡 NVM auto-install is disabled. Node.js versions won't be installed automatically."
        # echo "   Run 'nvm-auto-install' to configure this setting."
        # echo "   Or manually install versions with: nvm install --lts"
        # echo ""
        :  # No-op - messages disabled for less verbosity
    fi
fi
alias nvm-activate="nvm_force_node"
alias node-status="nvm_project_status"
