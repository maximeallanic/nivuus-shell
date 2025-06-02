# Modern Shell Configuration

Ultra-fast, modular, and intelligent shell environment with advanced Vim integration.

## Features

- 🚀 **Performance optimized** - Lightning fast startup
- 🎨 **Modern Vim integration** - System clipboard, mouse support, modern shortcuts
- 📦 **Modular architecture** - Easy to customize and extend
- 🔧 **Cross-platform** - Works on Linux, macOS, and WSL
- 🌈 **Beautiful prompts** - Clean and informative
- ⚡ **Smart completions** - Enhanced auto-completion
- 🔍 **Advanced history** - Intelligent search and deduplication

## Installation

### Quick Install (One-line)

```bash
# Download and install for current user
curl -fsSL https://raw.githubusercontent.com/maximeallanic/zshrc/main/install-remote.sh | bash

# Download and install system-wide (all users)
curl -fsSL https://raw.githubusercontent.com/maximeallanic/zshrc/main/install-system-remote.sh | sudo bash
```

### Manual Installation

#### User Installation (Default)

```bash
# Clone and install for current user
git clone https://github.com/mallanic/shell.git
cd shell
./install.sh
```

#### System-wide Installation (All Users)

```bash
# Clone and install for all users on the system (requires sudo)
git clone https://github.com/mallanic/shell.git
cd shell
sudo ./install-system.sh

# Test the installation
./test-system.sh
```

## Vim Integration

### Features

- **Ctrl+C** - Copy (visual mode)
- **Ctrl+X** - Cut (visual mode)
- **Ctrl+V** - Paste (insert/normal mode)
- **Ctrl+A** - Select all
- Mouse selection and scrolling
- System clipboard integration
- Line numbers and syntax highlighting

### Commands

- `vedit <file>` - Edit file with modern vim config
- `vim.modern` - Launch vim with modern config
- `vim_install_system` - Install config system-wide
- `vim_help` - Show help

### Installation Modes

- **User mode**: `~/.vimrc.modern` (default)
- **System mode**: `/etc/vim/vimrc.modern` (system-wide)

## File Structure

```
config/
├── 01-performance.zsh     # Performance optimizations
├── 02-history.zsh         # Advanced history management
├── 03-completion.zsh      # Smart auto-completion
├── 04-keybindings.zsh     # Enhanced key bindings
├── 05-prompt.zsh          # Beautiful prompt configuration
├── 06-aliases.zsh         # Useful aliases
├── 07-functions.zsh       # Utility functions
├── 08-ai-integration.zsh  # AI assistant integration
├── 09-syntax-highlighting.zsh # Syntax highlighting
├── 10-environment.zsh     # Environment variables
├── 11-maintenance.zsh     # System maintenance tools
├── 12-diagnostics.zsh     # Diagnostic utilities
└── 13-vim-integration.zsh # Modern Vim integration
```

## System-wide Deployment

The system-wide installation creates:

- `/opt/modern-shell/` - Main configuration directory
- `/etc/vim/vimrc.modern` - System-wide vim configuration
- `/etc/zsh/zshrc.d/` - Zsh integration files
- `/etc/profile` - Shell-agnostic environment setup

All users will automatically have access to the modern shell configuration on their next login.

## Testing

```bash
# Test user installation
./test.sh

# Test system installation
./test-system.sh

# Quick functionality test
./quick-test.sh
```

## Uninstallation

```bash
# Remove user installation
./uninstall.sh

# Remove system installation (requires sudo)
sudo ./uninstall-system.sh
```

## License

MIT - See [LICENSE](LICENSE) for details.
