#!/usr/bin/env bats

# Simple smoke tests
load ../test_helper

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
}

teardown() {
    teardown_test_env
}

@test "All config modules can be loaded without errors" {
    for config_file in config/*.zsh; do
        [ -f "$config_file" ] || continue
        
        local module_name=$(basename "$config_file")
        run zsh -c "source '$config_file' && echo 'OK: $module_name'"
        
        if [ "$status" -ne 0 ]; then
            echo "Failed to load: $module_name"
            echo "Output: $output"
            return 1
        fi
    done
}

@test "Main functionality works" {
    run zsh -c "
        source $PROJECT_ROOT/config/01-performance.zsh
        source $PROJECT_ROOT/config/06-aliases.zsh
        echo 'Modules loaded successfully'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "successfully"
}

@test "Shell options are set correctly" {
    run zsh -c "
        source $PROJECT_ROOT/config/01-performance.zsh
        setopt | grep null_glob && echo 'NULL_GLOB_SET'
        setopt | grep -v global_rcs && echo 'GLOBAL_RCS_UNSET'
    "
    [ "$status" -eq 0 ]
}

@test "Environment is clean after loading" {
    run zsh -c "
        source $PROJECT_ROOT/config/01-performance.zsh
        echo \$PATH | grep -q '/usr/local/bin' && echo 'PATH_OK'
        [ -n '\$LANG' ] && echo 'LANG_SET'
    "
    [ "$status" -eq 0 ]
    assert_contains "$output" "PATH_OK"
}
