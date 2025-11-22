#!/usr/bin/env zsh
# =============================================================================
# Command Safety Checks
# =============================================================================
# Warns before executing dangerous commands
# Helps prevent accidental data loss or system damage
# =============================================================================

# Skip if explicitly disabled
[[ "${ENABLE_SAFETY_CHECKS:-true}" != "true" ]] && return

# =============================================================================
# Dangerous Command Patterns
# =============================================================================

# Critical patterns that should always warn
typeset -gA DANGEROUS_PATTERNS=(
    # Recursive deletion
    "rm -rf /"              "Deleting root directory - EXTREMELY DANGEROUS!"
    "rm -rf /\*"            "Deleting root directory - EXTREMELY DANGEROUS!"
    "rm -rf ~"              "Deleting home directory - EXTREMELY DANGEROUS!"
    "rm -rf ~/"             "Deleting home directory - EXTREMELY DANGEROUS!"
    "rm -rf \$HOME"         "Deleting home directory - EXTREMELY DANGEROUS!"
    "rm -rf /*"             "Deleting root directory - EXTREMELY DANGEROUS!"
    "rm -rf \."             "Deleting current directory recursively - DANGEROUS!"

    # Dangerous permissions
    "chmod -R 777"          "Making everything world-writable - SECURITY RISK!"
    "chmod 777 /"           "Changing root permissions - EXTREMELY DANGEROUS!"
    "chown -R"              "Recursive ownership change - verify paths!"

    # Disk operations
    "dd if=.*of=/dev/sd"    "Writing to raw disk device - DATA LOSS RISK!"
    "mkfs"                  "Creating filesystem - WILL DESTROY DATA!"
    "fdisk"                 "Disk partitioning - DATA LOSS RISK!"

    # System modifications
    "rm -rf /boot"          "Deleting boot files - SYSTEM WON'T START!"
    "rm -rf /etc"           "Deleting system config - SYSTEM FAILURE!"
    "rm -rf /usr"           "Deleting user binaries - SYSTEM FAILURE!"
    "rm -rf /var"           "Deleting variable data - SYSTEM FAILURE!"

    # Package management
    "apt-get remove.*sudo"  "Removing sudo - YOU'LL LOSE ADMIN ACCESS!"
    "yum remove.*sudo"      "Removing sudo - YOU'LL LOSE ADMIN ACCESS!"

    # Network
    "iptables -F"           "Flushing firewall rules - SECURITY RISK!"
    "iptables -X"           "Deleting firewall chains - SECURITY RISK!"
)

# Warnings for potentially dangerous but common operations
typeset -gA WARNING_PATTERNS=(
    # Force flags
    "rm -rf"                "Recursive force deletion"
    "rm -fr"                "Recursive force deletion"
    "git push.*--force"     "Force push - can overwrite remote history"
    "git push.*-f"          "Force push - can overwrite remote history"

    # Sensitive operations
    "sudo rm"               "Removing files as root"
    "chmod 777"             "Making file world-writable"
    "chmod.*\+x /usr"       "Modifying system directory permissions"

    # Mass operations
    "find.*-delete"         "Mass file deletion"
    "xargs.*rm"             "Mass file deletion via xargs"
)

# =============================================================================
# Safety Check Function
# =============================================================================

_nivuus_safety_check() {
    local cmd="$1"

    # Skip empty commands
    [[ -z "$cmd" ]] && return 0

    # Check for critical dangerous patterns
    for pattern danger_msg in ${(kv)DANGEROUS_PATTERNS}; do
        # Expand the pattern to handle variables
        local expanded_pattern=$(echo "$pattern" | sed 's/\\././g')

        if [[ "$cmd" =~ "$expanded_pattern" ]]; then
            # Critical warning - requires explicit confirmation
            echo ""
            echo "⚠️  ${NORD_ERROR}DANGER:${NORD_RESET} $danger_msg"
            echo "Command: ${NORD_PATH}$cmd${NORD_RESET}"
            echo ""
            echo -n "Type 'yes' to continue or anything else to cancel: "
            read -r response

            if [[ "$response" != "yes" ]]; then
                echo "${NORD_SUCCESS}✓ Command cancelled${NORD_RESET}"
                return 1
            fi

            echo "${NORD_ERROR}⚠ Proceeding with dangerous command...${NORD_RESET}"
            return 0
        fi
    done

    # Check for warning patterns
    for pattern warning_msg in ${(kv)WARNING_PATTERNS}; do
        if [[ "$cmd" =~ "$pattern" ]]; then
            # Warning - show but allow to proceed
            echo ""
            echo "⚠️  ${NORD_FIREBASE}WARNING:${NORD_RESET} $warning_msg"
            echo "Command: ${NORD_PATH}$cmd${NORD_RESET}"
            echo -n "Press Enter to continue or Ctrl+C to cancel... "
            read -r

            return 0
        fi
    done

    return 0
}

