# =============================================================================
# PATH FINAL CLEANUP - LOADS LAST
# =============================================================================

# This module loads LAST (99-xxx) to fix any PATH corruption that happened
# during the loading of other modules or external tools

echo "🔍 Final PATH cleanup check..."

# Function to completely rebuild PATH from scratch
final_path_fix() {
    local clean_path=""
    
    # Essential system paths (absolute order)
    local essential_paths=(
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
        "/usr/local/sbin"
    )
    
    # Build clean base PATH
    for path in "${essential_paths[@]}"; do
        if [[ -d "$path" ]]; then
            if [[ -z "$clean_path" ]]; then
                clean_path="$path"
            else
                clean_path="$clean_path:$path"
            fi
        fi
    done
    
    # Add user paths
    if [[ -d "$HOME/.local/bin" ]]; then
        clean_path="$HOME/.local/bin:$clean_path"
    fi
    
    # Add NVM Node.js if available
    if [[ -d "$HOME/.nvm/versions/node/v22.16.0/bin" ]]; then
        clean_path="$HOME/.nvm/versions/node/v22.16.0/bin:$clean_path"
    fi
    
    # Add Google Cloud SDK
    if [[ -d "$HOME/google-cloud-sdk/bin" ]]; then
        clean_path="$clean_path:$HOME/google-cloud-sdk/bin"
    fi
    
    # Add snap
    if [[ -d "/snap/bin" ]]; then
        clean_path="$clean_path:/snap/bin"
    fi
    
    export PATH="$clean_path"
}

# Check if PATH is corrupted
if [[ "$PATH" == *"Unknown command"* ]] || \
   [[ "$PATH" == *"share/man"* ]] || \
   [[ "$PATH" == *"::"* ]] || \
   [[ -z "$PATH" ]] || \
   ! command -v ls >/dev/null 2>&1 || \
   ! command -v cat >/dev/null 2>&1 || \
   ! command -v sed >/dev/null 2>&1; then
    
    echo "🚨 Final PATH corruption detected - applying emergency fix"
    final_path_fix
    echo "✅ PATH fixed: $PATH"
    
    # Verify fix
    if command -v ls >/dev/null 2>&1 && command -v cat >/dev/null 2>&1 && command -v sed >/dev/null 2>&1; then
        echo "✅ All essential commands now available"
    else
        echo "❌ PATH fix failed - manual intervention required"
    fi
else
    echo "💚 PATH is healthy"
fi
