#!/bin/bash

# =============================================================================
# NIVUUS SHELL - DOCUMENTATION UPDATER
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly README_FILE="$PROJECT_ROOT/README.md"

# Get current version
CURRENT_VERSION=$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "unknown")

# Update installation commands in README
update_readme_installation() {
    if [[ ! -f "$README_FILE" ]]; then
        echo "⚠️  README.md not found, skipping update"
        return
    fi
    
    echo "📝 Updating README.md installation commands..."
    
    # Update curl command to use latest release
    sed -i 's|curl -fsSL https://raw\.githubusercontent\.com/maximeallanic/nivuus-shell/master/install\.sh|curl -fsSL https://github.com/maximeallanic/nivuus-shell/releases/latest/download/install.sh|g' "$README_FILE"
    
    # Update any version references
    if [[ "$CURRENT_VERSION" != "unknown" ]]; then
        echo "📝 Updated installation commands to use latest release"
    fi
}

# Update version badge if present
update_version_badge() {
    if [[ ! -f "$README_FILE" ]] || [[ "$CURRENT_VERSION" == "unknown" ]]; then
        return
    fi
    
    # Update version badge (if it exists)
    if grep -q "badge.*version" "$README_FILE"; then
        sed -i "s|badge/version-[^-]*-|badge/version-$CURRENT_VERSION-|g" "$README_FILE"
        echo "📝 Updated version badge to $CURRENT_VERSION"
    fi
}

main() {
    echo "🔄 Updating documentation..."
    
    update_readme_installation
    update_version_badge
    
    echo "✅ Documentation updated"
}

main "$@"
