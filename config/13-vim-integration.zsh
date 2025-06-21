#!/usr/bin/env zsh
# shell: zsh
# =============================================================================
# VIM INTEGRATION AND CONFIGURATION
# =============================================================================

# Set vim as default editor
export EDITOR="vim"
export VISUAL="vim"

# Install Nord colorscheme for Vim (official version from GitHub)
install_nord_colorscheme() {
    local is_system_install="${1:-false}"
    local user_colors_dir="$HOME/.vim/colors"
    local system_colors_dir="/etc/vim/colors"
    
    # Check if Nord theme already exists
    local nord_file="$user_colors_dir/nord.vim"
    if [[ "$is_system_install" == true ]]; then
        nord_file="$system_colors_dir/nord.vim"
    fi
    
    if [[ -f "$nord_file" ]]; then
        return 0  # Already installed, skip download
    fi
    
    # Create colors directories
    if [[ "$is_system_install" == true ]]; then
        sudo mkdir -p "$system_colors_dir"
        [[ ! -d "$user_colors_dir" ]] && mkdir -p "$user_colors_dir"
    else
        mkdir -p "$user_colors_dir"
    fi
    
    # Download official Nord theme from GitHub
    local nord_url="https://raw.githubusercontent.com/nordtheme/vim/main/colors/nord.vim"
    local temp_file="/tmp/nord_vim_theme.vim"
    
    echo "Downloading official Nord theme from GitHub..."
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$nord_url" -o "$temp_file"; then
            # Install for user
            cp "$temp_file" "$user_colors_dir/nord.vim"
            echo "Nord colorscheme installed for user"
            
            # Install system-wide if requested
            if [[ "$is_system_install" == true ]]; then
                sudo cp "$temp_file" "$system_colors_dir/nord.vim"
                echo "Nord colorscheme installed system-wide"
            fi
            
            rm -f "$temp_file"
        else
            echo "Warning: Failed to download Nord theme, using fallback"
            # Fallback: create a minimal nord-like theme
            create_fallback_nord_theme "$is_system_install"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$nord_url" -O "$temp_file"; then
            cp "$temp_file" "$user_colors_dir/nord.vim"
            echo "Nord colorscheme installed for user"
            
            if [[ "$is_system_install" == true ]]; then
                sudo cp "$temp_file" "$system_colors_dir/nord.vim"
                echo "Nord colorscheme installed system-wide"
            fi
            
            rm -f "$temp_file"
        else
            echo "Warning: Failed to download Nord theme, using fallback"
            create_fallback_nord_theme "$is_system_install"
        fi
    else
        echo "Warning: Neither curl nor wget available, using fallback"
        create_fallback_nord_theme "$is_system_install"
    fi
}

# Fallback function to create a basic Nord-like theme
create_fallback_nord_theme() {
    local is_system_install="${1:-false}"
    local user_colors_dir="$HOME/.vim/colors"
    local system_colors_dir="/etc/vim/colors"
    
    local fallback_nord='" Fallback Nord theme for Vim
set background=dark
hi clear
if exists("syntax_on") | syntax reset | endif
let g:colors_name = "nord"

hi Normal       ctermfg=252 ctermbg=233 guifg=#D8DEE9 guibg=#2E3440
hi CursorLine   ctermbg=234 guibg=#3B4252 cterm=NONE gui=NONE
hi LineNr       ctermfg=238 guifg=#4C566A
hi Visual       ctermbg=236 guibg=#434C5E
hi Comment      ctermfg=238 guifg=#4C566A cterm=italic gui=italic
hi Constant     ctermfg=4   guifg=#81A1C1
hi String       ctermfg=2   guifg=#A3BE8C
hi Function     ctermfg=6   guifg=#88C0D0
hi Statement    ctermfg=4   guifg=#81A1C1
hi Type         ctermfg=4   guifg=#81A1C1'

    echo "$fallback_nord" > "$user_colors_dir/nord.vim"
    if [[ "$is_system_install" == true ]]; then
        echo "$fallback_nord" | sudo tee "$system_colors_dir/nord.vim" > /dev/null
    fi
}

