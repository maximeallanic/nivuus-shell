#!/usr/bin/env bats

# Load helpers
load '../helpers/assertions'
load '../helpers/mocks'

# Setup before each test
setup() {
    # Load Nord theme first
    source "$NIVUUS_SHELL_DIR/themes/nord.zsh"

    # Load prompt module
    source "$NIVUUS_SHELL_DIR/config/05-prompt.zsh"
}

# Cleanup after each test
teardown() {
    cleanup_all_mocks
}

# =============================================================================
# SSH Detection Tests
# =============================================================================

@test "is_ssh detects SSH_CLIENT environment" {
    mock_ssh_session
    run is_ssh
    [ "$status" -eq 0 ]
}

@test "is_ssh detects local session" {
    mock_local_session
    run is_ssh
    [ "$status" -eq 1 ]
}

# =============================================================================
# Root Detection Tests
# =============================================================================

@test 'is_root detects root user (EUID=0)' {
    mock_root_user

    run is_root

    assert $state equals 0
}

@test 'is_root detects regular user' {
    mock_regular_user

    run is_root

    assert $state equals 1
}

# =============================================================================
# Git Prompt Tests
# =============================================================================

@test 'git_prompt_info returns nothing when not in git repo' {
    cd /tmp

    result=$(git_prompt_info)

    assert "$result" is_empty
}

@test 'git_prompt_info shows branch name in git repo' {
    create_mock_git_repo
    cd tests/fixtures/git_repo

    result=$(git_prompt_info)

    assert "$result" contains "master"
}

@test 'git_prompt_info uses cache for subsequent calls' {
    create_mock_git_repo
    cd tests/fixtures/git_repo

    # This test verifies caching works
    assert_cached "git_prompt_info"
}

@test 'git_prompt_info shows dirty indicator for modified files' {
    create_mock_git_repo
    cd tests/fixtures/git_repo

    echo "change" >> README.md

    result=$(git_prompt_info)

    # Should contain red circle (dirty indicator)
    assert "$result" contains "○"
}

@test 'git_prompt_info shows clean indicator for clean repo' {
    create_mock_git_repo
    cd tests/fixtures/git_repo

    # Ensure repo is clean
    git add -A
    git commit -m "Clean" 2>/dev/null || true

    result=$(git_prompt_info)

    # Should contain green circle (clean indicator)
    assert "$result" contains "●"
}

# =============================================================================
# Python Venv Detection Tests
# =============================================================================

@test 'prompt_python_venv detects standard venv' {
    mock_python_venv "venv"

    result=$(prompt_python_venv)

    assert "$result" contains "(venv)"
}

@test 'prompt_python_venv detects conda environment' {
    mock_python_venv "conda"

    result=$(prompt_python_venv)

    assert "$result" contains "(conda:my-conda-env)"
}

@test 'prompt_python_venv detects poetry environment' {
    mock_python_venv "poetry"

    result=$(prompt_python_venv)

    assert "$result" contains "(poetry)"
}

@test 'prompt_python_venv returns nothing when no venv active' {
    mock_no_venv

    result=$(prompt_python_venv)

    assert "$result" is_empty
}

@test 'prompt_python_venv uses correct Nord color (180)' {
    mock_python_venv "venv"

    result=$(prompt_python_venv)

    assert_color "$result" 180
}

# =============================================================================
# Cloud Context Tests
# =============================================================================

@test 'prompt_cloud_context detects AWS profile' {
    mock_aws_env

    result=$(prompt_cloud_context)

    assert "$result" contains "aws:production"
}

@test 'prompt_cloud_context detects GCP project' {
    mock_gcp_env

    result=$(prompt_cloud_context)

    assert "$result" contains "gcp:my-gcp-project"
}

@test 'prompt_cloud_context detects Azure subscription' {
    mock_azure_env

    result=$(prompt_cloud_context)

    assert "$result" contains "az:"
}

@test 'prompt_cloud_context returns nothing when no cloud env set' {
    # Ensure no cloud vars set
    unset AWS_PROFILE
    unset CLOUDSDK_CORE_PROJECT
    unset AZURE_SUBSCRIPTION_ID

    result=$(prompt_cloud_context)

    assert "$result" is_empty
}

# =============================================================================
# Firebase Detection Tests
# =============================================================================

@test 'prompt_firebase detects Firebase project from .firebaserc' {
    mock_firebase_config "my-firebase-project"
    cd tests/fixtures

    result=$(prompt_firebase)

    assert "$result" contains "my-firebase-project"
}

@test 'prompt_firebase returns nothing when no .firebaserc exists' {
    cd /tmp

    result=$(prompt_firebase)

    assert "$result" is_empty
}

# =============================================================================
# Background Jobs Tests
# =============================================================================

@test 'background_jobs_info shows running job' {
    # Start a background sleep process
    sleep 10 &
    local job_pid=$!

    result=$(background_jobs_info)

    # Should show running job indicator
    assert "$result" contains "▶"

    # Cleanup
    kill $job_pid 2>/dev/null || true
}

@test 'background_jobs_info returns nothing when no jobs' {
    # Ensure no background jobs
    kill %% 2>/dev/null || true

    result=$(background_jobs_info)

    assert "$result" is_empty
}

# =============================================================================
# Build Prompt Integration Tests
# =============================================================================

@test 'build_prompt assembles all components' {
    # Setup various contexts
    mock_local_session
    mock_regular_user
    mock_python_venv "venv"
    mock_aws_env

    result=$(build_prompt)

    # Should contain status, path, venv, cloud
    assert "$result" is_not_empty
}

@test 'build_prompt uses Nord colors' {
    result=$(build_prompt)

    # Should contain at least one Nord color code
    assert_color "$result" 109  # cyan_light for path
}

@test 'build_prompt is fast (<100ms)' {
    assert_performance 100 "build_prompt"
}

# =============================================================================
# Color Variables Tests
# =============================================================================

@test 'NORD_PATH is set' {
    assert_env_set "NORD_PATH"
}

@test 'NORD_SUCCESS is set' {
    assert_env_set "NORD_SUCCESS"
}

@test 'NORD_ERROR is set' {
    assert_env_set "NORD_ERROR"
}

@test 'NORD_GIT_BRANCH is set' {
    assert_env_set "NORD_GIT_BRANCH"
}

# Print summary and exit
print_test_summary
exit $?
