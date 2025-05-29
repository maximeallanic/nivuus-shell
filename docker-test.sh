#!/bin/bash
# ZSH Ultra Performance Config - Docker Test
# Test the installation in a clean Debian environment

set -euo pipefail

# Build test image
docker build -t zsh-ultra-test -f- . << 'EOF'
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    wget \
    sudo \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser

# Copy configuration
COPY . /home/testuser/zsh-config/
RUN chown -R testuser:testuser /home/testuser/zsh-config/

# Switch to test user
USER testuser
WORKDIR /home/testuser/zsh-config

# Set up ZSH as default shell for user
RUN sudo chsh -s /bin/zsh testuser

CMD ["/bin/bash"]
EOF

echo "🐳 Docker test image built successfully!"
echo ""
echo "To test the installation:"
echo "  docker run -it zsh-ultra-test"
echo ""
echo "Inside the container, run:"
echo "  ./install.sh"
echo "  zsh"
echo "  zsh_health_check"
echo ""
echo "To clean up:"
echo "  docker rmi zsh-ultra-test"
NTAINER_PREFIX}-$(echo "$image" | tr ':/' '-')"
    
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