# Create modern vim configuration with system clipboard support
setup_vim_config() {
    local vim_config
    local is_system_install=false
    
    # Determine installation mode
    if [[ "${1:-}" == "--system" ]] || [[ "$EUID" -eq 0 ]]; then
        vim_config="/etc/vim/vimrc.modern"
        is_system_install=true
    else
        vim_config="$HOME/.vimrc.modern"
    fi
    
    # Create configuration directory if needed
    if [[ "$is_system_install" == true ]]; then
        [[ ! -d "/etc/vim" ]] && sudo mkdir -p "/etc/vim"
    fi
    
    # Install Nord colorscheme
    install_nord_colorscheme "$is_system_install"
    
    # Create the config file
    local config_content='" =============================================================================
" MODERN VIM CONFIGURATION
" Enhanced usability with system clipboard and mouse support
" =============================================================================

" Basic settings
set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,latin1

" Visual and behavior
syntax on
set number
set norelativenumber
set ruler
set cursorline
set showmatch
set hlsearch
set incsearch
set ignorecase
set smartcase

" Indentation and formatting
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set backspace=indent,eol,start

" System clipboard integration
set clipboard=unnamedplus
if has('\''clipboard'\'')
    set clipboard=unnamed,unnamedplus
endif

" Mouse support - allows selection without entering visual mode
set mouse=a
if has('\''mouse_sgr'\'')
    set ttymouse=sgr
endif

" Disable visual mode on mouse selection for SSH compatibility
set selectmode=mouse
set keymodel=startsel

" Modern key mappings
" Ctrl+C for copy and exit visual mode
vnoremap <C-c> "+y<Esc>
" Ctrl+X for cut and exit visual mode
vnoremap <C-x> "+d<Esc>
" Ctrl+V for paste (insert and normal mode)
inoremap <C-v> <C-r>+
nnoremap <C-v> "+p
" Ctrl+A for select all
nnoremap <C-a> ggVG

" Modern behavior
set wildmenu
set wildmode=longest:full,full
set history=1000
set undolevels=1000

" File handling
set autoread
set noswapfile
set nobackup
set writebackup

" Status line
set laststatus=2
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ [BUFFER=%n]

" Color scheme improvements
if &t_Co > 2 || has("gui_running")
    try
        colorscheme nord
        set background=dark
    catch
        colorscheme default
        set background=dark
    endtry
else
    colorscheme default
    set background=dark
endif

" Performance
set lazyredraw
set ttyfast'

    # Write configuration only if it doesn't exist
    if [[ ! -f "$vim_config" ]]; then
        if [[ "$is_system_install" == true ]]; then
            echo "$config_content" | sudo tee "$vim_config" > /dev/null
            sudo chmod 644 "$vim_config"
            echo "System-wide vim configuration created at: $vim_config"
        else
            echo "$config_content" > "$vim_config"
            echo "User vim configuration created at: $vim_config"
        fi
    fi

    # Setup VIMINIT for the current session
    if [[ -f "$vim_config" ]]; then
        if [[ "$is_system_install" == true ]]; then
            export VIMINIT="source /etc/vim/vimrc.modern"
        else
            export VIMINIT="source $vim_config"
        fi
    fi
}

# Install vim config system-wide
vim_install_system() {
    echo "Installing vim configuration system-wide..."
    setup_vim_config --system
    
    # Create system-wide profile entry
    local profile_entry='# Modern vim configuration
if [[ -f /etc/vim/vimrc.modern ]]; then
    export VIMINIT="source /etc/vim/vimrc.modern"
fi'
    
    # Add to system profile if not already present
    if ! grep -q "vimrc.modern" /etc/profile 2>/dev/null; then
        echo "$profile_entry" | sudo tee -a /etc/profile > /dev/null
        echo "Added vim configuration to /etc/profile"
    fi
    
    # Create system-wide zsh configuration
    local zsh_config_dir="/etc/zsh/zshrc.d"
    if [[ ! -d "$zsh_config_dir" ]]; then
        sudo mkdir -p "$zsh_config_dir"
    fi
    
    echo "$profile_entry" | sudo tee "$zsh_config_dir/99-vim-modern.zsh" > /dev/null
    echo "Created system-wide zsh configuration"
    
    # Install configuration for root user specifically
    setup_root_vim_config
    
    vim_clipboard_setup --system
}

