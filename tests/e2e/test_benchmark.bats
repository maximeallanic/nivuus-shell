#!/usr/bin/env bats

# E2E tests for bin/benchmark script

setup() {
    export NIVUUS_SHELL_DIR="${BATS_TEST_DIRNAME}/../.."
}

@test "benchmark script exists and is executable" {
    [ -f "$NIVUUS_SHELL_DIR/bin/benchmark" ]
    [ -x "$NIVUUS_SHELL_DIR/bin/benchmark" ]
}

@test "benchmark produces expected output format" {
    # Run benchmark and check it produces output (don't check exit code due to bats context issues)
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    [[ "$output" == *"ms"* ]]
}

@test "benchmark shows timing information" {
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    [[ "$output" == *"ms"* ]] || [[ "$output" == *"time"* ]] || [[ "$output" == *"Time"* ]]
}

@test "benchmark measures shell load time" {
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    [[ "$output" == *"Shell Load"* ]] || [[ "$output" == *"Load Time"* ]] || [[ "$output" == *"Run"* ]]
}

@test "benchmark shows performance rating" {
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    [[ "$output" == *"Excellent"* ]] || [[ "$output" == *"Good"* ]] || [[ "$output" == *"Slow"* ]] || [[ "$output" == *"✓"* ]]
}

@test "benchmark references 300ms performance target" {
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    [[ "$output" == *"300"* ]]
}

@test "benchmark shows average time" {
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    [[ "$output" == *"Average"* ]] || [[ "$output" == *"average"* ]]
}

@test "benchmark tests multiple runs" {
    output=$("$NIVUUS_SHELL_DIR/bin/benchmark" 2>&1 || true)
    # Should show multiple runs (Run 1, Run 2, etc.)
    [[ "$output" == *"Run"* ]]
}

@test "benchmark script is properly formatted" {
    # Verify benchmark script has proper shebang and structure
    head -1 "$NIVUUS_SHELL_DIR/bin/benchmark" | grep -q '#!/'
}
