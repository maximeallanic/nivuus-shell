#!/usr/bin/env zsh
# ============================================================================
# Nivuus Shell - Auto-Update System
# ============================================================================
# Manages automatic updates from the GitHub repository
# - Weekly automatic update checks (configurable)
# - Automatic installation with backup
# - Manual update via 'nivuus-update' command
# ============================================================================

# Configuration variables (can be overridden in .zsh_local)
: ${ENABLE_AUTOUPDATE:=true}
: ${AUTOUPDATE_CHECK_FREQUENCY_DAYS:=7}
: ${NIVUUS_REMOTE_REPO:=git@github.com:maximeallanic/nivuus-shell.git}
: ${NIVUUS_BRANCH:=master}

# Last update check timestamp file
NIVUUS_UPDATE_CHECK_FILE="$HOME/.nivuus-shell-last-update-check"

# ============================================================================
# Helper Functions
# ============================================================================

# Check if we're in a git repository
_nivuus_is_git_repo() {
    [[ -d "$NIVUUS_SHELL_DIR/.git" ]] && return 0
    return 1
}

# Get current commit hash
_nivuus_current_commit() {
    git -C "$NIVUUS_SHELL_DIR" rev-parse HEAD 2>/dev/null
}

# Get remote commit hash
_nivuus_remote_commit() {
    git -C "$NIVUUS_SHELL_DIR" rev-parse origin/$NIVUUS_BRANCH 2>/dev/null
}

# Check if update is available
_nivuus_update_available() {
    local current=$(_nivuus_current_commit)
    local remote=$(_nivuus_remote_commit)

    [[ -n "$current" ]] && [[ -n "$remote" ]] && [[ "$current" != "$remote" ]]
}

# Get days since last check
_nivuus_days_since_check() {
    if [[ ! -f "$NIVUUS_UPDATE_CHECK_FILE" ]]; then
        echo 999
        return
    fi

    local last_check=$(cat "$NIVUUS_UPDATE_CHECK_FILE" 2>/dev/null || echo 0)
    local now=$(date +%s)
    local diff=$((now - last_check))
    echo $((diff / 86400))
}

# Update the last check timestamp
_nivuus_update_check_timestamp() {
    date +%s > "$NIVUUS_UPDATE_CHECK_FILE"
}

# Create backup before update
_nivuus_create_update_backup() {
    local backup_dir="$HOME/.config/nivuus-shell-backup/pre-update-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$backup_dir"

    # Backup entire installation directory
    if [[ -d "$NIVUUS_SHELL_DIR" ]]; then
        cp -r "$NIVUUS_SHELL_DIR" "$backup_dir/nivuus-shell"
    fi

    # Backup user files
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/.zshrc"
    [[ -f "$HOME/.zsh_local" ]] && cp "$HOME/.zsh_local" "$backup_dir/.zsh_local"

    echo "$backup_dir"
}

# Perform the actual update
_nivuus_perform_update() {
    local backup_dir=$(_nivuus_create_update_backup)

    echo "📦 Backup created: $backup_dir"
    echo "🔄 Updating Nivuus Shell..."

    # Fetch and pull from remote
    if git -C "$NIVUUS_SHELL_DIR" fetch origin "$NIVUUS_BRANCH" 2>/dev/null && \
       git -C "$NIVUUS_SHELL_DIR" pull origin "$NIVUUS_BRANCH" 2>/dev/null; then

        echo "✅ Update successful!"

        # Recompile all .zsh files
        for file in "$NIVUUS_SHELL_DIR"/**/*.zsh(N); do
            zcompile "$file" 2>/dev/null
        done

        echo "🔨 Recompiled configuration files"
        echo "♻️  Restart your shell to apply changes: exec zsh"

        return 0
    else
        echo "❌ Update failed! Restoring from backup..."

        # Restore from backup
        if [[ -d "$backup_dir/nivuus-shell" ]]; then
            rm -rf "$NIVUUS_SHELL_DIR"
            cp -r "$backup_dir/nivuus-shell" "$NIVUUS_SHELL_DIR"
            echo "✅ Restored from backup"
        fi

        return 1
    fi
}

# Background update check (async, no performance impact)
_nivuus_check_update_async() {
    (
        # Fetch remote changes silently
        git -C "$NIVUUS_SHELL_DIR" fetch origin "$NIVUUS_BRANCH" &>/dev/null

        # Update timestamp
        _nivuus_update_check_timestamp

        # Check if update is available
        if _nivuus_update_available; then
            # Auto-install the update
            _nivuus_perform_update > /tmp/nivuus-update.log 2>&1
        fi
    ) &!
}

# ============================================================================
# Main Auto-Update Logic
# ============================================================================

# Only run if enabled and in a git repository
if [[ "$ENABLE_AUTOUPDATE" == "true" ]] && _nivuus_is_git_repo; then
    # Check if it's time for an update check
    local days_since_check=$(_nivuus_days_since_check)

    if (( days_since_check >= AUTOUPDATE_CHECK_FREQUENCY_DAYS )); then
        _nivuus_check_update_async
    fi
fi

# ============================================================================
# Manual Update Command
# ============================================================================

nivuus-update() {
    if ! _nivuus_is_git_repo; then
        echo "❌ Nivuus Shell is not installed as a git repository"
        echo "   Auto-update is only available for git-based installations"
        return 1
    fi

    echo "🔍 Checking for updates..."

    # Fetch remote changes
    git -C "$NIVUUS_SHELL_DIR" fetch origin "$NIVUUS_BRANCH" 2>/dev/null

    # Update check timestamp
    _nivuus_update_check_timestamp

    # Check versions
    local current=$(_nivuus_current_commit)
    local remote=$(_nivuus_remote_commit)

    echo "📍 Current version: ${current:0:8}"
    echo "📍 Remote version:  ${remote:0:8}"

    if _nivuus_update_available; then
        echo ""
        echo "🆕 Update available!"
        echo ""
        _nivuus_perform_update
    else
        echo ""
        echo "✅ Already up to date!"
    fi
}
