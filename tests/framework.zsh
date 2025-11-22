#!/usr/bin/env zsh
# Pure ZSH test framework - no external dependencies
# TAP-compliant output for CI/CD compatibility

# Test state
typeset -g _TEST_COUNT=0
typeset -g _TEST_PASSED=0
typeset -g _TEST_FAILED=0
typeset -g _CURRENT_TEST=""
typeset -g _SETUP_FUNCTION=""
typeset -g _TEARDOWN_FUNCTION=""

# Colors for output
typeset -g _COLOR_GREEN="\033[0;32m"
typeset -g _COLOR_RED="\033[0;31m"
typeset -g _COLOR_YELLOW="\033[0;33m"
typeset -g _COLOR_RESET="\033[0m"

# Define test (supports both function name and inline code block)
@test() {
    _CURRENT_TEST="$1"
    shift

    # Run setup if defined
    if [[ -n "$_SETUP_FUNCTION" ]] && typeset -f "$_SETUP_FUNCTION" >/dev/null; then
        $_SETUP_FUNCTION
    fi

    # Run test
    (( _TEST_COUNT++ ))

    # Check if we have a function name or inline code
    local test_passed=false
    if [[ $# -gt 0 ]]; then
        # We have a function name
        if "$@"; then
            test_passed=true
        fi
    fi

    if $test_passed; then
        (( _TEST_PASSED++ ))
        echo "${_COLOR_GREEN}ok${_COLOR_RESET} $_TEST_COUNT - $_CURRENT_TEST"
    else
        (( _TEST_FAILED++ ))
        echo "${_COLOR_RED}not ok${_COLOR_RESET} $_TEST_COUNT - $_CURRENT_TEST"
    fi

    # Run teardown if defined
    if [[ -n "$_TEARDOWN_FUNCTION" ]] && typeset -f "$_TEARDOWN_FUNCTION" >/dev/null; then
        $_TEARDOWN_FUNCTION
    fi
}

# Define setup function
@setup() {
    _SETUP_FUNCTION="$1"
    "$@"
}

# Define teardown function
@teardown() {
    _TEARDOWN_FUNCTION="$1"
    "$@"
}

# Assertions
assert() {
    local value="$1"
    local op="$2"
    local expected="$3"

    case "$op" in
        equals|same_as)
            [[ "$value" == "$expected" ]]
            ;;
        is_empty)
            [[ -z "$value" ]]
            ;;
        is_not_empty)
            [[ -n "$value" ]]
            ;;
        contains)
            [[ "$value" == *"$expected"* ]]
            ;;
        matches)
            [[ "$value" =~ "$expected" ]]
            ;;
        *)
            # Direct boolean test
            [[ "$value" "$op" "$expected" ]]
            ;;
    esac
}

# Run command and capture state
run() {
    "$@"
    state=$?
    return $state
}

# Assert function exists
assert_function_exists() {
    typeset -f "$1" >/dev/null 2>&1
}

# Assert environment variable is set
assert_env_set() {
    [[ -n "${(P)1}" ]]
}

# Assert alias exists
assert_alias_exists() {
    alias "$1" >/dev/null 2>&1
}

# Assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    grep -q "$text" "$file" 2>/dev/null
}

# Assert matches regex
assert_matches() {
    local value="$1"
    local pattern="$2"
    [[ "$value" =~ $pattern ]]
}

# Print test summary
print_test_summary() {
    echo "1..$_TEST_COUNT"
    echo ""
    echo "${_COLOR_YELLOW}═══════════════════════════════════════${_COLOR_RESET}"
    echo "${_COLOR_YELLOW}Test Summary${_COLOR_RESET}"
    echo "${_COLOR_YELLOW}═══════════════════════════════════════${_COLOR_RESET}"
    echo "Total:  $_TEST_COUNT"
    echo "${_COLOR_GREEN}Passed: $_TEST_PASSED${_COLOR_RESET}"
    if (( _TEST_FAILED > 0 )); then
        echo "${_COLOR_RED}Failed: $_TEST_FAILED${_COLOR_RESET}"
        return 1
    fi
    echo "${_COLOR_YELLOW}═══════════════════════════════════════${_COLOR_RESET}"
    return 0
}

# Cleanup function
cleanup_all_mocks() {
    unset -f gemini git ssh 2>/dev/null
    unset SSH_CLIENT SSH_TTY SESSION_TYPE 2>/dev/null
    unset AWS_PROFILE CLOUDSDK_CORE_PROJECT AZURE_SUBSCRIPTION_ID 2>/dev/null
    unset VIRTUAL_ENV CONDA_DEFAULT_ENV POETRY_ACTIVE 2>/dev/null
}
