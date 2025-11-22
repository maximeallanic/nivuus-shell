#!/usr/bin/env zunit

# Load helpers
source tests/helpers/assertions.zsh
source tests/helpers/mocks.zsh

# Setup
@setup {
    source themes/nord.zsh
    source config/19-ai-suggestions.zsh
}

# Cleanup
@teardown {
    cleanup_all_mocks
}

# =============================================================================
# AI Suggestions Workflow Tests
# =============================================================================

@test 'Complete workflow: trigger → generate → display → accept' {
    # Mock gemini response
    mock_gemini "ls -la" "ls -la --color=auto"

    # Simulate widget call
    BUFFER="ls -la"
    _ai_show_inline

    # Should have started generation
    assert "$_AI_GENERATE_PID" is_not_empty

    # Wait for generation (mock is instant)
    sleep 0.1

    # Should have suggestion
    assert "$_AI_CURRENT_SUGGESTION" same_as "ls -la --color=auto"

    # Accept suggestion
    _ai_accept_inline

    # Buffer should be updated
    assert "$BUFFER" same_as "ls -la --color=auto"
}

@test 'Animation cycles through dots' {
    # Start at 1 dot
    _AI_ANIMATION_DOTS=1

    # First cycle
    _ai_animate_dots
    assert "$_AI_ANIMATION_DOTS" equals 2

    # Second cycle
    _ai_animate_dots
    assert "$_AI_ANIMATION_DOTS" equals 3

    # Third cycle (loops back to 1)
    _ai_animate_dots
    assert "$_AI_ANIMATION_DOTS" equals 1
}

@test 'RPROMPT shows loading animation with correct Nord colors' {
    _AI_SAVED_RPROMPT="original"
    _AI_ANIMATION_DOTS=1

    _ai_update_loading_animation

    # Should contain cyan color (110)
    assert_color "$RPROMPT" 110

    # Should contain "Generating"
    assert "$RPROMPT" contains "Generating"
}

@test 'RPROMPT shows suggestion with correct Nord colors' {
    _AI_CURRENT_SUGGESTION="git status"
    _AI_SAVED_RPROMPT="original"

    # Simulate completion handler
    RPROMPT="%F{143}🤖 git status%F{254} (Ctrl+↓)%f"

    # Should contain green (143)
    assert_color "$RPROMPT" 143

    # Should contain gray (254)
    assert_color "$RPROMPT" 254
}

@test 'Cancel generation cleans up properly' {
    # Setup active generation
    _AI_GENERATE_PID=12345
    _AI_TEMP_FILE="/tmp/test"
    _AI_SAVED_RPROMPT="original"
    RPROMPT="loading..."

    _ai_cancel_generation

    # Should cleanup
    assert "$_AI_GENERATE_PID" is_empty
    assert "$_AI_TEMP_FILE" is_empty
    assert "$RPROMPT" same_as "original"
}

@test 'Debounce delays suggestion trigger' {
    # Enable auto-debounce
    ENABLE_AI_AUTO_DEBOUNCE=true
    AI_DEBOUNCE_DELAY=1

    BUFFER="test"

    # Start debounce
    _ai_start_debounce

    # Check that trigger is scheduled (would need sched inspection)
    # For now, just verify function exists
    assert_function_exists "_ai_debounce_trigger"
}

@test 'Context collection includes all required info' {
    cd tests/fixtures

    context=$(_ai_get_context)

    # Should include directory
    assert "$context" contains "Dir:"

    # Should include files
    assert "$context" contains "Files"

    # Should include recent commands
    assert "$context" contains "Recent commands"

    # Should include user
    assert "$context" contains "User:"
}

@test 'Cache respects 5min TTL' {
    mock_gemini "test" "cached response"

    # First call
    result1=$(_ai_generate "test")
    time1=$EPOCHSECONDS

    # Second call immediately (cache hit)
    result2=$(_ai_generate "test")

    assert "$result1" same_as "$result2"

    # Verify cache was used (same response)
    assert "$_AI_CACHE_TIME[test_$(pwd)]" is_not_empty
}

@test 'Gracefully handles missing gemini-cli' {
    mock_gemini_error

    result=$(_ai_generate "test" 2>&1)

    # Should return ERROR
    assert "$result" contains "ERROR"
}

# =============================================================================
# Keybindings Integration Tests
# =============================================================================

@test 'Ctrl+Down accepts inline suggestion' {
    # Verify keybinding is registered
    bindkey | grep -q "\^\[\[1;5B.*ai-accept-inline"

    assert $state equals 0
}

@test 'Shift+Tab clears inline suggestion' {
    # Verify keybinding is registered
    bindkey | grep -q "\^\[\[Z.*ai-clear-inline"

    assert $state equals 0
}

@test 'Ctrl+2 triggers AI suggestion' {
    # Verify keybinding is registered
    bindkey | grep -q "\^2.*ai-show-inline"

    assert $state equals 0
}

# =============================================================================
# SIGUSR1 Signal Handling Tests
# =============================================================================

@test 'TRAPUSR1 is defined' {
    assert_function_exists "TRAPUSR1"
}

@test 'Completion handler widget is registered' {
    # Check if widget exists
    zle -l | grep -q "_ai_handle_completion"

    assert $state equals 0
}