# Setup vim configuration specifically for root user
setup_root_vim_config() {
    echo "Installing vim configuration for root user..."
    
    local root_vim_config="/root/.vimrc.modern"
    local root_zshrc="/root/.zshrc"
    
    # Copy the modern vim configuration to root
    if [[ -f "/etc/vim/vimrc.modern" ]]; then
        sudo cp "/etc/vim/vimrc.modern" "$root_vim_config"
        sudo chmod 644 "$root_vim_config"
        echo "Vim configuration copied to root: $root_vim_config"
    fi
    
    # Setup root's shell configuration
    local root_vim_setup='# Modern vim configuration for root
if [[ -f /root/.vimrc.modern ]]; then
    export VIMINIT="source /root/.vimrc.modern"
elif [[ -f /etc/vim/vimrc.modern ]]; then
    export VIMINIT="source /etc/vim/vimrc.modern"
fi

# Set vim as default editor
export EDITOR="vim"
export VISUAL="vim"'
    
    # Add to root's .zshrc if it exists, or create it
    if [[ -f "$root_zshrc" ]]; then
        if ! sudo grep -q "vimrc.modern" "$root_zshrc" 2>/dev/null; then
            echo "" | sudo tee -a "$root_zshrc" > /dev/null
            echo "$root_vim_setup" | sudo tee -a "$root_zshrc" > /dev/null
            echo "Added vim configuration to root's .zshrc"
        fi
    else
        echo "$root_vim_setup" | sudo tee "$root_zshrc" > /dev/null
        echo "Created root's .zshrc with vim configuration"
    fi
    
    # Also add to root's .bashrc for bash compatibility
    local root_bashrc="/root/.bashrc"
    if [[ -f "$root_bashrc" ]]; then
        if ! sudo grep -q "vimrc.modern" "$root_bashrc" 2>/dev/null; then
            echo "" | sudo tee -a "$root_bashrc" > /dev/null
            echo "$root_vim_setup" | sudo tee -a "$root_bashrc" > /dev/null
            echo "Added vim configuration to root's .bashrc"
        fi
    fi
    
    echo "Root user vim configuration completed"
}

# Enhanced aliases with Nord theme support
alias vi='smart_vim'
alias vim='smart_vim'
alias vim.nord='command vim -u ~/.vimrc.modern || command vim -u /etc/vim/vimrc.modern'

# Vim aliases and functions
alias vim.modern='command vim -u ~/.vimrc.modern || command vim -u /etc/vim/vimrc.modern'

# Aliases for SSH-optimized vim
alias vim.ssh='command vim -u ~/.vimrc.ssh 2>/dev/null || command vim -u /etc/vim/vimrc.ssh 2>/dev/null || command vim'
alias vssh='vim.ssh'
alias vim-minimal='command vim -u ~/.vimrc.minimal 2>/dev/null || command vim'

# Function to edit with modern vim
vedit() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: vedit <file>"
        return 1
    fi
    
    # Try user config first, then system config
    if [[ -f "$HOME/.vimrc.modern" ]]; then
        command vim -u "$HOME/.vimrc.modern" "$file"
    elif [[ -f "/etc/vim/vimrc.modern" ]]; then
        command vim -u "/etc/vim/vimrc.modern" "$file"
    else
        command vim "$file"
    fi
}

