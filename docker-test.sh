#!/bin/bash

# Docker Test Script for ZSH Ultra Performance
# Tests installation in clean Debian/Ubuntu environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_IMAGES=("debian:bullseye" "debian:bookworm" "ubuntu:20.04" "ubuntu:22.04" "ubuntu:latest")
CONTAINER_PREFIX="zsh-test"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

cleanup_containers() {
    log "Cleaning up test containers..."
    for image in "${TEST_IMAGES[@]}"; do
        container_name="${CONTAINER_PREFIX}-$(echo "$image" | tr ':/' '-')"
        if docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"; then
            docker rm -f "$container_name" >/dev/null 2>&1 || true
        fi
    done
}

test_image() {
    local image="$1"
    local container_name="${CONTAINER_PREFIX}-$(echo "$image" | tr ':/' '-')"
    
    log "Testing installation on $image..."
    
    # Create and start container
    docker run -d --name "$container_name" \
        -v "$SCRIPT_DIR:/zsh-config:ro" \
        "$image" \
        sleep 3600 >/dev/null
    
    # Install required packages
    docker exec "$container_name" bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq sudo curl git zsh
        useradd -m -s /bin/bash testuser
        echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    " >/dev/null 2>&1
    
    # Copy configuration and test
    docker exec "$container_name" bash -c "
        cp -r /zsh-config /home/testuser/
        chown -R testuser:testuser /home/testuser/zsh-config
        chmod +x /home/testuser/zsh-config/*.sh
    " >/dev/null 2>&1
    
    # Run installation test
    if docker exec -u testuser "$container_name" bash -c "
        cd /home/testuser/zsh-config
        echo 'y' | ./install.sh --non-interactive >/dev/null 2>&1
        source ~/.zshrc >/dev/null 2>&1
        ./quick-test.sh >/dev/null 2>&1
    "; then
        success "Installation successful on $image"
        return 0
    else
        error "Installation failed on $image"
        return 1
    fi
}

main() {
    local failed_tests=0
    local total_tests=${#TEST_IMAGES[@]}
    
    log "Starting Docker tests for ZSH Ultra Performance"
    log "Testing on ${total_tests} different images..."
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    # Cleanup any existing containers
    cleanup_containers
    
    # Pull images in parallel for faster testing
    log "Pulling Docker images..."
    for image in "${TEST_IMAGES[@]}"; do
        docker pull "$image" >/dev/null 2>&1 &
    done
    wait
    
    # Run tests
    for image in "${TEST_IMAGES[@]}"; do
        if ! test_image "$image"; then
            ((failed_tests++))
        fi
        
        # Cleanup container after test
        container_name="${CONTAINER_PREFIX}-$(echo "$image" | tr ':/' '-')"
        docker rm -f "$container_name" >/dev/null 2>&1 || true
    done
    
    # Results
    echo
    log "Docker Test Results:"
    log "Total tests: $total_tests"
    log "Passed: $((total_tests - failed_tests))"
    log "Failed: $failed_tests"
    
    if [ "$failed_tests" -eq 0 ]; then
        success "All Docker tests passed!"
        exit 0
    else
        error "Some Docker tests failed"
        exit 1
    fi
}

# Handle interrupts
trap cleanup_containers EXIT INT TERM

# Check arguments
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --cleanup      Only cleanup existing containers"
    echo ""
    echo "This script tests ZSH Ultra Performance installation"
    echo "in clean Docker containers with different Debian/Ubuntu versions."
    exit 0
fi

if [ "${1:-}" = "--cleanup" ]; then
    cleanup_containers
    success "Cleanup completed"
    exit 0
fi

# Run main function
main "$@"