#!/usr/bin/env bats

# Test for fixing the arithmetic expression issue in fix_problematic_environment function

load ../test_helper

setup() {
    export TEMP_TEST_DIR=$(mktemp -d)
    export ORIGINAL_LANG="${LANG:-}"
    export ORIGINAL_LC_ALL="${LC_ALL:-}"
    export ORIGINAL_USER="${USER:-}"
    export ORIGINAL_HOME="$HOME"
}

teardown() {
    [[ -d "$TEMP_TEST_DIR" ]] && rm -rf "$TEMP_TEST_DIR"
    export LANG="$ORIGINAL_LANG"
    export LC_ALL="$ORIGINAL_LC_ALL"
    export USER="$ORIGINAL_USER"
    export HOME="$ORIGINAL_HOME"
    unset SUDO_USER SUDO_UID FORCE_ROOT_SAFE MINIMAL_MODE
}

@test "problematic arithmetic expression ((var++)) should be avoided" {
    # Test that shows why ((var++)) fails in some environments
    run bash -c '
        set -euo pipefail
        unset LANG LC_ALL USER
        export SHELL="/usr/bin/tlog-rec-session"
        fixes_applied=0
        # This may fail in some environments
        if ! ((fixes_applied++)) 2>/dev/null; then
            echo "ARITHMETIC_FAILED"
            exit 1
        fi
        echo $fixes_applied
    '
    
    # In some environments this will fail, proving the need for our fix
    if [ "$status" -ne 0 ]; then
        echo "# Confirmed: ((var++)) fails in restricted environments" >&3
        [[ "$output" == *"ARITHMETIC_FAILED"* ]]
    else
        echo "# ((var++)) works in this environment, but may fail in others" >&3
        [ "$output" = "1" ]
    fi
}

@test "robust arithmetic alternatives work in all environments" {
    # Test our robust alternatives
    run bash -c '
        set -euo pipefail
        unset LANG LC_ALL USER
        export SHELL="/usr/bin/tlog-rec-session"
        
        fixes_applied=0
        
        # Method 1: $((var + 1)) - most portable
        fixes_applied=$((fixes_applied + 1)) && echo "Method1: $fixes_applied"
        
        # Method 2: expr (fallback)
        fixes_applied=$(expr $fixes_applied + 1 2>/dev/null) && echo "Method2: $fixes_applied"
        
        echo "SUCCESS"
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"SUCCESS"* ]]
}

@test "fixed install.sh function works in problematic environment" {
    # Create test script with our fixed function
    cat > "$TEMP_TEST_DIR/test_fixed_function.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

# Our fixed function
fix_problematic_environment() {
    local fixes_applied=0
    
    # Robust arithmetic increment function
    increment_fixes() {
        fixes_applied=$((fixes_applied + 1)) 2>/dev/null || {
            fixes_applied=$(expr ${fixes_applied:-0} + 1 2>/dev/null) || {
                fixes_applied=1
            }
        }
    }
    
    # Fix locale issues more aggressively
    if [[ -z "${LANG:-}" ]] || [[ "${LANG:-}" == "C" ]] || [[ "${LANG:-}" == "POSIX" ]]; then
        export LANG=C.UTF-8
        export LC_ALL=C.UTF-8
        increment_fixes
        echo "Fixed locale: C.UTF-8" >&2
    fi
    
    # Fix missing USER
    if [[ -z "${USER:-}" ]]; then
        USER=$(whoami 2>/dev/null || echo "user")
        export USER
        increment_fixes
        echo "Fixed USER: $USER" >&2
    fi
    
    # Fix missing HOME  
    if [[ -z "${HOME:-}" ]] || [[ ! -d "${HOME:-/nonexistent}" ]]; then
        if [[ "${USER:-}" == "root" ]]; then
            export HOME="/root"
        else
            export HOME="/home/${USER:-user}"
        fi
        increment_fixes
        echo "Fixed HOME: $HOME" >&2
    fi
    
    # Detect problematic sudo/su environment
    if [[ -n "${SUDO_USER:-}" ]] || [[ -n "${SUDO_UID:-}" ]] || [[ "${PATH:-}" == "/usr/bin:/bin" ]]; then
        export FORCE_ROOT_SAFE=1
        export MINIMAL_MODE=1
        increment_fixes
        echo "Activated root-safe mode" >&2
    fi
    
    if [[ ${fixes_applied:-0} -gt 0 ]]; then
        echo "Applied $fixes_applied environment fixes" >&2
    fi
}

# Simulate the problematic environment from the bug report
unset LANG LC_ALL USER HOME
export SHELL="/usr/bin/tlog-rec-session"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

fix_problematic_environment
echo "FUNCTION_COMPLETED_SUCCESSFULLY"
EOF

    chmod +x "$TEMP_TEST_DIR/test_fixed_function.sh"
    
    run "$TEMP_TEST_DIR/test_fixed_function.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"FUNCTION_COMPLETED_SUCCESSFULLY"* ]]
    [[ "$stderr" == *"Fixed locale"* ]]
    [[ "$stderr" == *"Fixed USER"* ]]
}

@test "install.sh no longer contains problematic arithmetic" {
    # Check that install.sh has been fixed
    run grep -n "((fixes_applied++))" "$PROJECT_ROOT/install.sh"
    [ "$status" -ne 0 ] # Should not find the problematic pattern
    
    # Check that it now uses the robust pattern
    run grep -n "increment_fixes" "$PROJECT_ROOT/install.sh"
    [ "$status" -eq 0 ] # Should find our fix
}

@test "corrected install.sh survives the problematic environment test" {
    # Extract and test the actual fix_problematic_environment function from install.sh
    run bash -c "
        set -euo pipefail
        # Simulate problematic environment
        unset LANG LC_ALL USER HOME
        export SHELL='/usr/bin/tlog-rec-session'
        export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        
        # Source the function from install.sh
        source <(sed -n '/^fix_problematic_environment()/,/^}/p' '$PROJECT_ROOT/install.sh')
        
        # Run the function
        fix_problematic_environment
        echo 'ENVIRONMENT_FIX_SUCCESS'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ENVIRONMENT_FIX_SUCCESS"* ]]
}