# Function to setup vim clipboard support
vim_clipboard_setup() {
    local is_system_install=false
    [[ "${1:-}" == "--system" ]] && is_system_install=true
    
    echo "Setting up vim clipboard support..."
    
    # Check for clipboard utilities
    local clipboard_tool=""
    if command -v xclip >/dev/null 2>&1; then
        clipboard_tool="xclip"
    elif command -v xsel >/dev/null 2>&1; then
        clipboard_tool="xsel"
    elif command -v wl-clipboard >/dev/null 2>&1; then
        clipboard_tool="wl-clipboard"
    else
        echo "Installing xclip for clipboard support..."
        local install_cmd=""
        if command -v apt >/dev/null 2>&1; then
            install_cmd="apt install -y xclip"
        elif command -v pacman >/dev/null 2>&1; then
            install_cmd="pacman -S --noconfirm xclip"
        elif command -v dnf >/dev/null 2>&1; then
            install_cmd="dnf install -y xclip"
        fi
        
        if [[ -n "$install_cmd" ]]; then
            if [[ "$is_system_install" == true ]] || [[ "$EUID" -eq 0 ]]; then
                eval "$install_cmd"
            else
                sudo $install_cmd
            fi
        fi
    fi
    
    echo "Clipboard tool: ${clipboard_tool:-xclip} is available"
}

# Function to setup vim for SSH usage with optimal mouse support
vim_ssh_setup() {
    local ssh_vim_config
    local is_system_install=false
    
    # Determine installation mode
    if [[ "${1:-}" == "--system" ]] || [[ "$EUID" -eq 0 ]]; then
        ssh_vim_config="/etc/vim/vimrc.ssh"
        is_system_install=true
    else
        ssh_vim_config="$HOME/.vimrc.ssh"
    fi
    
    # Create SSH-optimized vim configuration
    local ssh_config_content='" =============================================================================
" WEB/REMOTE-OPTIMIZED VIM CONFIGURATION
" Simple config for vscode.dev, Chromebook, SSH - terminal handles selection
" =============================================================================

" Basic settings
set nocompatible
set encoding=utf-8
syntax on
set number
set norelativenumber
set ruler
set cursorline

" COMPLETELY DISABLE VIM MOUSE - let terminal handle everything
set mouse=
set ttymouse=

" Remove all mouse mappings
if has("mouse")
    set mouse=
endif

" Clear any existing mouse mappings
silent! nunmap <LeftMouse>
silent! nunmap <LeftDrag>
silent! nunmap <LeftRelease>
silent! nunmap <RightMouse>
silent! iunmap <LeftMouse>
silent! iunmap <LeftDrag>
silent! iunmap <LeftRelease>
silent! iunmap <RightMouse>
silent! vunmap <LeftMouse>
silent! vunmap <LeftDrag>
silent! vunmap <LeftRelease>
silent! vunmap <RightMouse>

" No selection modes that interfere with terminal
set selectmode=
set keymodel=

" Line numbers and basic visual settings
set number
set showmatch
set hlsearch
set incsearch

" Indentation
set autoindent
set tabstop=4
set shiftwidth=4
set expandtab

" Status line optimized for web
set laststatus=2
set statusline=%F\ [%l:%c]\ %p%%\ [SHIFT+CLICK\ TO\ SELECT]

" Performance for web environments
set lazyredraw
set ttyfast
set timeout
set timeoutlen=1000
set ttimeoutlen=50
set updatetime=300

" Disable problematic features
set noswapfile
set nobackup
set nowritebackup

" Color scheme
if &t_Co > 2
    try
        colorscheme nord
        set background=dark
    catch
        colorscheme default
        set background=dark
    endtry
endif'

    # Write SSH configuration
    if [[ "$is_system_install" == true ]]; then
        echo "$ssh_config_content" | sudo tee "$ssh_vim_config" > /dev/null
        sudo chmod 644 "$ssh_vim_config"
        echo "SSH vim configuration created at: $ssh_vim_config"
    else
        echo "$ssh_config_content" > "$ssh_vim_config"
        echo "SSH vim configuration created at: $ssh_vim_config"
    fi
}

