# =============================================================================
# VIM INTEGRATION AND CONFIGURATION
# =============================================================================

# Set vim as default editor
export EDITOR="vim"
export VISUAL="vim"

# Create modern vim configuration with system clipboard support
setup_vim_config() {
    local vim_config="$HOME/.vimrc.modern"
    
    cat > "$vim_config" << 'EOF'
" =============================================================================
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
set relativenumber
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
if has('clipboard')
    set clipboard=unnamed,unnamedplus
endif

" Mouse support
set mouse=a
if has('mouse_sgr')
    set ttymouse=sgr
endif

" Modern key mappings
" Ctrl+C for copy (visual mode)
vnoremap <C-c> "+y
" Ctrl+X for cut (visual mode)
vnoremap <C-x> "+d
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
    colorscheme default
    set background=dark
endif

" Performance
set lazyredraw
set ttyfast
EOF

    # Source the modern config if it exists
    if [[ -f "$vim_config" ]]; then
        export VIMINIT="source $vim_config"
    fi
}

# Vim aliases and functions
alias vi='vim'
alias vim.modern='vim -u ~/.vimrc.modern'

# Function to edit with modern vim
vedit() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: vedit <file>"
        return 1
    fi
    vim -u ~/.vimrc.modern "$file"
}

# Function to setup vim clipboard support
vim_clipboard_setup() {
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
        if command -v apt >/dev/null 2>&1; then
            sudo apt install -y xclip
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm xclip
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y xclip
        fi
    fi
    
    echo "Clipboard tool: ${clipboard_tool:-xclip} is available"
}

# Auto-setup on module load
setup_vim_config

# Help function
vim_help() {
    cat << 'EOF'
=== VIM INTEGRATION HELP ===

Commands:
  vedit <file>        - Edit file with modern vim config
  vim.modern          - Launch vim with modern config
  vim_clipboard_setup - Setup clipboard utilities
  vim_help           - Show this help

Modern vim features enabled:
  • Ctrl+C - Copy (visual mode)
  • Ctrl+X - Cut (visual mode)  
  • Ctrl+V - Paste (insert/normal mode)
  • Ctrl+A - Select all
  • Mouse selection and scrolling
  • System clipboard integration
  • Line numbers and syntax highlighting
EOF
}
