#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# NVM (NODE VERSION MANAGER) CONFIGURATION
# =============================================================================

# NVM Configuration
export NVM_LAZY_LOAD=false          # Disable lazy loading for better VS Code integration
export NVM_AUTO_USE=true            # Automatically use Node version from .nvmrc
export NVM_COMPLETION=true          # Enable command completion

# Suppress npm warnings
export NPM_CONFIG_LOGLEVEL=warn      # Reduce npm verbosity
export NPM_CONFIG_UPDATE_NOTIFIER=false   # Disable update notifier

# Suppress deprecated npm config warnings
suppress_npm_warnings() {
    if command -v npm &> /dev/null; then
        # Create/update .npmrc to suppress deprecated warnings
        local npmrc_file="$HOME/.npmrc"

        # Create file if it doesn't exist
        if [[ ! -f "$npmrc_file" ]]; then
            touch "$npmrc_file"
        fi

        # Add each setting only if not already present (avoid duplicates)
        if ! grep -q "^fund=false" "$npmrc_file" 2>/dev/null; then
            echo "fund=false" >> "$npmrc_file"
        fi

        if ! grep -q "^audit=false" "$npmrc_file" 2>/dev/null; then
            echo "audit=false" >> "$npmrc_file"
        fi

        if ! grep -q "^update-notifier=false" "$npmrc_file" 2>/dev/null; then
            echo "update-notifier=false" >> "$npmrc_file"
        fi
    fi
}

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

# LEGACY: This function is replaced by nvm_auto_use_lazy() in the ultra-lazy loading section
# Kept for backwards compatibility if called manually, but not used in normal operation

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

# Fix Node.js PATH if needed
# Usage: nvm_fix_path [silent]
nvm_fix_path() {
    local silent="${1:-false}"
    command -v nvm &> /dev/null || return 1

    local current_version="$(nvm current 2>/dev/null)"

    # Try to activate if no version is active
    if [[ "$current_version" == "none" || "$current_version" == "system" ]]; then
        if nvm use default 2>&1; then
            current_version="$(nvm current 2>/dev/null)"
            [[ "$silent" != "true" ]] && echo "🔧 Activated default Node.js: $current_version"
        elif nvm use --lts 2>&1; then
            current_version="$(nvm current 2>/dev/null)"
            [[ "$silent" != "true" ]] && echo "🔧 Activated LTS Node.js: $current_version"
        else
            [[ "$silent" != "true" ]] && echo "⚠️  No valid Node.js version to add to PATH"
            return 1
        fi
    fi

    # Fix PATH
    if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
        local node_bin_path="$NVM_DIR/versions/node/$current_version/bin"
        if [[ -d "$node_bin_path" ]]; then
            PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/node/' | tr '\n' ':' | sed 's/:$//')
            export PATH="$node_bin_path:$PATH"
            hash -r 2>/dev/null || true
            return 0
        else
            [[ "$silent" != "true" ]] && echo "⚠️  Node.js bin directory not found: $node_bin_path"
            return 1
        fi
    fi
    return 1
}

