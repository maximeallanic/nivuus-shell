#!/usr/bin/env zsh
# =============================================================================
# Custom Functions
# =============================================================================
# Useful utility functions
# =============================================================================

# Create and enter a temporary directory
tmpcd() {
    local tmpdir=$(mktemp -d)
    cd "$tmpdir" || return 1
    echo "Created temporary directory: $tmpdir"
}

# Find and replace in files
replace() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: replace <search> <replace> [path]"
        echo "Example: replace 'foo' 'bar' ."
        return 1
    fi

    local search="$1"
    local replace="$2"
    local path="${3:-.}"

    if command -v rg &>/dev/null; then
        # Use ripgrep if available
        rg -l "$search" "$path" | xargs sed -i "s/$search/$replace/g"
    else
        # Fallback to find + grep + sed
        grep -rl "$search" "$path" | xargs sed -i "s/$search/$replace/g"
    fi

    echo "✓ Replaced '$search' with '$replace' in $path"
}

# Show file count in directory
count() {
    local dir="${1:-.}"
    echo "Files: $(find "$dir" -type f | wc -l)"
    echo "Directories: $(find "$dir" -type d | wc -l)"
}

# Make script executable and open in editor
editx() {
    if [[ -z "$1" ]]; then
        echo "Usage: editx <script>"
        return 1
    fi

    local script="$1"

    # Create if doesn't exist
    if [[ ! -f "$script" ]]; then
        echo "#!/usr/bin/env bash" > "$script"
    fi

    # Make executable
    chmod +x "$script"

    # Open in editor
    $EDITOR "$script"
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"

    if command -v python3 &>/dev/null; then
        echo "Serving on http://localhost:$port"
        python3 -m http.server "$port"
    elif command -v python &>/dev/null; then
        echo "Serving on http://localhost:$port"
        python -m SimpleHTTPServer "$port"
    else
        echo "✗ Python not found"
        return 1
    fi
}

# Process management
psgrep() {
    if [[ -z "$1" ]]; then
        echo "Usage: psgrep <process>"
        return 1
    fi

    ps aux | grep -i "$1" | grep -v grep
}

# Kill process by name
killp() {
    if [[ -z "$1" ]]; then
        echo "Usage: killp <process>"
        return 1
    fi

    pkill -i "$1"
}

# Memory usage of a process
memof() {
    if [[ -z "$1" ]]; then
        echo "Usage: memof <process>"
        return 1
    fi

    ps aux | grep -i "$1" | grep -v grep | awk '{print $6}'
}

# Show PATH in readable format
path() {
    echo "$PATH" | tr ':' '\n' | nl
}

# Add to PATH
addpath() {
    if [[ -z "$1" ]]; then
        echo "Usage: addpath <directory>"
        return 1
    fi

    if [[ ! -d "$1" ]]; then
        echo "✗ Directory '$1' does not exist"
        return 1
    fi

    export PATH="$1:$PATH"
    echo "✓ Added '$1' to PATH"
}

# =============================================================================
# Encode/Decode
# =============================================================================

# Base64 encode
b64encode() {
    if [[ -z "$1" ]]; then
        echo "Usage: b64encode <string>"
        return 1
    fi

    echo -n "$1" | base64
}

# Base64 decode
b64decode() {
    if [[ -z "$1" ]]; then
        echo "Usage: b64decode <base64-string>"
        return 1
    fi

    echo "$1" | base64 -d
}

# URL encode
urlencode() {
    if [[ -z "$1" ]]; then
        echo "Usage: urlencode <string>"
        return 1
    fi

    python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))"
}

# =============================================================================
# JSON/YAML
# =============================================================================

# Pretty print JSON
json() {
    if command -v jq &>/dev/null; then
        jq '.' "$@"
    elif command -v python3 &>/dev/null; then
        python3 -m json.tool "$@"
    else
        echo "✗ Neither jq nor python3 found"
        return 1
    fi
}

# =============================================================================
# Disk Usage
# =============================================================================

# Show largest files/directories
largest() {
    local count="${1:-10}"
    du -ah . | sort -rh | head -n "$count"
}
