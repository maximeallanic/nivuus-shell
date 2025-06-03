# Nivuus Shell

🚀 **Ultra-fast, intelligent, and AI-powered ZSH configuration** with advanced integrations, performance monitoring, and developer-focused features.

## ✨ Core Features

### 🤖 **AI-Powered Assistant**
- **GitHub Copilot CLI** integration - Get instant command suggestions
- **Smart command explanation** - Understand complex commands instantly
- **Interactive AI help** - `??`, `?git`, `ask`, `why`, `explain` commands
- **Context-aware suggestions** - AI learns from your workflow

### ⚡ **Ultra-Performance**
- **Sub-300ms startup** - Lightning-fast shell initialization
- **Async prompt** - Non-blocking git status and performance indicators
- **Smart caching** - Intelligent completion and module caching
- **Background maintenance** - Auto-cleanup and optimization
- **Performance monitoring** - Real-time benchmarking and profiling

### 🎨 **Modern Vim Integration**
- **System clipboard** - Seamless copy/paste with Ctrl+C/V/X/A
- **Mouse support** - Click, drag, and scroll naturally
- **SSH/Remote optimized** - Perfect for VS Code, Chromebook, SSH
- **Nord theme** - Beautiful syntax highlighting
- **Smart detection** - Auto-adapts to local vs remote environments

### 🏗️ **Advanced Architecture**
- **17 specialized modules** - Highly modular and maintainable
- **Smart project detection** - Auto-configures for Node.js, Python, Rust, Go
- **Environment management** - Secure .env handling with validation
- **Cross-platform** - Linux, macOS, WSL2 support
- **Root-safe mode** - Secure minimal configuration for privileged access

### 📦 **Developer Experience**
- **Node.js/NVM** - Auto-installation and smart version switching
- **VS Code integration** - Seamless terminal and task integration
- **Modern CLI tools** - eza, bat, fd, ripgrep with smart fallbacks
- **Git enhancements** - Beautiful logs, smart aliases, status indicators
- **Project workflows** - Auto-detection and setup suggestions

### 🔧 **System Intelligence**
- **Health monitoring** - Comprehensive diagnostics and benchmarking
- **Auto-maintenance** - Smart cleanup and optimization
- **Backup system** - Automatic configuration backup and restore
- **Network utilities** - IP detection, port scanning, weather info
- **Security features** - Safe environment variable handling

## 🚀 Quick Start

### One-Line Installation

```bash
# Install for current user (recommended)
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | bash

# System-wide installation (all users)
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | sudo bash -s -- --system
```

**What gets installed automatically:**
- ⚡ Nivuus Shell configuration with 17 specialized modules
- 🤖 GitHub Copilot CLI integration (if available)
- 📦 Node.js LTS via NVM with auto-switching
- 🎨 Modern CLI tools (eza, bat, fd, ripgrep) with smart fallbacks
- 🔧 Vim with modern shortcuts and Nord theme
- 💾 Automatic backup of existing configurations

### Manual Installation Options

```bash
# Clone and install locally
git clone https://github.com/maximeallanic/nivuus-shell.git && cd nivuus-shell
./install.sh

# Non-interactive installation
./install.sh --non-interactive

# Health check existing installation
./install.sh --health-check

# Show all options
./install.sh --help
```

## 🤖 AI-Powered Commands

### GitHub Copilot Integration

**Instant command suggestions:**
```bash
?? "find large files"                    # Get shell command suggestions
?git "undo last commit"                  # Git-specific help
?gh "create a new repository"            # GitHub CLI assistance
```

**Command explanation:**
```bash
why "tar -xzf archive.tar.gz"           # Explain what a command does
explain "find . -name '*.js' -delete"   # Detailed explanation with examples
```

**Interactive AI assistant:**
```bash
ask "how to compress a folder"          # General command help
ai "convert video to mp4"               # Direct Copilot suggestion
aihelp                                  # Show all AI commands
```

### Smart Command Detection

The AI assistant automatically:
- 🎯 **Learns your patterns** - Suggests commands based on your workflow
- 🔍 **Context awareness** - Adapts suggestions to your current project
- ⚡ **Instant feedback** - Sub-second response times
- 🛡️ **Safety first** - Explains potentially dangerous commands

## 🎨 Vim Integration

### Modern Shortcuts & Features

