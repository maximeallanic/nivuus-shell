#!/usr/bin/env bats

# Tests pour les environnements problématiques (locales, root, etc.)
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "Handles locale failures gracefully" {
    # Simulate locale failure environment
    run zsh -c "
        unset LANG
        unset LC_ALL
        export LANG=C
        # Simulate locale command failure
        alias locale='echo locale: command not found >&2; exit 1'
        source $PROJECT_ROOT/config/10-environment.zsh
        echo \"LANG=\$LANG\"
        echo \"LC_ALL=\$LC_ALL\"
        echo 'LOCALE_TEST_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "LOCALE_TEST_OK"
    # Should have UTF-8 locale set (either C.UTF-8 or en_US.UTF-8)
    [[ "$output" =~ UTF-8 ]] || fail "No UTF-8 locale found in output"
}

@test "Root-safe activates with SUDO_USER" {
    run zsh -c "
        export SUDO_USER=testuser
        export SUDO_UID=1000
        export PATH=/usr/bin:/bin
        source $PROJECT_ROOT/config/99-root-safe.zsh
        echo \"MINIMAL_MODE=\$MINIMAL_MODE\"
        echo \"FORCE_ROOT_SAFE=\$FORCE_ROOT_SAFE\"
        echo \"SKIP_GLOBAL_CONFIG=\$SKIP_GLOBAL_CONFIG\"
        echo 'SUDO_ROOT_SAFE_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "MINIMAL_MODE=1"
    assert_contains "$output" "FORCE_ROOT_SAFE=1"
    assert_contains "$output" "SKIP_GLOBAL_CONFIG=1"
    assert_contains "$output" "SUDO_ROOT_SAFE_OK"
}

@test "Root-safe activates with restricted environment" {
    run zsh -c "
        export LANG=C
        unset DISPLAY
        export PATH=/usr/bin:/bin
        # Simulate non-writable HOME
        restricted_home=\"$TEST_HOME/restricted\"
        mkdir -p \"\$restricted_home\"
        chmod 555 \"\$restricted_home\"
        export HOME=\"\$restricted_home\"
        source $PROJECT_ROOT/config/99-root-safe.zsh
        echo \"MINIMAL_MODE=\$MINIMAL_MODE\"
        echo 'RESTRICTED_ROOT_SAFE_OK'
        # Restore permissions for cleanup
        chmod 755 \"\$restricted_home\"
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "MINIMAL_MODE=1"
    assert_contains "$output" "RESTRICTED_ROOT_SAFE_OK"
}

@test "Root-safe with FORCE_ROOT_SAFE=1" {
    run zsh -c "
        export FORCE_ROOT_SAFE=1
        source $PROJECT_ROOT/config/99-root-safe.zsh
        echo \"MINIMAL_MODE=\$MINIMAL_MODE\"
        echo \"SKIP_GLOBAL_CONFIG=\$SKIP_GLOBAL_CONFIG\"
        echo \"DISABLE_AUTO_UPDATE=\$DISABLE_AUTO_UPDATE\"
        echo 'FORCED_ROOT_SAFE_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "MINIMAL_MODE=1"
    assert_contains "$output" "SKIP_GLOBAL_CONFIG=1"
    assert_contains "$output" "DISABLE_AUTO_UPDATE=true"
    assert_contains "$output" "FORCED_ROOT_SAFE_OK"
}

@test "Performance config handles minimal mode" {
    run zsh -c "
        export MINIMAL_MODE=1
        source $PROJECT_ROOT/config/01-performance.zsh
        echo \"ANTIGEN_DISABLE=\$ANTIGEN_DISABLE\"
        echo \"ANTIGEN_DISABLE_CACHE=\$ANTIGEN_DISABLE_CACHE\"
        echo 'PERFORMANCE_MINIMAL_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "ANTIGEN_DISABLE=1"
    assert_contains "$output" "ANTIGEN_DISABLE_CACHE=1"
    assert_contains "$output" "PERFORMANCE_MINIMAL_OK"
}

@test "Locale fix works without locale command" {
    run zsh -c "
        unset LANG
        unset LC_ALL
        # Simulate missing locale command
        export PATH=/bin:/usr/bin
        alias locale='exit 127'  # Command not found
        source $PROJECT_ROOT/config/10-environment.zsh
        echo \"LANG=\$LANG\"
        echo \"LC_ALL=\$LC_ALL\"
        echo 'NO_LOCALE_CMD_OK'
    "
    [ "$status" -eq 0 ]
    # Should have UTF-8 locale set (either C.UTF-8 or en_US.UTF-8)
    [[ "$output" =~ UTF-8 ]] || fail "No UTF-8 locale found in output"
    assert_contains "$output" "NO_LOCALE_CMD_OK"
}

@test "Handles missing whoami command" {
    # Create a fake whoami that fails
    local fake_whoami_dir=$(mktemp -d)
    cat > "$fake_whoami_dir/whoami" << 'EOF'
#!/bin/sh
exit 127
EOF
    chmod +x "$fake_whoami_dir/whoami"

    run zsh -c "
        export PATH='$fake_whoami_dir:/bin:/usr/bin'
        export USER=testuser
        export UID=1000
        export EUID=1000
        source '$PROJECT_ROOT/config/99-root-safe.zsh' || true
        echo 'WHOAMI_MISSING_OK'
    "

    # Cleanup
    rm -rf "$fake_whoami_dir"

    [ "$status" -eq 0 ]
    assert_contains "$output" "WHOAMI_MISSING_OK"
}

@test "Debug mode shows diagnostics" {
    run zsh -c "
        export DEBUG_MODE=true
        export FORCE_ROOT_SAFE=1
        source $PROJECT_ROOT/config/99-root-safe.zsh 2>&1
        echo 'DEBUG_DIAGNOSTICS_OK'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "Root-Safe Diagnostics"
    assert_contains "$output" "DEBUG_DIAGNOSTICS_OK"
}

@test "Handles completely broken environment" {
    run zsh -c "
        # Simulate completely broken environment
        unset LANG
        unset LC_ALL
        unset USER
        unset HOME
        export PATH=/usr/bin:/bin
        alias whoami='exit 1'
        alias locale='exit 1'
        source $PROJECT_ROOT/config/10-environment.zsh
        source $PROJECT_ROOT/config/99-root-safe.zsh
        echo 'BROKEN_ENV_SURVIVED'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "BROKEN_ENV_SURVIVED"
}
