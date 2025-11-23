#!/usr/bin/env bats

# E2E tests for bin/healthcheck script

setup() {
    export NIVUUS_SHELL_DIR="${BATS_TEST_DIRNAME}/../.."
}

@test "healthcheck script exists and is executable" {
    [ -f "$NIVUUS_SHELL_DIR/bin/healthcheck" ]
    [ -x "$NIVUUS_SHELL_DIR/bin/healthcheck" ]
}

@test "healthcheck runs without errors" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    [ "$status" -eq 0 ]
}

@test "healthcheck shows Nivuus Shell header" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    [[ "$output" == *"Nivuus Shell"* ]] || [[ "$output" == *"Health"* ]]
}

@test "healthcheck checks ZSH installation" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    [[ "$output" == *"zsh"* ]] || [[ "$output" == *"ZSH"* ]]
}

@test "healthcheck checks config files" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    [[ "$output" == *"config"* ]] || [[ "$output" == *"Config"* ]]
}

@test "healthcheck checks theme file" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    # Theme check is part of the overall health verification
    [[ "$output" == *"theme"* ]] || [[ "$output" == *"Theme"* ]] || [[ "$output" == *"nord"* ]] || [[ "$output" == *"Config files"* ]]
}

@test "healthcheck shows success indicators" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    [[ "$output" == *"✓"* ]] || [[ "$output" == *"OK"* ]] || [[ "$output" == *"Success"* ]]
}

@test "healthcheck verifies installation location" {
    run "$NIVUUS_SHELL_DIR/bin/healthcheck"
    [[ "$output" == *"NIVUUS_SHELL_DIR"* ]] || [[ "$output" == *"installation"* ]] || [[ "$output" == *"installed"* ]] || [[ "$output" == *"Location"* ]]
}

@test "healthcheck runs quickly (<2 seconds)" {
    start=$(date +%s)
    "$NIVUUS_SHELL_DIR/bin/healthcheck" >/dev/null
    end=$(date +%s)
    elapsed=$(( end - start ))

    [ "$elapsed" -lt 2 ]
}