**Copy/Paste (works everywhere):**
- `Ctrl+C` - Copy selection
- `Ctrl+X` - Cut selection  
- `Ctrl+V` - Paste
- `Ctrl+A` - Select all

**Smart Environment Detection:**
- 🏠 **Local usage** - Full mouse support with visual mode
- 🌐 **Remote/SSH** - Terminal-optimized with Shift+Click selection
- 💻 **VS Code** - Perfect integration with editor terminals
- 📱 **Web environments** - Optimized for vscode.dev, Codespaces

**Available Commands:**
```bash
vedit <file>                # Edit with modern config
vim.modern                  # Launch vim with full features
vim.ssh <file>              # SSH-optimized editing
vim_help                    # Show all vim commands
vim_install_system          # Install system-wide (sudo)
```

### Automatic Features

- **Nord color scheme** - Beautiful syntax highlighting
- **Line numbers** - Always visible for reference
- **Auto-detection** - Chooses optimal config for your environment
- **Clipboard integration** - Works with system clipboard
- **Performance optimized** - Fast startup and responsive editing

## 📦 Development Environment

### Node.js & NVM Integration

**Automatic Setup:**
- 🚀 **Auto-installation** - NVM installed during setup
- 🔄 **Smart switching** - Auto-detects `.nvmrc` files
- 💻 **VS Code ready** - Perfect integration with editor
- 📌 **LTS default** - Latest stable Node.js as default

**Available Commands:**
```bash
nvm-install                 # Install NVM (if needed)
nvm-update                  # Update to latest NVM
nvm-health                  # Check installation status
nvm use <version>           # Switch Node.js version
nvm install <version>       # Install specific version
```

**Automatic Behavior:**
- **Directory switching** - Auto-uses version from `.nvmrc`
- **VS Code integration** - Exports environment variables
- **Global tools** - Adds npm binaries to PATH
- **Project detection** - Shows suggestions for Node.js projects

### Project Intelligence

**Smart Project Detection:**
```bash
# Automatically detects and configures:
📦 Node.js projects        # package.json, yarn.lock detection
🐍 Python projects        # requirements.txt, pyproject.toml
🦀 Rust projects          # Cargo.toml detection  
🐹 Go projects            # go.mod detection
🐳 Docker projects        # Dockerfile detection
```

**Auto-suggestions per project type:**
- **Node.js**: `npm install`, `npm start`, `npm test`
- **Python**: `pip install -r requirements.txt`, `python main.py`
- **Rust**: `cargo build`, `cargo run`, `cargo test`
- **Go**: `go mod download`, `go run .`, `go test`

### VS Code Integration

**Seamless Terminal Experience:**
- 🔧 **Task integration** - Proper PATH and environment setup
- 📂 **Workspace awareness** - Auto-configures per project
- 🎯 **Node.js support** - Automatic version management
- ⚡ **Performance** - Optimized for integrated terminal

**Automatic Features:**
- Environment variable export for tasks
- Node.js version detection and switching  
- Development tool PATH configuration
- Shell integration for debugging

## 🔧 Advanced Features

### Performance & Diagnostics

**Health Monitoring:**
```bash
healthcheck                 # Complete system health analysis
benchmark                   # Performance benchmarking suite
zsh_info                    # Detailed configuration information
zsh_benchmark               # Startup time analysis
```

**What gets monitored:**
- ⚡ **Startup performance** - Target <300ms, alerts if slower
- 📝 **Completion system** - Cache health and rebuild detection
- 🔌 **Plugin status** - Syntax highlighting and autosuggestions
- 🛠️ **Modern tools** - Availability of eza, bat, fd, ripgrep
- 📊 **System metrics** - Memory, disk, and performance indicators

### Smart Maintenance

**Automatic Cleanup (runs weekly):**
- 🧽 **History optimization** - Removes duplicates while preserving order
- 🗂️ **Cache management** - Cleans temporary and cache files
- 🔄 **Completion rebuild** - Refreshes completion database
- 📦 **Package checking** - Monitors for available updates

**Manual Maintenance:**
```bash
cleanup                     # Manual system cleanup
smart_maintenance           # Force maintenance run
update_system               # Update packages and config
```

### Modern CLI Tools

