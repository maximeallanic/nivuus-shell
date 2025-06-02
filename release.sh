#!/usr/bin/env zsh

# ZSH Ultra Performance Config - Release Automation Script
# Automates version bumping, tagging, and release deployment

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly VERSION_FILE="VERSION"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
    fi
}

# Check if working directory is clean
check_clean_working_dir() {
    if [[ -n $(git status --porcelain) ]]; then
        log_error "Working directory is not clean. Please commit or stash changes."
    fi
}

# Read current version from VERSION file
read_current_version() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        log_error "VERSION file not found"
    fi
    cat "$VERSION_FILE" | tr -d '\n'
}

# Parse semantic version
parse_version() {
    local version="$1"
    if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        log_error "Invalid version format: $version (expected: x.y.z)"
    fi
    
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
}

# Increment version based on type
increment_version() {
    local current_version="$1"
    local bump_type="$2"
    
    read -r major minor patch <<< "$(parse_version "$current_version")"
    
    case "$bump_type" in
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        *)
            log_error "Invalid bump type: $bump_type (expected: major, minor, or patch)"
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Update VERSION file
update_version_file() {
    local new_version="$1"
    echo "$new_version" > "$VERSION_FILE"
    log_success "Updated VERSION file to $new_version"
}

# Create git commit and tag
create_release() {
    local version="$1"
    local tag_name="v$version"
    
    # Add and commit VERSION file
    git add "$VERSION_FILE"
    git commit -m "chore: bump version to $version"
    
    # Create annotated tag
    git tag -a "$tag_name" -m "Release $version

Automated release created by release.sh script.
See CHANGELOG.md for detailed changes."
    
    log_success "Created commit and tag $tag_name"
}

# Push changes and tag
push_release() {
    local version="$1"
    local tag_name="v$version"
    
    log_info "Pushing changes and tag to origin..."
    git push origin main
    git push origin "$tag_name"
    
    log_success "Pushed commit and tag $tag_name to origin"
    log_info "GitHub Actions will automatically create the release"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <bump_type>

Automate version bumping and release creation for ZSH Ultra Performance Config.

ARGUMENTS:
    bump_type    Version increment type: major, minor, or patch

OPTIONS:
    -h, --help      Show this help message
    -d, --dry-run   Show what would be done without making changes
    -y, --yes       Skip confirmation prompts

EXAMPLES:
    $0 patch        # 1.0.0 -> 1.0.1
    $0 minor        # 1.0.0 -> 1.1.0
    $0 major        # 1.0.0 -> 2.0.0
    $0 -d patch     # Dry run to see what would happen
    $0 -y minor     # Skip confirmation prompts

EOF
}

# Main function
main() {
    local bump_type=""
    local dry_run=false
    local skip_confirmation=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -y|--yes)
                skip_confirmation=true
                shift
                ;;
            major|minor|patch)
                bump_type="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done
    
    # Validate arguments
    if [[ -z "$bump_type" ]]; then
        log_error "Bump type is required. Use --help for usage information."
    fi
    
    # Perform checks
    check_git_repo
    check_clean_working_dir
    
    # Get current version and calculate new version
    local current_version
    current_version=$(read_current_version)
    local new_version
    new_version=$(increment_version "$current_version" "$bump_type")
    
    # Show what will be done
    echo
    log_info "Release Summary:"
    echo "  Current version: $current_version"
    echo "  New version:     $new_version"
    echo "  Bump type:       $bump_type"
    echo "  Tag name:        v$new_version"
    echo
    
    if [[ "$dry_run" == true ]]; then
        log_warning "DRY RUN - No changes will be made"
        echo "Actions that would be performed:"
        echo "  1. Update VERSION file to $new_version"
        echo "  2. Create commit: 'chore: bump version to $new_version'"
        echo "  3. Create tag: v$new_version"
        echo "  4. Push commit and tag to origin"
        echo "  5. GitHub Actions will create the release automatically"
        exit 0
    fi
    
    # Confirmation prompt
    if [[ "$skip_confirmation" == false ]]; then
        echo -n "Proceed with release? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Release cancelled"
            exit 0
        fi
    fi
    
    # Perform release
    echo
    log_info "Creating release..."
    
    update_version_file "$new_version"
    create_release "$new_version"
    push_release "$new_version"
    
    echo
    log_success "Release $new_version created successfully!"
    log_info "Monitor GitHub Actions at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
}

# Run main function with all arguments
main "$@"
