#!/bin/bash

# Test script to validate root-safe installation and antigen protection
# =====================================================================

set -e

echo "🧪 Testing root-safe installation and antigen protection..."

# Test 1: Simulate root environment
test_root_environment() {
    echo "📋 Test 1: Root environment simulation"
    
    # Create temporary test environment
    TEMP_DIR=$(mktemp -d)
    
    # Test with root-like environment variables (create subshell to avoid readonly issues)
    (
        export HOME="$TEMP_DIR"
        export USER="root"
        
        # Source root protection file
        if source ./config/00-root-protection.zsh 2>&1 | grep -q "error\|warning"; then
            echo "❌ Root protection has warnings/errors"
            exit 1
        else
            echo "✅ Root protection loads cleanly"
        fi
        
        # Test antigen mock
        if antigen bundle zsh-users/zsh-syntax-highlighting 2>&1 | grep -q "error\|warning"; then
            echo "❌ Antigen mock has warnings/errors"
            exit 1
        else
            echo "✅ Antigen mock works correctly"
        fi
    )
    
    local test_result=$?
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    return $test_result
}

# Test 2: Locale fix validation
test_locale_fix() {
    echo "📋 Test 2: Locale fix validation"
    
    # Backup current locale
    OLD_LANG="$LANG"
    OLD_LC_ALL="$LC_ALL"
    
    # Test with problematic locale
    export LANG=C
    export LC_ALL=C
    
    # Source the install script locale fix
    if grep -A 20 "Critical locale fix" install.sh | bash 2>&1 | grep -q "setlocale\|warning"; then
        echo "❌ Locale fix still produces warnings"
        return 1
    else
        echo "✅ Locale fix works correctly"
    fi
    
    # Restore locale
    export LANG="$OLD_LANG"
    export LC_ALL="$OLD_LC_ALL"
}

# Test 3: PATH diagnostic
test_path_diagnostic() {
    echo "📋 Test 3: PATH diagnostic"
    
    # Backup current PATH
    OLD_PATH="$PATH"
    
    # Test with corrupted PATH
    export PATH="/broken/path:Unknown command:/usr/bin"
    
    # Source path diagnostic
    if source ./config/00-path-diagnostic.zsh 2>&1 | grep -q "PATH corruption detected"; then
        echo "✅ PATH corruption detected and handled"
    else
        echo "❌ PATH corruption not detected"
        return 1
    fi
    
    # Restore PATH
    export PATH="$OLD_PATH"
}

# Test 4: Installation in root mode
test_root_installation() {
    echo "📋 Test 4: Root installation simulation"
    
    # Create temporary root-like environment
    TEMP_DIR=$(mktemp -d)
    export TEMP_HOME="$TEMP_DIR"
    
    # Export root environment variables
    export ANTIGEN_DISABLE=1
    export MINIMAL_MODE=1
    
    # Test that antigen operations are mocked
    source ./config/01-performance.zsh
    
    if command -v antigen >/dev/null && antigen --version 2>&1 | grep -q "error\|warning"; then
        echo "❌ Antigen not properly mocked"
        return 1
    else
        echo "✅ Antigen properly mocked/disabled"
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Run all tests
echo "🔬 Starting comprehensive root-safe tests..."
echo

if test_root_environment && test_locale_fix && test_path_diagnostic && test_root_installation; then
    echo
    echo "🎉 All tests passed! Root-safe installation is working correctly."
    echo
    echo "✅ Root environment detection: OK"
    echo "✅ Locale fix: OK"
    echo "✅ PATH diagnostic: OK" 
    echo "✅ Antigen protection: OK"
    echo
    echo "The shell configuration should now work without errors in root mode."
else
    echo
    echo "❌ Some tests failed. Please review the output above."
    exit 1
fi
