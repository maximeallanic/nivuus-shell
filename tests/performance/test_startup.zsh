#!/usr/bin/env zunit

# Load helpers
source tests/helpers/assertions.zsh

# =============================================================================
# Startup Time Tests (CRITICAL)
# =============================================================================

@test 'CRITICAL: Full shell startup time is under 300ms' {
    assert_startup_time
}

@test 'Shell loads all modules successfully' {
    result=$(NIVUUS_SHELL_DIR="$(pwd)" zsh -i -c 'echo $NIVUUS_AI_SUGGESTIONS_LOADED' 2>/dev/null)

    assert "$result" equals "1"
}

@test 'Prompt generation is fast (<100ms)' {
    # Load all required modules
    source themes/nord.zsh
    source config/05-prompt.zsh

    assert_performance 100 "build_prompt"
}

@test 'Git prompt with cache is fast (<50ms on cache hit)' {
    # Load modules
    source themes/nord.zsh
    source config/05-prompt.zsh

    # Create test repo
    create_mock_git_repo
    cd tests/fixtures/git_repo

    # First call (cache miss)
    git_prompt_info >/dev/null

    # Second call (cache hit) should be under 50ms
    assert_performance 50 "git_prompt_info"
}

# =============================================================================
# Module Load Time Tests
# =============================================================================

@test 'Nord theme loads quickly (<10ms)' {
    assert_performance 10 "source themes/nord.zsh"
}

@test 'Prompt module loads quickly (<50ms)' {
    source themes/nord.zsh

    assert_performance 50 "source config/05-prompt.zsh"
}

@test 'AI suggestions module loads quickly (<100ms)' {
    source themes/nord.zsh

    assert_performance 100 "source config/19-ai-suggestions.zsh"
}

# =============================================================================
# Compilation Tests
# =============================================================================

@test 'All config files are compiled to .zwc' {
    # Compile first
    for file in config/*.zsh; do
        zcompile "$file" 2>/dev/null
    done

    # Verify
    for file in config/*.zsh; do
        assert_file_compiled "$file"
    done
}

@test 'Loading compiled .zwc is faster than uncompiled' {
    local test_file="config/05-prompt.zsh"

    # Compile
    zcompile "$test_file" 2>/dev/null

    # Measure uncompiled
    mv "${test_file}.zwc" "${test_file}.zwc.bak"
    local start1=$(date +%s%N)
    source "$test_file"
    local end1=$(date +%s%N)
    local time_uncompiled=$(( (end1 - start1) / 1000000 ))

    # Restore compiled version
    mv "${test_file}.zwc.bak" "${test_file}.zwc"

    # Measure compiled
    local start2=$(date +%s%N)
    source "$test_file"
    local end2=$(date +%s%N)
    local time_compiled=$(( (end2 - start2) / 1000000 ))

    # Compiled should be faster
    assert $(( time_compiled < time_uncompiled )) equals 1
}

# =============================================================================
# Memory Usage Tests
# =============================================================================

@test 'Shell memory footprint is reasonable (<100MB)' {
    # Get memory usage in KB
    local mem_kb=$(ps -o rss= -p $$ | tr -d ' ')
    local mem_mb=$((mem_kb / 1024))

    assert $(( mem_mb < 100 )) equals 1
}
