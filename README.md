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
- 📱 **Node.js ready** - Automatic NVM installation and management

## Installation

### Quick Install (One-line)

```bash
# Download and install for current user
curl -fsSL https://raw.githubusercontent.com/maximeallanic/shell/main/install.sh | bash

# Download and install system-wide (all users)
curl -fsSL https://raw.githubusercontent.com/maximeallanic/shell/main/install.sh | sudo bash --system
```

### Manual Installation

#### User Installation (Default)

```bash
# Clone the repository
git clone https://github.com/maximeallanic/shell.git
cd shell

# Install for current user
./install.sh

# Non-interactive installation
./install.sh --non-interactive
```

#### System-wide Installation (All Users)

```bash
# Clone the repository
git clone https://github.com/maximeallanic/shell.git
cd shell

# Install system-wide (requires sudo)
sudo ./install.sh --system

# Non-interactive system installation
sudo ./install.sh --system --non-interactive
```

### Installation Options

```bash
# Show help and available options
./install.sh --help

# Run health check on existing installation
./install.sh --health-check

# Uninstall user configuration
./install.sh --uninstall

# Uninstall system-wide configuration  
sudo ./install.sh --system --uninstall
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

## Node.js & NVM Integration

The shell automatically installs and configures NVM (Node Version Manager) for seamless Node.js development.

### Features

- **Automatic installation** - NVM is installed during shell setup
- **Smart version switching** - Auto-detects and uses `.nvmrc` files
- **VS Code integration** - Properly configured for VS Code development
- **Latest LTS default** - Installs and sets Node.js LTS as default

### Commands

- `nvm-install` - Install NVM (if not already installed)
- `nvm-update` - Update NVM to latest version
- `nvm-health` - Check NVM installation and configuration
- `nvm use <version>` - Switch to specific Node.js version
- `nvm install <version>` - Install specific Node.js version

### Automatic Behavior

- **Directory switching** - Automatically uses Node version from `.nvmrc`
- **VS Code compatibility** - Exports necessary environment variables
- **Global tools** - Adds npm global binaries to PATH

## Architecture

### Modular Installation System

This shell configuration uses a modern modular architecture for easy maintenance and extensibility:

```
shell/
├── install.sh                      # Unified installer (user & system modes)
├── install-remote.sh               # Remote user installation
├── install-system-remote.sh        # Remote system installation
├── install/                        # Modular installation components
│   ├── common.sh                   # Shared utilities and functions
│   ├── packages.sh                 # System package installation
│   ├── nvm.sh                      # Node Version Manager setup
│   ├── backup.sh                   # Backup and restore operations
│   ├── config.sh                   # Configuration management
│   ├── system.sh                   # System-wide operations
│   └── verification.sh             # Installation verification
├── config/                         # Shell configuration modules
│   ├── 01-performance.zsh          # Performance optimizations
│   ├── 02-history.zsh              # Advanced history management
│   ├── 03-completion.zsh           # Smart auto-completion
│   ├── 04-keybindings.zsh          # Enhanced key bindings
│   ├── 05-prompt.zsh               # Beautiful prompt configuration
│   ├── 06-aliases.zsh              # Useful aliases
│   ├── 07-functions.zsh            # Utility functions
│   ├── 08-ai-integration.zsh       # AI assistant integration
│   ├── 09-syntax-highlighting.zsh  # Syntax highlighting
│   ├── 10-environment.zsh          # Environment variables
│   ├── 11-maintenance.zsh          # System maintenance tools
│   ├── 12-diagnostics.zsh          # Diagnostic utilities
│   ├── 13-vim-integration.zsh      # Modern Vim integration
│   ├── 14-subtle-colors.zsh        # Color schemes
│   ├── 15-vscode-integration.zsh   # VS Code integration
│   └── 16-nvm-integration.zsh      # Node.js & NVM management
├── test-modular.sh                 # Modular architecture tests
└── MODULAR_ARCHITECTURE.md         # Detailed architecture documentation
```

### Benefits of Modular Architecture

- **🔧 Maintainability**: Each module has a single responsibility
- **🧪 Testability**: Individual components can be tested independently  
- **♻️ Reusability**: Shared functions eliminate code duplication
- **📈 Extensibility**: New features can be added as separate modules
- **⚡ Performance**: Faster development and deployment cycles

For detailed architecture documentation, see [MODULAR_ARCHITECTURE.md](MODULAR_ARCHITECTURE.md).

## System-wide Deployment

The system-wide installation creates:

- `/opt/modern-shell/` - Main configuration directory
- `/etc/vim/vimrc.modern` - System-wide vim configuration
- `/etc/zsh/zshrc.d/` - Zsh integration files
- `/etc/profile` - Shell-agnostic environment setup

All users will automatically have access to the modern shell configuration on their next login.

## Troubleshooting

### Common Issues

#### Environment Variable Alerts

If you see security warnings for environment variables, use:

```bash
# Check .env file manually
envcheck

# Silent loading (default during startup)
envload
```

#### Root/Sudo Issues

If you get "No such file or directory" when using `sudo su`:

```bash
# Fix root configuration
./fix-root.sh

# Test root access
sudo zsh -c 'echo "Root shell works"'
```

#### Cache Corruption

If you see `.zwc` file errors:

```bash
# Fix cache issues
./fix-zsh-cache.sh

# Restart shell
source ~/.zshrc
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