**Enhanced Commands (with smart fallbacks):**
```bash
# File operations
ll                          # eza -la (beautiful file listing)
tree                        # eza --tree (directory tree)
cat file.txt                # bat (syntax highlighted)
find . -name "*.js"         # fd (faster alternative)
grep "pattern" files        # ripgrep (blazing fast search)

# Git shortcuts
gs                          # git status (enhanced)
gl                          # git log (beautiful graph)
ga                          # git add (interactive)
gd                          # git diff (syntax highlighted)
```

### Network & System Utilities

**Built-in Commands:**
```bash
myip                        # Show public IP address
localip                     # Show local IP addresses
ports                       # List open ports and processes
weather [city]              # Weather information
sysinfo                     # Comprehensive system info
analyze_size                # Directory size analysis
```

### Security & Environment

**Safe Environment Management:**
```bash
envcheck                    # Validate .env file security
envload                     # Silent environment loading
```

**Security Features:**
- 🛡️ **Input validation** - Sanitizes environment variables
- 🔒 **Root safety** - Special minimal mode for privileged access
- 📁 **Permission checks** - Validates file and directory permissions
- 🚫 **Unsafe command detection** - Warns about potentially dangerous operations

## 🏗️ Architecture

### Advanced Modular System

**17 Specialized Modules:**
```
shell/
├── install.sh                         # Unified installer with auto-detection
├── install/                           # Modular installation system
│   ├── common.sh                      # Shared utilities and functions
│   ├── packages.sh                    # Smart package management
│   ├── nvm.sh                         # Node.js/NVM automation
│   ├── backup.sh                      # Configuration backup/restore
│   ├── config.sh                      # Configuration management
│   ├── system.sh                      # System-wide operations
│   └── verification.sh                # Health checks and validation
├── config/                            # ZSH configuration modules
│   ├── 01-performance.zsh             # Ultra-fast startup optimizations
│   ├── 02-history.zsh                 # Advanced history management
│   ├── 03-completion.zsh              # Smart auto-completion system
│   ├── 04-keybindings.zsh             # Enhanced keyboard shortcuts
│   ├── 05-prompt.zsh                  # Async prompt with git status
│   ├── 06-aliases.zsh                 # Modern command aliases
│   ├── 07-functions.zsh               # 50+ utility functions
│   ├── 08-ai-integration.zsh          # GitHub Copilot CLI integration
│   ├── 09-syntax-highlighting.zsh     # Advanced code highlighting
│   ├── 10-environment.zsh             # Secure environment management
│   ├── 11-maintenance.zsh             # Automated system maintenance
│   ├── 12-diagnostics.zsh             # Health monitoring and benchmarks
│   ├── 13-vim-integration.zsh         # Modern Vim with clipboard support
│   ├── 14-subtle-colors.zsh           # Performance-optimized Nord theme
│   ├── 15-vscode-integration.zsh      # VS Code terminal integration
│   ├── 16-nvm-integration.zsh         # Node.js version management
│   └── 99-root-safe.zsh               # Secure root user configuration
└── docs/                              # Comprehensive documentation
```

**Architecture Benefits:**
- 🔧 **Maintainability** - Each module has single responsibility
- 🧪 **Testability** - Individual components tested independently
- ♻️ **Reusability** - Shared functions eliminate code duplication
- 📈 **Extensibility** - New features added as separate modules
- ⚡ **Performance** - Optimized loading order and lazy evaluation
- 🛡️ **Security** - Isolated module execution with validation

### Installation Modes

**Smart Auto-Detection:**
- 🏠 **Local mode** - Runs directly if modules are present
- 🌐 **Remote mode** - Auto-clones repository and re-executes
- 👥 **User mode** - `~/.config/nivuus-shell/` (default)
- 🏢 **System mode** - `/opt/nivuus-shell/` (all users)
- 🔒 **Root mode** - Minimal safe configuration for privileged access

## 🎯 System Deployment

### System-Wide Installation

**Enterprise-Ready Deployment:**
```bash
# Install for all users (requires sudo)
sudo ./install.sh --system
```

**Creates:**
- 📁 `/opt/nivuus-shell/` - Main configuration directory
- 🎨 `/etc/vim/vimrc.modern` - System-wide vim configuration  
- 🔧 `/etc/zsh/zshrc.d/` - ZSH integration files
- 🌐 `/etc/profile` - Shell-agnostic environment setup

**Benefits:**
- 👥 **All users** - Automatic access on next login
- 🔒 **Centralized** - Single configuration point
- 🛡️ **Secure** - Proper permissions and ownership
- 📊 **Consistent** - Same experience across user accounts