# Alias for backwards compatibility
nvm_fix_path_silent() {
    nvm_fix_path true
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

# =============================================================================
# ULTRA-LAZY NVM LOADING - Load NVM itself only when needed
# =============================================================================
#
# CRITICAL OPTIMIZATION: Do NOT load nvm.sh at startup!
# Loading nvm.sh takes ~800ms, which makes it impossible to reach <300ms goal.
#
# Strategy: Create wrapper functions for nvm/node/npm/npx that load NVM
# on first use. This reduces startup time to nearly zero for NVM.

# Set NVM_DIR but don't source nvm.sh yet
if [[ -z "$NVM_DIR" ]]; then
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
    elif [[ -d "/usr/local/nvm" ]]; then
        export NVM_DIR="/usr/local/nvm"
    elif [[ -d "/opt/nvm" ]]; then
        export NVM_DIR="/opt/nvm"
    fi
fi

# Track if NVM has been loaded
export _NIVUUS_NVM_LOADED=false

# Function to actually load NVM (called on first use)
_load_nvm_on_demand() {
    # Check if already loaded
    if [[ "$_NIVUUS_NVM_LOADED" == "true" ]]; then
        return 0
    fi

    # Mark as loaded FIRST to prevent recursion during source
    export _NIVUUS_NVM_LOADED=true

    # Load NVM script
    if [[ -n "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
        # Remove wrapper functions BEFORE sourcing to avoid conflicts
        unfunction nvm node npm npx 2>/dev/null

        # Source with explicit error handling
        if ! source "$NVM_DIR/nvm.sh" 2>&1; then
            echo "⚠️  Failed to load NVM script from: $NVM_DIR/nvm.sh" >&2
            export _NIVUUS_NVM_LOADED=false
            return 1
        fi

        # Load bash completion (optional, don't fail if it doesn't work)
        if [[ -s "$NVM_DIR/bash_completion" ]]; then
            source "$NVM_DIR/bash_completion" 2>/dev/null || true
        fi
    else
        if [[ -z "$NVM_DIR" ]]; then
            echo "⚠️  NVM_DIR is not set" >&2
        else
            echo "⚠️  NVM script not found at: $NVM_DIR/nvm.sh" >&2
        fi
        export _NIVUUS_NVM_LOADED=false
        return 1
    fi

    # NVM is now loaded, but don't activate Node.js yet
    # Let the calling context decide when to activate via _nvm_lazy_load
    return 0
}

# =============================================================================
# LAZY LOADING SETUP - CRITICAL FOR PERFORMANCE <300ms
# =============================================================================
#
# Strategy: NVM is loaded but Node.js is NOT activated at startup.
# Node.js is only loaded when:
# 1. User explicitly runs node/npm/npx commands (via wrappers)
# 2. User enters a Node.js project directory (detected via chpwd hook with cache)
#
# This reduces startup time from ~6s to <100ms

# Track if Node.js has been lazy-loaded
export _NIVUUS_NODE_LAZY_LOADED=false

# Lazy load Node.js on first use
_nvm_lazy_load() {
    # Check if already loaded
    if [[ "$_NIVUUS_NODE_LAZY_LOADED" == "true" ]] && command -v node &> /dev/null; then
        return 0
    fi

    # Mark as loaded to prevent recursion
    export _NIVUUS_NODE_LAZY_LOADED=true

    # Remove wrapper functions to expose real commands
    unfunction node npm npx 2>/dev/null

    # Check if we're in a Node.js project to determine version
    local target_version=""

    # Priority 1: .nvmrc file
    if [[ -f ".nvmrc" ]]; then
        target_version="$(cat .nvmrc)"
        nvm use "$target_version" --silent 2>/dev/null || nvm install "$target_version" >/dev/null 2>&1
    # Priority 2: package.json engines field
    elif [[ -f "package.json" ]]; then
        if target_version=$(get_package_json_node_version); then
            nvm use "${target_version}" --silent 2>/dev/null || {
                if [[ "$NVM_AUTO_INSTALL" == "true" ]] || [[ -f "$HOME/.nvm_auto_install" ]]; then
                    nvm install "${target_version}" >/dev/null 2>&1
                    nvm use "${target_version}" --silent 2>/dev/null
                fi
            }
        else
            # Package.json exists but no engines, use default/LTS/stable
            nvm use default --silent 2>/dev/null || \
            nvm use --lts --silent 2>/dev/null || \
            nvm use node --silent 2>/dev/null || \
            nvm use stable --silent 2>/dev/null
        fi
    # Priority 3: Use default, LTS, or latest stable
    else
        nvm use default --silent 2>/dev/null || \
        nvm use --lts --silent 2>/dev/null || \
        nvm use node --silent 2>/dev/null || \
        nvm use stable --silent 2>/dev/null
    fi

    # Fix PATH if needed
    local current_version="$(nvm current 2>/dev/null)"
    if [[ "$current_version" != "none" && "$current_version" != "system" ]]; then
        local node_bin_path="$NVM_DIR/versions/node/$current_version/bin"
        if [[ -d "$node_bin_path" ]]; then
            # Clean up PATH and add current version
            PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/node/' | tr '\n' ':' | sed 's/:$//')
            export PATH="$node_bin_path:$PATH"
            hash -r 2>/dev/null || true
        fi
    fi

    # Suppress npm warnings
    suppress_npm_warnings

    # Export Node.js related variables for VS Code
    if command -v node &> /dev/null; then
        NODE_PATH="$(npm root -g 2>/dev/null)"
        export NODE_PATH
        NVM_BIN="$NVM_DIR/versions/node/$(nvm current)/bin"
        export NVM_BIN
        NVM_INC="$NVM_DIR/versions/node/$(nvm current)/include/node"
        export NVM_INC
    fi
}

# Wrapper functions that trigger lazy loading of NVM itself
if [[ -n "$NVM_DIR" && -d "$NVM_DIR" ]]; then
    # Create wrapper for nvm command
    nvm() {
        if _load_nvm_on_demand; then
            # NVM loaded successfully, call the real nvm function
            # (which was defined by nvm.sh after we unfunction'd our wrapper)
            nvm "$@"
        else
            # Failed to load NVM
            echo "⚠️  NVM could not be loaded. Run 'nvm_debug' for diagnostics." >&2
            return 1
        fi
    }

    # Create wrappers for Node.js commands that load NVM and activate Node
    node() {
        if _load_nvm_on_demand; then
            # Ensure Node is activated
            if [[ "$_NIVUUS_NODE_LAZY_LOADED" != "true" ]]; then
                _nvm_lazy_load
            fi
        fi
        command node "$@"
    }

    npm() {
        if _load_nvm_on_demand; then
            # Ensure Node is activated
            if [[ "$_NIVUUS_NODE_LAZY_LOADED" != "true" ]]; then
                _nvm_lazy_load
            fi
        fi
        command npm "$@"
    }

    npx() {
        if _load_nvm_on_demand; then
            # Ensure Node is activated
            if [[ "$_NIVUUS_NODE_LAZY_LOADED" != "true" ]]; then
                _nvm_lazy_load
            fi
        fi
        command npx "$@"
    }

    # Optimized auto-switching on directory change
    if [[ "$NVM_AUTO_USE" == "true" ]]; then
        # Initialize tracking variable to current dir to prevent initial hook execution
        # This prevents NVM from loading at shell startup, saving ~1000ms
        export _NIVUUS_LAST_PWD="$(pwd)"

        # Lightweight chpwd hook - loads NVM only when entering Node.js projects
        nvm_auto_use_lazy() {
            local current_dir="$(pwd)"

            # Skip if same directory
            if [[ -n "$_NIVUUS_LAST_PWD" && "$current_dir" == "$_NIVUUS_LAST_PWD" ]]; then
                return 0
            fi

            export _NIVUUS_LAST_PWD="$current_dir"

            # Check for .nvmrc in current dir or parents
            local nvmrc_path=""
            local search_dir="$current_dir"
            while [[ "$search_dir" != "/" ]]; do
                if [[ -f "$search_dir/.nvmrc" ]]; then
                    nvmrc_path="$search_dir/.nvmrc"
                    break
                fi
                search_dir="$(dirname "$search_dir")"
            done

            # Determine if we're in a Node.js project
            local is_node_project=false
            if [[ -n "$nvmrc_path" || -f "package.json" ]]; then
                is_node_project=true
            fi

            # Load NVM if not loaded and we're in a Node.js project
            if [[ "$_NIVUUS_NVM_LOADED" != "true" ]] && [[ "$is_node_project" == "true" ]]; then
                echo "📦 Loading Node.js for project..."
                if _load_nvm_on_demand; then
                    # NVM loaded successfully, now activate Node
                    _nvm_lazy_load
                else
                    echo "⚠️  Failed to load NVM. Run 'nvm_debug' for diagnostics." >&2
                    return 1
                fi
            fi

            # If NVM is loaded, manage versions based on current directory
            if [[ "$_NIVUUS_NVM_LOADED" == "true" ]]; then
                local should_use_default=false

                if [[ -n "$nvmrc_path" ]]; then
                    # Found .nvmrc in current dir or parent - use it
                    local required_version="$(cat "$nvmrc_path")"
                    local current_version="$(nvm current 2>/dev/null)"

                    if [[ "$required_version" != "$current_version" ]]; then
                        if nvm use "$required_version" --silent 2>/dev/null; then
                            nvm_fix_path_silent
                        else
                            echo "⚠️  Required Node.js version $required_version not installed"
                            echo "   Run: nvm install $required_version"
                        fi
                    fi
                elif [[ -f "package.json" ]]; then
                    # No .nvmrc but has package.json - check engines
                    local required_version=$(get_package_json_node_version)
                    if [[ -n "$required_version" ]]; then
                        local current_version="$(nvm current 2>/dev/null)"
                        local current_major="$(echo "$current_version" | sed 's/v//' | cut -d. -f1)"

                        if [[ "$current_major" != "$required_version" ]]; then
                            if nvm use "$required_version" --silent 2>/dev/null; then
                                nvm_fix_path_silent
                            fi
                        fi
                    else
                        # package.json exists but no engines specified - ensure Node is available
                        if [[ "$(nvm current 2>/dev/null)" == "none" || "$(nvm current 2>/dev/null)" == "system" ]]; then
                            should_use_default=true
                        fi
                    fi
                else
                    # No Node project files - use default if available
                    should_use_default=true
                fi

                # Revert to default if needed
                if [[ "$should_use_default" == "true" ]]; then
                    local current_version="$(nvm current 2>/dev/null)"
                    # Try to use a sensible default version
                    if [[ "$current_version" == "none" || "$current_version" == "system" ]]; then
                        # Try default alias first, then LTS, then any installed version
                        if ! nvm use default --silent 2>/dev/null; then
                            if ! nvm use --lts --silent 2>/dev/null; then
                                # Use the latest installed version
                                local latest_version=$(nvm list | grep -v 'default' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                                if [[ -n "$latest_version" ]]; then
                                    nvm use "$latest_version" --silent 2>/dev/null
                                fi
                            fi
                        fi
                        nvm_fix_path_silent
                    fi
                fi
            fi
        }

        # Remove any existing nvm_auto_use from chpwd_functions
        chpwd_functions=("${chpwd_functions[@]:#nvm_auto_use}")
        chpwd_functions=("${chpwd_functions[@]:#nvm_auto_use_lazy}")
        # Add optimized version
        chpwd_functions+=(nvm_auto_use_lazy)
    fi

    # Debug mode
    if [[ "$SHELL_DEBUG" == "true" ]]; then
        echo "🔧 NVM ultra-lazy loading configured"
        echo "   NVM will load on first use of: nvm, node, npm, or npx"
        echo "   Or when entering a Node.js project directory"
    fi
else
    # NVM not available - show warning once per session
    if [[ -z "$_NVM_WARNING_SHOWN" ]]; then
        # Silent by default - only show in debug mode
        if [[ "$SHELL_DEBUG" == "true" ]]; then
            echo "⚠️  NVM not found. Run 'nvm_healthcheck' for diagnostics."
        fi
        export _NVM_WARNING_SHOWN=1
    fi
fi

# Export Node.js related variables for VS Code (only after lazy load)
# NOTE: These are set dynamically after _nvm_lazy_load is called
# Removed from startup to maintain <300ms performance target

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

# Apply npm warning suppression
suppress_npm_warnings
