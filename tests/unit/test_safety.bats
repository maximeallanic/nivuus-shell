#!/usr/bin/env bats

# Unit tests for safety module (config/21-safety.zsh)

setup() {
    # Load dependencies
    source "$NIVUUS_SHELL_DIR/themes/nord.zsh"
}

# =============================================================================
# Module Loading Tests
# =============================================================================

@test "Safety module loads without errors" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && echo 'loaded'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"loaded"* ]]
}

@test "Safety module can be disabled via ENABLE_SAFETY_CHECKS" {
    run zsh -c "export ENABLE_SAFETY_CHECKS=false && source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -f _nivuus_safety_check"
    [ "$status" -ne 0 ]
}

# =============================================================================
# Dangerous Patterns Tests
# =============================================================================

@test "DANGEROUS_PATTERNS associative array is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -p DANGEROUS_PATTERNS"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes 'rm -rf /' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep \"rm -rf /\" config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes 'rm -rf ~' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'rm -rf ~' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes 'chmod -R 777' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'chmod -R 777' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes 'dd if=.*of=/dev/sd' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'dd if=.*of=/dev/sd' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes 'mkfs' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'mkfs' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes system directory deletions" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep -E '(rm -rf /boot|rm -rf /etc|rm -rf /usr|rm -rf /var)' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes sudo removal warnings" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'remove.*sudo' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "DANGEROUS_PATTERNS includes iptables flush" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'iptables -F' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Warning Patterns Tests
# =============================================================================

@test "WARNING_PATTERNS associative array is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -p WARNING_PATTERNS"
    [ "$status" -eq 0 ]
}

@test "WARNING_PATTERNS includes 'rm -rf' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep -A 5 'WARNING_PATTERNS' config/21-safety.zsh | grep 'rm -rf'"
    [ "$status" -eq 0 ]
}

@test "WARNING_PATTERNS includes git force push patterns" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'git push.*--force' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "WARNING_PATTERNS includes 'sudo rm' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'sudo rm' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "WARNING_PATTERNS includes 'chmod 777' pattern" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep -A 10 'WARNING_PATTERNS' config/21-safety.zsh | grep 'chmod 777'"
    [ "$status" -eq 0 ]
}

@test "WARNING_PATTERNS includes mass deletion patterns" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep -E '(find.*-delete|xargs.*rm)' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Safety Check Function Tests
# =============================================================================

@test "_nivuus_safety_check function is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -f _nivuus_safety_check"
    [ "$status" -eq 0 ]
}

@test "_nivuus_safety_check returns 0 for safe commands" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && _nivuus_safety_check 'ls -la'"
    [ "$status" -eq 0 ]
}

@test "_nivuus_safety_check returns 0 for empty commands" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && _nivuus_safety_check ''"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Preexec Hook Tests
# =============================================================================

@test "_nivuus_preexec_safety hook function is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -f _nivuus_preexec_safety"
    [ "$status" -eq 0 ]
}

@test "preexec hook is registered" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'add-zsh-hook preexec' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Safe Alternatives Tests
# =============================================================================

@test "safe-rm function is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -f safe-rm"
    [ "$status" -eq 0 ]
}

@test "safe-chmod function is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -f safe-chmod"
    [ "$status" -eq 0 ]
}

@test "safety-help function is defined" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && typeset -f safety-help"
    [ "$status" -eq 0 ]
}

@test "safety-help provides documentation" {
    run zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && safety-help"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Command Safety Checks"* ]]
    [[ "$output" == *"ENABLE_SAFETY_CHECKS"* ]]
}

# =============================================================================
# Safe Aliases Tests
# =============================================================================

@test "Safe aliases are NOT enabled by default" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'ENABLE_SAFE_ALIASES:-false' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "Safe aliases can be enabled via ENABLE_SAFE_ALIASES" {
    run zsh -c "export ENABLE_SAFE_ALIASES=true && source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && alias rm"
    [ "$status" -eq 0 ]
    [[ "$output" == *"safe-rm"* ]]
}

# =============================================================================
# Pattern Coverage Tests
# =============================================================================

@test "Safety module covers at least 10 dangerous patterns" {
    count=$(zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && echo \${#DANGEROUS_PATTERNS[@]}")
    [ "$count" -ge 10 ]
}

@test "Safety module covers at least 5 warning patterns" {
    count=$(zsh -c "source '$NIVUUS_SHELL_DIR/themes/nord.zsh' && source '$NIVUUS_SHELL_DIR/config/21-safety.zsh' && echo \${#WARNING_PATTERNS[@]}")
    [ "$count" -ge 5 ]
}

# =============================================================================
# Color Usage Tests
# =============================================================================

@test "Safety module uses Nord error color for dangers" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep 'NORD_ERROR' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}

@test "Safety module uses Nord colors for messages" {
    run bash -c "cd '$BATS_TEST_DIRNAME/../..' && grep -E '(NORD_PATH|NORD_FIREBASE|NORD_RESET)' config/21-safety.zsh"
    [ "$status" -eq 0 ]
}
