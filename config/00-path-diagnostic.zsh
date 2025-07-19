#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# PATH DIAGNOSTIC AND CORRECTION - CRITICAL PRIORITY
# =============================================================================

# CRITICAL: This module MUST load first to fix PATH corruption issues
# This prevents "command not found" errors for basic commands like sed, cat, ls

# Function to clean and rebuild PATH
fix_corrupted_path() {
    local clean_path=""
    local seen_paths=()
    
    # Base system paths (in order of priority)
    local base_paths=(
        "/usr/local/bin"
        "/usr/bin" 
        "/bin"
        "/usr/sbin"
        "/sbin"
        "/usr/local/sbin"
    )
    
    # Add base paths first
    for path in "${base_paths[@]}"; do
        if [[ -d "$path" ]]; then
            clean_path="$path:$clean_path"
            seen_paths+=("$path")
        fi
    done
    
    # Add other important paths if they exist
    local additional_paths=(
        "/snap/bin"
        "$HOME/.local/bin"
        "/usr/local/go/bin"
    )
    
    for path in "${additional_paths[@]}"; do
        if [[ -d "$path" ]] && [[ ! " ${seen_paths[@]} " =~ " $path " ]]; then
            clean_path="$clean_path:$path"
            seen_paths+=("$path")
        fi
    done
    
    # Process existing PATH to preserve other valid entries
    if [[ -n "$PATH" ]]; then
        local -a existing_paths
        existing_paths=(${(s/:/)PATH})
        for path in "${existing_paths[@]}"; do
            # Skip if empty, already added, or contains problematic content
            if [[ -n "$path" ]] && \
               [[ ! " ${seen_paths[@]} " =~ " $path " ]] && \
               [[ "$path" != *"share/man"* ]] && \
               [[ "$path" != *"Unknown command"* ]] && \
               [[ -d "$path" ]] && \
               [[ "$path" =~ ^/ ]]; then
                clean_path="$clean_path:$path"
                seen_paths+=("$path")
            fi
        done
    fi
    
    # Remove leading/trailing colons and double colons
    clean_path="${clean_path#:}"
    clean_path="${clean_path%:}"
    clean_path="${clean_path//::/:}"
    
    export PATH="$clean_path"
}

# Diagnostic function
diagnose_path() {
    echo "=== PATH DIAGNOSTIC ==="
    echo "Original PATH: $PATH"
    echo "PATH length: ${#PATH}"
    
    # Check for problematic entries
    if [[ "$PATH" == *"share/man"* ]]; then
        echo "⚠️  Found problematic 'share/man' in PATH"
    fi
    
    if [[ "$PATH" == *"Unknown command"* ]]; then
        echo "⚠️  Found 'Unknown command' in PATH"
    fi
    
    # Count PATH entries
    local path_count=$(echo "$PATH" | tr ':' '\n' | wc -l)
    echo "PATH entries count: $path_count"
    
    # Check for duplicates
    local unique_count=$(echo "$PATH" | tr ':' '\n' | sort -u | wc -l)
    if [[ $path_count -ne $unique_count ]]; then
        echo "⚠️  Found $((path_count - unique_count)) duplicate PATH entries"
    fi
    
    # Test essential commands
    local missing_commands=()
    for cmd in ls cat sed grep awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo "❌ Missing commands: ${missing_commands[*]}"
        return 1
    else
        echo "✅ All essential commands available"
        return 0
    fi
}

# Auto-fix PATH corruption (ALWAYS fix if corrupted)
# echo "🔧 Checking PATH integrity..."  # Commented out to reduce verbosity

# Force fix if PATH contains known problematic patterns
if [[ "$PATH" == *"Unknown command"* ]] || [[ "$PATH" == *"share/man"* ]] || [[ "$PATH" == *"::"* ]]; then
    # Emergency clean PATH (silent fix)
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/home/mallanic/.local/bin"
    
    # Add NVM if available
    if [[ -d "$HOME/.nvm/versions/node/v22.16.0/bin" ]]; then
        export PATH="$HOME/.nvm/versions/node/v22.16.0/bin:$PATH"
    fi
    
    # Add Google Cloud SDK if available  
    if [[ -d "$HOME/google-cloud-sdk/bin" ]]; then
        export PATH="$PATH:$HOME/google-cloud-sdk/bin"
    fi
    
    # Add snap if available
    if [[ -d "/snap/bin" ]]; then
        export PATH="$PATH:/snap/bin"
    fi
elif ! diagnose_path >/dev/null 2>&1; then
    fix_corrupted_path
    
    # Verify fix worked (silent check)
    if ! diagnose_path >/dev/null 2>&1; then
        # Emergency fallback PATH
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin"
    fi
else
    # echo "✅ PATH is healthy"  # Commented out to reduce verbosity
fi

# Functions are available globally in ZSH by default
# No need to export them explicitly
