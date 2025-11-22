#!/usr/bin/env zsh
# =============================================================================
# Test Mocks - Simulate external dependencies for Nivuus Shell tests
# =============================================================================

# Mock gemini-cli command
# Usage: mock_gemini "ls -la" "List files with details"
mock_gemini() {
    local input=$1
    local response=$2

    gemini() {
        echo "$response"
    }
}

# Mock gemini-cli to return error
mock_gemini_error() {
    gemini() {
        echo "ERROR: AI service unavailable" >&2
        return 1
    }
}

# Remove gemini mock
unmock_gemini() {
    unfunction gemini 2>/dev/null
}

# Mock git command
# Usage: mock_git_repo "branch-name" "modified files"
mock_git_repo() {
    local branch=$1
    local status=$2

    git() {
        case "$1" in
            symbolic-ref)
                echo "refs/heads/$branch"
                ;;
            rev-parse)
                return 0
                ;;
            status)
                if [[ "$2" == "--short" ]]; then
                    echo "$status"
                else
                    echo "On branch $branch"
                    echo "$status"
                fi
                ;;
            diff)
                echo "diff --git a/file.txt b/file.txt"
                echo "+added line"
                ;;
            *)
                command git "$@"
                ;;
        esac
    }
}

# Mock clean git repo (no changes)
mock_git_clean() {
    mock_git_repo "master" ""
}

# Mock dirty git repo (uncommitted changes)
mock_git_dirty() {
    mock_git_repo "feature-branch" " M file1.txt\n M file2.txt"
}

# Remove git mock
unmock_git() {
    unfunction git 2>/dev/null
}

# Mock SSH environment
mock_ssh_session() {
    export SSH_CLIENT="192.168.1.100 12345 22"
    export SSH_TTY="/dev/pts/0"
}

# Mock local environment (no SSH)
mock_local_session() {
    unset SSH_CLIENT
    unset SSH_TTY
    unset SESSION_TYPE
}

# Mock root user
mock_root_user() {
    EUID=0
}

# Mock regular user
mock_regular_user() {
    EUID=1000
}

# Mock AWS environment
mock_aws_env() {
    export AWS_PROFILE="production"
}

# Mock GCP environment
mock_gcp_env() {
    export CLOUDSDK_CORE_PROJECT="my-gcp-project"
}

# Mock Azure environment
mock_azure_env() {
    export AZURE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789012"
}

# Mock Python venv
mock_python_venv() {
    local venv_type=$1  # "venv", "conda", or "poetry"

    case "$venv_type" in
        venv)
            export VIRTUAL_ENV="/home/user/project/venv"
            ;;
        conda)
            export CONDA_DEFAULT_ENV="my-conda-env"
            ;;
        poetry)
            export POETRY_ACTIVE=1
            ;;
    esac
}

# Mock no Python venv
mock_no_venv() {
    unset VIRTUAL_ENV
    unset CONDA_DEFAULT_ENV
    unset POETRY_ACTIVE
}

# Mock Firebase config
mock_firebase_config() {
    local project=$1
    local fixture_dir="tests/fixtures"

    mkdir -p "$fixture_dir"
    cat > "$fixture_dir/.firebaserc" <<EOF
{
  "projects": {
    "default": "$project"
  }
}
EOF
}

# Mock NVM installation
mock_nvm_installed() {
    export NVM_DIR="/home/user/.nvm"

    nvm() {
        echo "Now using node v18.0.0"
    }

    node() {
        echo "v18.0.0"
    }

    npm() {
        echo "9.0.0"
    }
}

# Mock NVM not installed
mock_nvm_not_installed() {
    unset NVM_DIR
    unfunction nvm 2>/dev/null
    unfunction node 2>/dev/null
    unfunction npm 2>/dev/null
}

# Clean up all mocks
cleanup_all_mocks() {
    unmock_gemini
    unmock_git
    mock_local_session
    mock_regular_user
    mock_no_venv
    mock_nvm_not_installed

    unset AWS_PROFILE
    unset CLOUDSDK_CORE_PROJECT
    unset AZURE_SUBSCRIPTION_ID
}

# Create mock git repository
create_mock_git_repo() {
    local repo_dir="tests/fixtures/git_repo"

    mkdir -p "$repo_dir"
    cd "$repo_dir"

    git init
    git config user.name "Test User"
    git config user.email "test@example.com"

    echo "# Test Repo" > README.md
    git add README.md
    git commit -m "Initial commit"

    cd - >/dev/null
}

# Create mock Node.js project
create_mock_nodejs_project() {
    local project_dir="tests/fixtures/nodejs_project"

    mkdir -p "$project_dir"

    cat > "$project_dir/package.json" <<'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "build": "webpack",
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

    echo "18.0.0" > "$project_dir/.nvmrc"
}

# Create mock Python project
create_mock_python_project() {
    local project_dir="tests/fixtures/python_project"

    mkdir -p "$project_dir"

    cat > "$project_dir/requirements.txt" <<'EOF'
flask==2.3.0
requests==2.28.0
pytest==7.3.0
EOF

    mkdir -p "$project_dir/venv/bin"
    touch "$project_dir/venv/bin/activate"
}

# Restore original environment after tests
restore_environment() {
    cleanup_all_mocks
}
