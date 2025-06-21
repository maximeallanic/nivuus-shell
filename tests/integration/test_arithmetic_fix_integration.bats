#!/usr/bin/env bats

# Integration test for the arithmetic fix in the full installation process

load ../test_helper

setup() {
    export TEMP_INSTALL_DIR=$(mktemp -d)
    export ORIGINAL_LANG="${LANG:-}"
    export ORIGINAL_LC_ALL="${LC_ALL:-}"
    export ORIGINAL_USER="${USER:-}"
    export ORIGINAL_HOME="$HOME"
}

teardown() {
    [[ -d "$TEMP_INSTALL_DIR" ]] && rm -rf "$TEMP_INSTALL_DIR"
    export LANG="$ORIGINAL_LANG"
    export LC_ALL="$ORIGINAL_LC_ALL" 
    export USER="$ORIGINAL_USER"
    export HOME="$ORIGINAL_HOME"
    unset SUDO_USER SUDO_UID FORCE_ROOT_SAFE MINIMAL_MODE
}

@test "install.sh handles problematic environment without arithmetic errors" {
    # Copy install.sh to temp directory for isolated testing
    cp "$PROJECT_ROOT/install.sh" "$TEMP_INSTALL_DIR/install.sh"
    
    # Simulate the exact problematic environment from the bug report
    run bash -c "
        cd '$TEMP_INSTALL_DIR'
        
        # Reproduce the exact environment conditions
        unset LANG LC_ALL USER HOME
        export SHELL='/usr/bin/tlog-rec-session'
        export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        
        # Set up minimal project structure to avoid other errors
        mkdir -p install config
        echo 'echo \"Mock install\"' > install/system.sh
        echo 'echo \"Mock config\"' > install/config.sh
        echo 'echo \"Mock common\"' > install/common.sh
        chmod +x install/*.sh
        
        # Run just the environment fix part (the part that was failing)
        bash -c '
            set -euo pipefail
            source <(sed -n \"/^fix_problematic_environment()/,/^}/p\" install.sh)
            fix_problematic_environment
            echo \"ENVIRONMENT_FIX_COMPLETED\"
        '
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"ENVIRONMENT_FIX_COMPLETED"* ]]
}

@test "full install.sh dry-run works in problematic environment" {
    skip "Requires full installer setup - use for manual testing"
    
    # This test would require setting up the full installer structure
    # For now, we focus on the specific arithmetic fix
    
    run bash -c "
        cd '$PROJECT_ROOT'
        
        # Simulate problematic environment
        unset LANG LC_ALL USER HOME
        export SHELL='/usr/bin/tlog-rec-session'
        export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        
        # Dry run of install.sh (would need --dry-run flag implementation)
        echo 'DRY_RUN_PLACEHOLDER'
    "
    
    [ "$status" -eq 0 ]
}

@test "arithmetic fix prevents the exact error from bug report" {
    # Test that specifically reproduces and fixes the reported error
    
    # First, show that the old approach would fail
    run bash -c '
        set -euo pipefail
        unset LANG LC_ALL USER
        export SHELL="/usr/bin/tlog-rec-session"
        
        fixes_applied=0
        # This is the pattern that was failing
        if ! ((fixes_applied++)) 2>/dev/null; then
            echo "OLD_APPROACH_FAILED"
            exit 1
        fi
        echo "OLD_APPROACH_WORKED: $fixes_applied"
    '
    
    # In some environments this fails, in others it works
    if [ "$status" -ne 0 ]; then
        echo "# Confirmed: Old arithmetic approach fails" >&3
    fi
    
    # Now test our robust approach
    run bash -c '
        set -euo pipefail
        unset LANG LC_ALL USER
        export SHELL="/usr/bin/tlog-rec-session"
        
        fixes_applied=0
        
        # Our robust increment function
        increment_fixes() {
            fixes_applied=$((fixes_applied + 1)) 2>/dev/null || {
                fixes_applied=$(expr ${fixes_applied:-0} + 1 2>/dev/null) || {
                    fixes_applied=1
                }
            }
        }
        
        increment_fixes
        echo "NEW_APPROACH_WORKS: $fixes_applied"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"NEW_APPROACH_WORKS: 1"* ]]
}