## 🛠️ Troubleshooting & Maintenance

### Common Issues & Solutions

**Performance Issues:**
```bash
# Profile startup time
benchmark                   # Complete performance analysis
zsh_benchmark               # Detailed startup metrics

# Fix slow startup
cleanup                     # Clean caches and temporary files
smart_maintenance           # Force maintenance cycle
```

**Environment Variables:**
```bash
# Security warnings for .env files
envcheck                    # Manual validation with details
envload                     # Silent loading (startup default)
```

**Root/Sudo Issues:**
```bash
# Fix "No such file or directory" with sudo su
./config/vscode-fix.sh      # Fix root configuration
sudo zsh -c 'echo "Test"'   # Verify root access
```

**Cache Problems:**
```bash
# Fix .zwc compilation errors
rm ~/.zcompdump*            # Remove completion cache
autoload -U compinit && compinit    # Rebuild completions
source ~/.zshrc             # Reload configuration
```

### Diagnostic Commands

**Health Monitoring:**
```bash
healthcheck                 # Complete system analysis
zsh_info                    # Configuration details
nvm-health                  # Node.js/NVM status
vim_help                    # Vim integration status
```

**Benchmarking:**
```bash
benchmark                   # Overall performance test
zsh_benchmark               # Startup time analysis (10 runs)
profile_zsh                 # Detailed profiling
```

## ❌ Uninstallation

### Quick Removal

**One-command uninstall:**
```bash
# Remove user installation
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/uninstall.sh | bash

# Remove system installation (requires sudo)
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/uninstall.sh | sudo bash
```

**Local uninstall:**
```bash
# If repository is already cloned
./uninstall.sh              # Remove user installation
sudo ./uninstall.sh         # Remove system installation
```

### What Gets Removed

**Configuration Files:**
- ✅ Nivuus Shell configuration
- ✅ ZSH plugins (syntax highlighting, autosuggestions)
- ✅ ZSH cache and compiled files
- ✅ Vim modern configurations
- ⚙️ Optional: System packages (eza, bat, fd-find, ripgrep)
- ⚙️ Optional: Reset default shell to bash

### What Gets Preserved

**Safe Backup System:**
- 💾 **Configuration backups** in `~/.config/nivuus-shell-backup`
- 📦 **System packages** (unless explicitly chosen for removal)
- 🔧 **Custom configurations** outside our scope
- 📁 **User data** and personal files

### Selective Removal

**Choose what to remove:**
- Interactive prompts for package removal
- Option to keep modern CLI tools
- Backup restoration options
- Shell preference reset choice

## 📚 Documentation & API

### Complete Documentation

- 📖 **[API.md](API.md)** - Complete function reference with 50+ utilities
- 🏗️ **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed technical architecture
- 📝 **[CHANGELOG.md](CHANGELOG.md)** - Version history and features
- 🔬 **[docs/](docs/)** - Additional guides and tutorials

### Key APIs

**System Functions:**
- `system_info()` - Comprehensive system information
- `cleanup_system()` - Smart system cleanup
- `update_system()` - System and config updates

**Development Functions:**
- `mkcd(dir)` - Create and navigate to directory
- `extract(archive)` - Intelligent archive extraction
- `detect_project()` - Auto-detect project type with suggestions

**Network Functions:**
- `myip()` - Public IP and network information
- `weather([city])` - Weather information
- `ports()` - List open ports and processes

**Performance Functions:**
- `benchmark_shell()` - Complete performance analysis
- `profile_zsh()` - Detailed configuration profiling

## 📄 License

**MIT License** - See [LICENSE](LICENSE) for full details.

---

### 🌟 Why Choose Nivuus Shell?

- ⚡ **Ultra-fast** - Sub-300ms startup with performance monitoring
- 🤖 **AI-powered** - GitHub Copilot integration for instant command help
- 🎨 **Beautiful** - Nord theme with subtle colors and modern design
- 🔧 **Complete** - Everything you need for modern development
- 🛡️ **Secure** - Safe environment handling and root protection
- 📚 **Documented** - Comprehensive guides and API reference
- 🏗️ **Modular** - Easy to customize and extend
- 🌐 **Universal** - Works everywhere (Linux, macOS, WSL, SSH, VS Code)

**Ready to supercharge your terminal experience?**

```bash
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | bash
```