# Aliases for SSH-optimized vim
alias vim.ssh='command vim -u ~/.vimrc.ssh 2>/dev/null || command vim -u /etc/vim/vimrc.ssh 2>/dev/null || command vim'
alias vssh='vim.ssh'
alias vim-minimal='command vim -u ~/.vimrc.minimal 2>/dev/null || command vim'

# Function to detect environment and use appropriate vim config
smart_vim() {
    local file="$1"
    
    # Force web/remote config for better compatibility
    # Check for various remote/web environments OR default to web-friendly config
    if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ -n "$CODESPACES" ]] || [[ -n "$GITPOD_WORKSPACE_ID" ]] || [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_IPC_HOOK_CLI" ]] || [[ "$TERM" == "xterm-256color" ]]; then
        # We're in a remote/web environment, use terminal-friendly config
        if [[ -f "$HOME/.vimrc.ssh" ]]; then
            command vim -u "$HOME/.vimrc.ssh" "$file"
        elif [[ -f "/etc/vim/vimrc.ssh" ]]; then
            command vim -u "/etc/vim/vimrc.ssh" "$file"
        else
            vim_ssh_setup
            command vim -u "$HOME/.vimrc.ssh" "$file"
        fi
    else
        # Local usage, use modern config
        if [[ -f "$HOME/.vimrc.modern" ]]; then
            command vim -u "$HOME/.vimrc.modern" "$file"
        elif [[ -f "/etc/vim/vimrc.modern" ]]; then
            command vim -u "/etc/vim/vimrc.modern" "$file"
        else
            command vim "$file"
        fi
    fi
}

# Auto-setup on module load (user config only) - only if not already configured
if [[ ! -f "$HOME/.vimrc.modern" ]] && [[ ! -f "/etc/vim/vimrc.modern" ]]; then
    setup_vim_config
fi

# Auto-setup SSH config if needed
if [[ ! -f "$HOME/.vimrc.ssh" ]] && [[ ! -f "/etc/vim/vimrc.ssh" ]]; then
    vim_ssh_setup
fi

# Help function
vim_help() {
    cat << 'EOF'
=== VIM INTEGRATION HELP ===

Commands:
  vi/vim <file>            - Smart vim (auto-detects SSH and uses appropriate config)
  vedit <file>             - Edit file with modern vim config (local)
  vim.ssh <file>           - Force SSH-optimized vim config
  vssh <file>              - Alias for vim.ssh
  vim.modern               - Launch vim with modern config
  vim.nord                 - Launch vim with Nord theme
  vim_install_system       - Install config system-wide (requires sudo)
  vim_ssh_setup            - Setup SSH-optimized vim config
  setup_root_vim_config    - Setup vim config for root user
  vim_clipboard_setup      - Setup clipboard utilities
  install_nord_colorscheme - Install Nord colorscheme
  vim_help                 - Show this help

Features enabled:
  LOCAL USAGE:
  • Line numbers (absolute, not relative)
  • Full mouse support with visual mode
  • System clipboard integration
  • Modern key mappings (Ctrl+C/X/V/A)
  
  SSH/WEB USAGE (vscode.dev, Chromebook, SSH):
  • Line numbers displayed
  • Mouse handling: HOLD SHIFT + click and drag to select
  • Copy with Ctrl+C or right-click after selection
  • Automatic detection of remote environments
  • Terminal bypasses vim for text selection

Mouse behavior in remote environments:
  • Mouse disabled in vim - use terminal selection
  • Click and drag to select text (works now!)
  • Copy with Ctrl+C or right-click
  • Works with SSH, vscode.dev, Chromebook, Codespaces

Installation modes:
  • User mode: ~/.vimrc.modern & ~/.vimrc.ssh
  • System mode: /etc/vim/vimrc.modern & /etc/vim/vimrc.ssh
  • Root mode: /root/.vimrc.* 
EOF
}
