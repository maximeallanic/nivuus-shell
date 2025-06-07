#!/bin/bash
# Enhanced backup script with robust gcloud preservation

# Check if a line contains user configuration
is_user_config() {
    local line="$1"
    
    # Skip empty lines and our own configuration
    [[ -z "$line" ]] && return 1
    [[ "$line" =~ ^#.*Modern.*ZSH.*Configuration ]] && return 1
    [[ "$line" =~ ^export.*ZSH_CONFIG_DIR ]] && return 1
    [[ "$line" =~ ^\[.*-r.*config_file ]] && return 1
    [[ "$line" =~ ^for.*config_file.*in ]] && return 1
    
    # Node.js/NVM configurations
    [[ "$line" =~ ^export.*NVM_DIR ]] && return 0
    [[ "$line" =~ ^\[.*-s.*nvm\.sh ]] && return 0
    [[ "$line" =~ ^\[.*-s.*bash_completion ]] && return 0
    
    # Google Cloud SDK configurations - enhanced patterns
    [[ "$line" =~ gcloud ]] && return 0
    [[ "$line" =~ google-cloud-sdk ]] && return 0
    [[ "$line" =~ ^source.*google-cloud ]] && return 0
    [[ "$line" =~ ^\..*google-cloud ]] && return 0
    [[ "$line" =~ path\.zsh\.inc ]] && return 0
    [[ "$line" =~ completion\.zsh\.inc ]] && return 0
    [[ "$line" =~ ^export.*GOOGLE_CLOUD ]] && return 0
    [[ "$line" =~ ^export.*GCLOUD ]] && return 0
    [[ "$line" =~ ^export.*GOOGLE_APPLICATION_CREDENTIALS ]] && return 0
    [[ "$line" =~ ^export.*CLOUDSDK ]] && return 0
    [[ "$line" =~ ^PATH.*gcloud ]] && return 0
    [[ "$line" =~ ^PATH.*google-cloud ]] && return 0
    [[ "$line" =~ ^alias.*gcloud ]] && return 0
    
    # Other development environments
    [[ "$line" =~ pyenv ]] && return 0
    [[ "$line" =~ rbenv ]] && return 0
    [[ "$line" =~ conda ]] && return 0
    [[ "$line" =~ anaconda ]] && return 0
    [[ "$line" =~ miniconda ]] && return 0
    [[ "$line" =~ ^export.*JAVA_HOME ]] && return 0
    [[ "$line" =~ ^export.*ANDROID ]] && return 0
    [[ "$line" =~ ^export.*FLUTTER ]] && return 0
    [[ "$line" =~ ^export.*DART ]] && return 0
    
    # Common shell customizations
    [[ "$line" =~ ^source.*\.bashrc ]] && return 0
    [[ "$line" =~ ^source.*\.profile ]] && return 0
    [[ "$line" =~ ^source.*\.bash_profile ]] && return 0
    [[ "$line" =~ ^alias ]] && return 0
    [[ "$line" =~ ^function ]] && return 0
    
    # User configuration comments
    [[ "$line" =~ ^#.*User ]] && return 0
    [[ "$line" =~ ^#.*Personal ]] && return 0
    [[ "$line" =~ ^#.*Custom ]] && return 0
    [[ "$line" =~ ^#.*My ]] && return 0
    [[ "$line" =~ ^#.*Added.by ]] && return 0
    [[ "$line" =~ ^#.*The.next.line ]] && return 0
    [[ "$line" =~ ^#.*This.line ]] && return 0
    [[ "$line" =~ ^#.*Enable ]] && return 0
    [[ "$line" =~ ^#.*Load ]] && return 0
    [[ "$line" =~ ^#.*Initialize ]] && return 0
    
    # PATH modifications (but not our own)
    if [[ "$line" =~ ^export.*PATH.*= ]] && [[ ! "$line" =~ ZSH_CONFIG_DIR ]]; then
        return 0
    fi
    
    return 1
}

# Extract user configurations
extract_user_configs() {
    local source_file="$1"
    local output_file="$2"
    
    [[ ! -f "$source_file" ]] && return 1
    
    local temp_file
    temp_file=$(mktemp)
    local found_configs=false
    local in_preserved_section=false
    
    while IFS= read -r line; do
        # Check for preserved section markers
        if [[ "$line" =~ ^#.*PRESERVED.*USER.*CONFIGURATIONS ]]; then
            in_preserved_section=true
            continue
        fi
        
        # End of preserved section
        if [[ "$in_preserved_section" == true ]] && [[ "$line" =~ ^#.*===.*=== ]]; then
            in_preserved_section=false
            continue
        fi
        
        # Include everything in preserved section
        if [[ "$in_preserved_section" == true ]]; then
            echo "$line" >> "$temp_file"
            found_configs=true
            continue
        fi
        
        # Check if line is user configuration
        if is_user_config "$line"; then
            echo "$line" >> "$temp_file"
            found_configs=true
        fi
    done < "$source_file"
    
    if [[ "$found_configs" == true ]]; then
        # Clean up empty lines and save
        sed '/^$/N;/^\n$/d' "$temp_file" > "$output_file"
        rm -f "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Main function for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Testing backup script..."
    if [[ -f ~/.zshrc ]]; then
        temp_output=$(mktemp)
        if extract_user_configs ~/.zshrc "$temp_output"; then
            echo "✅ Successfully extracted user configurations:"
            cat "$temp_output"
            rm -f "$temp_output"
        else
            echo "❌ No user configurations found"
        fi
    else
        echo "❌ ~/.zshrc not found"
    fi
fi
