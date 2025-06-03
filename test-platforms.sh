#!/bin/bash
# =============================================================================
# CROSS-PLATFORM COMPATIBILITY TEST
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
}

# Load the detection functions
source "./install/common.sh"

print_header "Nivuus Shell Platform Compatibility Test"

# Test OS detection
print_test "Operating system detection"
if detect_os; then
    print_pass "Detected OS: $OS ($DISTRO) with package manager: $PACKAGE_MANAGER"
else
    print_fail "Could not detect operating system"
    exit 1
fi

# Test package manager availability
print_test "Package manager availability"
if check_package_manager; then
    print_pass "Package manager $PACKAGE_MANAGER is available and working"
else
    print_fail "Package manager $PACKAGE_MANAGER is not available"
    exit 1
fi

# Test required commands
print_test "Required system commands"
missing_commands=()

required_commands=(
    "curl"
    "git"
)

for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        print_pass "$cmd is available"
    else
        print_fail "$cmd is missing"
        missing_commands+=("$cmd")
    fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo
    echo -e "${YELLOW}Missing commands can be installed with:${NC}"
    case "$PACKAGE_MANAGER" in
        apt)
            echo "sudo apt install -y ${missing_commands[*]}"
            ;;
        dnf)
            echo "sudo dnf install -y ${missing_commands[*]}"
            ;;
        yum)
            echo "sudo yum install -y ${missing_commands[*]}"
            ;;
        apk)
            echo "sudo apk add ${missing_commands[*]}"
            ;;
        pacman)
            echo "sudo pacman -S ${missing_commands[*]}"
            ;;
        zypper)
            echo "sudo zypper install ${missing_commands[*]}"
            ;;
        brew)
            echo "brew install ${missing_commands[*]}"
            ;;
    esac
fi

# Test ZSH availability
print_test "ZSH shell availability"
if command -v zsh &> /dev/null; then
    print_pass "ZSH is available at: $(which zsh)"
else
    echo -e "${YELLOW}⚠️  ZSH not found, will be installed during setup${NC}"
fi

# Test sudo availability (if not macOS with Homebrew)
if [[ "$PACKAGE_MANAGER" != "brew" ]]; then
    print_test "Sudo privileges"
    if sudo -n true 2>/dev/null; then
        print_pass "Sudo access available"
    elif [[ "$EUID" -eq 0 ]]; then
        print_pass "Running as root"
    else
        echo -e "${YELLOW}⚠️  Sudo access may be required for package installation${NC}"
    fi
fi

# Platform-specific tests
print_test "Platform-specific features"

case "$PACKAGE_MANAGER" in
    apt)
        if [[ -f /etc/apt/sources.list ]]; then
            print_pass "APT sources configured"
        fi
        ;;
    brew)
        if brew --version &> /dev/null; then
            print_pass "Homebrew is functional"
        fi
        ;;
    dnf)
        if dnf --version &> /dev/null; then
            print_pass "DNF is functional"
        fi
        ;;
    yum)
        if yum --version &> /dev/null; then
            print_pass "YUM is functional"
        fi
        ;;
    apk)
        if apk --version &> /dev/null; then
            print_pass "APK is functional"
        fi
        ;;
    pacman)
        if pacman --version &> /dev/null; then
            print_pass "Pacman is functional"
        fi
        ;;
    zypper)
        if zypper --version &> /dev/null; then
            print_pass "Zypper is functional"
        fi
        ;;
esac

echo
print_header "Platform Compatibility Summary"
echo -e "Platform: ${GREEN}$OS${NC}"
echo -e "Distribution: ${GREEN}$DISTRO${NC}"
echo -e "Package Manager: ${GREEN}$PACKAGE_MANAGER${NC}"
echo -e "Status: ${GREEN}✅ Compatible${NC}"
echo
echo "Your system is ready for Nivuus Shell installation!"
echo "Run: ./install.sh"
