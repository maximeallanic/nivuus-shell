#!/usr/bin/env bats

# Regression test to ensure arithmetic fix remains in place

load ../test_helper

@test "install.sh does not contain dangerous arithmetic expressions" {
    # Ensure the problematic ((var++)) pattern is not present
    run grep -n "((.*++))" "$PROJECT_ROOT/install.sh"
    [ "$status" -ne 0 ] # Should not find any increment expressions
}

@test "install.sh contains safe arithmetic helper function" {
    # Ensure our fix is present
    run grep -n "increment_fixes" "$PROJECT_ROOT/install.sh"
    [ "$status" -eq 0 ] # Should find our helper function
}

@test "fix_problematic_environment function is robust" {
    # Ensure the function uses safe parameter expansion and increment
    run sed -n '/fix_problematic_environment()/,/^}/p' "$PROJECT_ROOT/install.sh"
    [ "$status" -eq 0 ]
    
    # Should contain increment_fixes helper function
    [[ "$output" == *'increment_fixes()'* ]]
    
    # Should use safe arithmetic with error handling
    [[ "$output" == *'2>/dev/null || {'* ]]
    
    # Should not contain dangerous ((...)) increment
    ! [[ "$output" == *'((fixes_applied++))'* ]]
}

@test "arithmetic operations are wrapped in error handling" {
    # Check that arithmetic operations have fallbacks
    run sed -n '/fix_problematic_environment()/,/^}/p' "$PROJECT_ROOT/install.sh"
    [ "$status" -eq 0 ]
    
    # Should contain the robust increment pattern
    [[ "$output" == *'2>/dev/null || {'* ]]
    [[ "$output" == *'expr ${fixes_applied:-0}'* ]]
}

@test "no unprotected arithmetic expressions remain" {
    # Scan for any remaining dangerous patterns
    run grep -n '\(\(.*\)\)' "$PROJECT_ROOT/install.sh"
    
    if [ "$status" -eq 0 ]; then
        # If we find any ((...)) expressions, they should be safe ones
        echo "Found arithmetic expressions:" >&3
        echo "$output" >&3
        
        # Should not contain the dangerous increment pattern
        ! [[ "$output" == *'(('*'++))'* ]]
        ! [[ "$output" == *'(('*'--)'* ]]
    fi
}
