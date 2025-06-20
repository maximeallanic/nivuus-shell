# Test Helper Functions
# Common utilities for all tests

# Project root detection
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Test environment setup
setup_test_env() {
    export TEST_MODE=1
    export MINIMAL_MODE=1
    export SKIP_UPDATES_CHECK=true
    export ANTIGEN_CACHE_ENABLED=false
    
    # Create temporary directories
    export TEST_HOME=$(mktemp -d)
    export TEST_CONFIG_DIR="$TEST_HOME/.config"
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Backup original environment
    export ORIG_HOME="$HOME"
    export ORIG_PATH="$PATH"
    
    # Setup Node.js environment for testing
    setup_nodejs_test_env
}

# Cleanup test environment
teardown_test_env() {
    # Restore original environment
    export HOME="$ORIG_HOME"
    export PATH="$ORIG_PATH"
    
    # Clean up temporary files
    [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ] && rm -rf "$TEST_HOME"
    
    # Clean up Node.js test environment
    unset NODE_TEST_MODE NVM_DIR
    
    unset TEST_MODE MINIMAL_MODE TEST_HOME TEST_CONFIG_DIR
    unset ORIG_HOME ORIG_PATH
}

# Assert helpers
assert_file_exists() {
    [ -f "$1" ] || {
        echo "File '$1' does not exist"
        return 1
    }
}

assert_directory_exists() {
    [ -d "$1" ] || {
        echo "Directory '$1' does not exist"
        return 1
    }
}

assert_command_exists() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Command '$1' is not available"
        return 1
    }
}

assert_contains() {
    local string="$1"
    local substring="$2"
    [[ "$string" == *"$substring"* ]] || {
        echo "String '$string' does not contain '$substring'"
        return 1
    }
}

# Performance measurement
measure_startup_time() {
    local config_file="$1"
    local iterations="${2:-5}"
    local total_time=0
    
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N)
        # Suppress all output to avoid parsing issues
        zsh -c "source '$config_file'; exit 0" >/dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$((end_time - start_time))
        total_time=$((total_time + duration))
    done
    
    # Return average time in milliseconds
    echo $((total_time / iterations / 1000000))
}

# Clean output for performance measurement
clean_performance_output() {
    local output="$1"
    # Remove NVM warnings and error messages
    echo "$output" | grep -v "NVM not available" | \
                    grep -v "no such file or directory" | \
                    grep -v "⚠️" | \
                    grep -v "zsh:source:" | \
                    tail -1 | \
                    grep -oE '[0-9]+' | \
                    head -1
}

# Color output for tests
color_output() {
    local color="$1"
    local message="$2"
    
    case "$color" in
        "red")    echo -e "\033[0;31m$message\033[0m" ;;
        "green")  echo -e "\033[0;32m$message\033[0m" ;;
        "yellow") echo -e "\033[1;33m$message\033[0m" ;;
        "blue")   echo -e "\033[0;34m$message\033[0m" ;;
        *)        echo "$message" ;;
    esac
}

# Load config module safely
load_config_module() {
    local module="$1"
    local config_path="$PROJECT_ROOT/config/$module"
    
    if [ -f "$config_path" ]; then
        # Source in current shell context to make functions available
        set +e  # Don't exit on errors during sourcing
        source "$config_path"
        local exit_code=$?
        set -e
        
        if [ $exit_code -ne 0 ]; then
            echo "Failed to load module: $module"
            return 1
        fi
        return 0
    else
        echo "Module not found: $config_path"
        return 1
    fi
}

# Setup Node.js environment for testing
setup_nodejs_test_env() {
    # Check if we already have Node.js available
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        export NODE_TEST_MODE="system"
        return 0
    fi
    
    # Try to use existing NVM installation
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        source "$NVM_DIR/nvm.sh"
        
        # Use existing Node.js version or install LTS
        if ! command -v node >/dev/null 2>&1; then
            nvm use --lts >/dev/null 2>&1 || nvm install --lts >/dev/null 2>&1
        fi
        
        if command -v node >/dev/null 2>&1; then
            export NODE_TEST_MODE="nvm"
            return 0
        fi
    fi
    
    # Install minimal NVM for testing if not available
    if [ ! -s "$TEST_HOME/.nvm/nvm.sh" ]; then
        install_nvm_for_testing
    fi
}

# Install NVM specifically for testing
install_nvm_for_testing() {
    local NVM_TEST_DIR="$TEST_HOME/.nvm"
    mkdir -p "$NVM_TEST_DIR"
    
    # Download and install NVM quietly
    if command -v curl >/dev/null 2>&1; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh 2>/dev/null | \
        NVM_DIR="$NVM_TEST_DIR" bash >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh 2>/dev/null | \
        NVM_DIR="$NVM_TEST_DIR" bash >/dev/null 2>&1
    else
        # Skip installation if no download tool available
        export NODE_TEST_MODE="unavailable"
        return 1
    fi
    
    # Source NVM and install Node.js LTS
    if [ -s "$NVM_TEST_DIR/nvm.sh" ]; then
        export NVM_DIR="$NVM_TEST_DIR"
        source "$NVM_DIR/nvm.sh"
        
        # Install Node.js LTS quietly
        nvm install --lts >/dev/null 2>&1
        nvm use --lts >/dev/null 2>&1
        
        if command -v node >/dev/null 2>&1; then
            export NODE_TEST_MODE="nvm_test"
            return 0
        fi
    fi
    
    export NODE_TEST_MODE="unavailable"
    return 1
}

# Mock Node.js/npm for testing when not available
setup_nodejs_mocks() {
    if [ "$NODE_TEST_MODE" = "unavailable" ]; then
        # Create mock commands
        mkdir -p "$TEST_HOME/bin"
        
        # Mock node command
        cat > "$TEST_HOME/bin/node" << 'EOF'
#!/bin/bash
case "$1" in
    "--version") echo "v18.0.0" ;;
    *) echo "Mock Node.js for testing" ;;
esac
EOF
        chmod +x "$TEST_HOME/bin/node"
        
        # Mock npm command  
        cat > "$TEST_HOME/bin/npm" << 'EOF'
#!/bin/bash
case "$1" in
    "--version") echo "9.0.0" ;;
    "config") 
        case "$2" in
            "get") echo "/tmp/npm-global" ;;
        esac
        ;;
    *) echo "Mock npm for testing" ;;
esac
EOF
        chmod +x "$TEST_HOME/bin/npm"
        
        # Mock npx command
        cat > "$TEST_HOME/bin/npx" << 'EOF'
#!/bin/bash
echo "Mock npx for testing"
EOF
        chmod +x "$TEST_HOME/bin/npx"
        
        # Add to PATH
        export PATH="$TEST_HOME/bin:$PATH"
        export NODE_TEST_MODE="mocked"
    fi
}

# Check if Node.js is available for testing
is_nodejs_available_for_testing() {
    [ "$NODE_TEST_MODE" != "unavailable" ]
}

# Load config module with Node.js environment
load_config_with_nodejs() {
    local module="$1"
    local config_path="$PWD/config/$module"
    
    # Setup Node.js environment first
    if [ "$NODE_TEST_MODE" = "nvm" ] || [ "$NODE_TEST_MODE" = "nvm_test" ]; then
        source "$NVM_DIR/nvm.sh" 2>/dev/null || true
    fi
    
    if [ -f "$config_path" ]; then
        source "$config_path" 2>/dev/null || {
            echo "Failed to load module: $module"
            return 1
        }
    else
        echo "Module not found: $config_path"
        return 1
    fi
}
