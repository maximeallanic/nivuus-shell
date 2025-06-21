#!/usr/bin/env bash
# =============================================================================
# TEST RUNNER - Nivuus Shell Test Suite
# =============================================================================

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR="$PROJECT_ROOT/tests"
readonly BATS_VERSION="1.8.2"

print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════╗"
    echo "║         Nivuus Shell Test Suite        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "${BLUE}${BOLD}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if BATS is installed
check_bats() {
    # Check if local BATS exists first
    if [ -f "$PROJECT_ROOT/.bats/bin/bats" ]; then
        export PATH="$PROJECT_ROOT/.bats/bin:$PATH"
    fi
    
    if ! command -v bats >/dev/null 2>&1; then
        print_warning "BATS not found. Installing..."
        install_bats
    else
        local version=$(bats --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        print_success "BATS found (version: $version)"
    fi
}

# Install BATS if not available
install_bats() {
    local temp_dir=$(mktemp -d)
    local bats_dir="$PROJECT_ROOT/.bats"
    
    cd "$temp_dir"
    
    print_section "Installing BATS $BATS_VERSION locally..."
    
    if command -v git >/dev/null 2>&1; then
        git clone https://github.com/bats-core/bats-core.git
        cd bats-core
        git checkout "v$BATS_VERSION"
        
        # Install locally in project
        mkdir -p "$bats_dir"
        ./install.sh "$bats_dir"
        
        # Add to PATH for this session
        export PATH="$bats_dir/bin:$PATH"
    else
        print_error "Git is required to install BATS"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    rm -rf "$temp_dir"
    
    if command -v bats >/dev/null 2>&1; then
        print_success "BATS installed successfully"
    else
        print_error "BATS installation failed"
        exit 1
    fi
}

# Run syntax checks
run_syntax_checks() {
    print_section "Running syntax checks..."
    
    local failed=0
    
    # Check ZSH config files
    for config_file in config/*.zsh; do
        [ -f "$config_file" ] || continue
        
        if zsh -n "$config_file" 2>/dev/null; then
            echo "  ✓ $(basename "$config_file")"
        else
            echo "  ✗ $(basename "$config_file")"
            ((failed++))
        fi
    done
    
    # Check shell scripts
    for script in install/*.sh *.sh; do
        [ -f "$script" ] || continue
        
        if bash -n "$script" 2>/dev/null; then
            echo "  ✓ $(basename "$script")"
        else
            echo "  ✗ $(basename "$script")"
            ((failed++))
        fi
    done
    
    if [ "$failed" -eq 0 ]; then
        print_success "All syntax checks passed"
        return 0
    else
        print_error "$failed syntax errors found"
        return 1
    fi
}

# Run test suite
run_test_suite() {
    local test_type="$1"
    local exit_code=0
    
    case "$test_type" in
        "unit")
            print_section "Running unit tests..."
            bats "$TEST_DIR/unit/"*.bats || exit_code=$?
            ;;
        "integration")
            print_section "Running integration tests..."
            bats "$TEST_DIR/integration/"*.bats || exit_code=$?
            ;;
        "performance")
            print_section "Running performance tests..."
            bats "$TEST_DIR/performance/"*.bats || exit_code=$?
            ;;
        "compatibility")
            print_section "Running compatibility tests..."
            bats "$TEST_DIR/compatibility/"*.bats || exit_code=$?
            ;;
        "install")
            print_section "Running installation tests..."
            bats "$TEST_DIR/install/"*.bats || exit_code=$?
            ;;
        "all")
            print_section "Running all tests..."
            bats "$TEST_DIR/main.bats" \
                 "$TEST_DIR/unit/"*.bats \
                 "$TEST_DIR/integration/"*.bats \
                 "$TEST_DIR/performance/"*.bats \
                 "$TEST_DIR/compatibility/"*.bats \
                 "$TEST_DIR/install/"*.bats || exit_code=$?
            ;;
        *)
            print_error "Unknown test type: $test_type"
            exit 1
            ;;
    esac
    
    return $exit_code
}

# Generate test report
generate_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="$PROJECT_ROOT/test-report.txt"
    
    print_section "Generating test report..."
    
    {
        echo "Nivuus Shell Test Report"
        echo "Generated: $timestamp"
        echo "==============================="
        echo
        
        echo "Environment:"
        echo "- OS: $(uname -s) $(uname -r)"
        echo "- Shell: $(zsh --version 2>/dev/null || echo 'ZSH not found')"
        echo "- BATS: $(bats --version 2>/dev/null || echo 'BATS not found')"
        echo
        
        echo "Project Structure:"
        find config/ -name "*.zsh" | wc -l | xargs echo "- Config modules:"
        find install/ -name "*.sh" | wc -l | xargs echo "- Install scripts:"
        echo
        
    } > "$report_file"
    
    print_success "Report saved to: $report_file"
}

# Main function
main() {
    cd "$PROJECT_ROOT"
    
    print_header
    
    local test_type="${1:-all}"
    local generate_report_flag="${2:-false}"
    
    # Verify environment
    if [ ! -f "README.md" ]; then
        print_error "Must run from project root directory"
        exit 1
    fi
    
    # Check dependencies
    check_bats
    
    # Run syntax checks first
    if ! run_syntax_checks; then
        print_error "Syntax checks failed. Fix errors before running tests."
        exit 1
    fi
    
    # Run requested tests
    local test_exit_code=0
    run_test_suite "$test_type" || test_exit_code=$?
    
    # Generate report if requested
    if [ "$generate_report_flag" = "true" ] || [ "$generate_report_flag" = "--report" ]; then
        generate_report
    fi
    
    # Final status
    if [ "$test_exit_code" -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_error "Some tests failed (exit code: $test_exit_code)"
    fi
    
    exit $test_exit_code
}

# Show usage if no arguments or help requested
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 <test_type> [--report]"
    echo
    echo "Test types:"
    echo "  unit         - Run unit tests only"
    echo "  integration  - Run integration tests only"
    echo "  performance  - Run performance benchmarks"
    echo "  compatibility - Run compatibility tests"
    echo "  all          - Run all tests (default)"
    echo
    echo "Options:"
    echo "  --report     - Generate detailed test report"
    echo "  -h, --help   - Show this help message"
    echo
    exit 0
fi

main "$@"