# =============================================================================
# Hook into Command Execution
# =============================================================================

# ZSH preexec hook - runs before command execution
_nivuus_preexec_safety() {
    local cmd="$1"

    # Run safety check
    _nivuus_safety_check "$cmd"
    local result=$?

    # If check failed, prevent command execution
    if [[ $result -ne 0 ]]; then
        # Kill the command by sending a fake interrupt
        kill -INT $$
    fi
}

# Register the hook
autoload -U add-zsh-hook
add-zsh-hook preexec _nivuus_preexec_safety

# =============================================================================
# Safe Alternatives
# =============================================================================

# Safe rm with confirmation for important files
safe-rm() {
    local files=("$@")
    local important_files=()

    # Check for important files
    for file in "${files[@]}"; do
        # Skip flags
        [[ "$file" =~ ^- ]] && continue

        # Check if file is important (hidden files, config files, etc.)
        if [[ "$file" =~ ^\. ]] || \
           [[ "$file" =~ (config|rc|profile|bashrc|zshrc)$ ]] || \
           [[ -d "$file" ]]; then
            important_files+=("$file")
        fi
    done

    # Warn about important files
    if [[ ${#important_files[@]} -gt 0 ]]; then
        echo "⚠️  About to delete important files:"
        for file in "${important_files[@]}"; do
            echo "  - $file"
        done
        echo -n "Continue? (y/N): "
        read -r response

        if [[ "$response" != "y" ]] && [[ "$response" != "Y" ]]; then
            echo "Cancelled"
            return 1
        fi
    fi

    # Execute rm
    command rm "$@"
}

# Safe chmod - warns about 777
safe-chmod() {
    local mode="$1"
    shift
    local files=("$@")

    # Warn about 777
    if [[ "$mode" == "777" ]] || [[ "$mode" == "a+rwx" ]]; then
        echo "⚠️  WARNING: Setting permissions to 777 (world-writable)"
        echo "This is a security risk. Consider using 755 or 775 instead."
        echo -n "Continue with 777? (y/N): "
        read -r response

        if [[ "$response" != "y" ]] && [[ "$response" != "Y" ]]; then
            echo "Cancelled. Suggested alternatives:"
            echo "  chmod 755 (rwxr-xr-x) - owner full, others read/execute"
            echo "  chmod 775 (rwxrwxr-x) - owner+group full, others read/execute"
            echo "  chmod 700 (rwx------) - owner only"
            return 1
        fi
    fi

    # Execute chmod
    command chmod "$mode" "${files[@]}"
}

# =============================================================================
# Configuration Help
# =============================================================================

safety-help() {
    cat <<EOF
Command Safety Checks - Protection Against Dangerous Commands

This module warns you before executing potentially dangerous commands.

Configuration:
  export ENABLE_SAFETY_CHECKS=false    # Disable all safety checks

Critical Checks (require 'yes' confirmation):
  • rm -rf / or ~                      # Deleting critical directories
  • chmod 777 /                        # Dangerous permissions on root
  • dd to /dev/sd*                     # Raw disk writes
  • mkfs, fdisk                        # Filesystem operations
  • Removing /boot, /etc, /usr, /var   # System directories
  • Removing sudo package              # Loss of admin access

Warning Checks (press Enter to continue):
  • rm -rf                             # Recursive force deletion
  • git push --force                   # Force push
  • sudo rm                            # Root deletion
  • chmod 777                          # World-writable permissions
  • find ... -delete                   # Mass deletion

Safe Alternatives:
  safe-rm <files>      # Warns before deleting important files
  safe-chmod <mode>    # Warns about dangerous permissions

Examples:
  # This will require confirmation:
  rm -rf /

  # This will show a warning:
  rm -rf node_modules

  # Safe alternative:
  safe-rm .env .npmrc

Bypass (for scripts):
  # Add comment to bypass checks in automated scripts
  # NIVUUS_SAFETY_BYPASS
  rm -rf /tmp/safe-to-delete

EOF
}

# =============================================================================
# Aliases
# =============================================================================

# Optionally override rm and chmod with safe versions
if [[ "${ENABLE_SAFE_ALIASES:-false}" == "true" ]]; then
    alias rm='safe-rm'
    alias chmod='safe-chmod'
fi
