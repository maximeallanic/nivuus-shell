# Nivuus Shell - Feature List

Complete guide of what you can do with Nivuus Shell.

## Table of Contents

1. [AI-Powered Commands](#ai-powered-commands)
2. [Modern Text Editing](#modern-text-editing)
3. [Smart Navigation](#smart-navigation)
4. [Git Commands](#git-commands)
5. [Node.js Development](#nodejs-development)
6. [System Monitoring](#system-monitoring)
7. [File Management](#file-management)
8. [Network Tools](#network-tools)
9. [Configuration](#configuration)

---

## AI-Powered Commands

Get instant help and command suggestions powered by GitHub Copilot.

### Quick Help
```bash
??                      # Get command suggestions
?? "find large files"   # Ask for specific task
?git "undo commit"      # Git-specific help
?gh "create repo"       # GitHub CLI assistance
```

### Command Understanding
```bash
why "tar -xzf file"     # Explain what a command does
explain "complex cmd"   # Get detailed explanation
ask "compress folder"   # General command help
aihelp                  # Show all AI commands
```

---

## Modern Text Editing

Edit files with modern keyboard shortcuts that work everywhere.

### Vim Shortcuts
- **Ctrl+C** - Copy selection
- **Ctrl+X** - Cut selection
- **Ctrl+V** - Paste
- **Ctrl+A** - Select all

### Commands
```bash
vedit <file>            # Edit file with modern shortcuts
vim.modern              # Full-featured vim
vim.ssh <file>          # Optimized for SSH/remote
vim_help                # Show vim shortcuts
```

**Automatic detection** - Adapts to local, SSH, VS Code, and web environments.

---

## Smart Navigation

Navigate your terminal efficiently with intelligent shortcuts.

### History Search
Type any command prefix, then use **↑** or **↓** to cycle through matching commands.

**Examples:**
```bash
# Type 'git' then press ↑/↓ to see:
git status
git add .
git commit -m "..."
git push

# Type 'npm' then press ↑/↓ to see:
npm install
npm run dev
npm test
```

### Keyboard Shortcuts
- **↑ / ↓** - Navigate history with prefix filtering
- **Ctrl+P / Ctrl+N** - Alternative navigation
- **Ctrl+R** - Search full history
- **Ctrl+S** - Forward search

### Directory Shortcuts
```bash
..                      # Go up one directory
...                     # Go up two directories
....                    # Go up three directories
.....                   # Go up four directories

d                       # List recent directories
1                       # Jump to previous directory
2-5                     # Jump to directory in stack
```

---

## Git Commands

Fast shortcuts for common git operations.

### Basic Operations
```bash
gs                      # git status (short format)
ga                      # git add
gaa                     # git add --all
gc                      # git commit
gcm                     # git commit -m "message"
gp                      # git push
gpl                     # git pull
```

### Advanced Operations
```bash
gd                      # git diff
gds                     # git diff --staged
gb                      # git branch
gba                     # git branch -a (all branches)
gco                     # git checkout
gcb                     # git checkout -b (new branch)
gl                      # git log (beautiful graph, last 10)
gla                     # git log (all branches)
```

**Prompt integration** - See current branch and git status in your prompt.

---

## Node.js Development

Automatic Node.js version management with zero configuration.

### Auto-Switching
- **Detects `.nvmrc`** - Automatically switches to project's Node.js version
- **Returns to default** - When leaving project directory
- **Works in VS Code** - Seamless integration with editor

### Commands
```bash
nvm-install             # Install NVM
nvm-update              # Update NVM to latest
nvm-health              # Check NVM status
nvm use <version>       # Switch Node.js version
nvm install <version>   # Install specific version
```

### Project Detection
Automatically detects and suggests commands for:
- 📦 **Node.js** - Shows `npm install`, `npm start`, `npm test`
- 🐍 **Python** - Shows `pip install`, `python main.py`
- 🦀 **Rust** - Shows `cargo build`, `cargo run`
- 🐹 **Go** - Shows `go mod download`, `go run .`

---

## System Monitoring

Keep your system healthy and performant.

### Health Checks
```bash
healthcheck             # Complete system analysis
benchmark               # Performance benchmarking
zsh_info                # Configuration details
```

### Maintenance
```bash
cleanup                 # Clean temporary files and cache
update_system           # Update packages and config
```

**Automatic maintenance** runs weekly to:
- Remove duplicate history entries
- Clean cache and temporary files
- Refresh completion database

---

## File Management

Modern, faster alternatives to traditional file commands.

### File Listing
```bash
ll                      # Beautiful file list with icons
la                      # List all files (including hidden)
tree                    # Directory tree view
```

### File Search
```bash
f <pattern>             # Fast file search
fd <pattern>            # Find files by name
rg <pattern>            # Search file contents
```

### File Operations
```bash
mkcd <directory>        # Create and enter directory
extract <archive>       # Extract any archive format
backup <file>           # Create timestamped backup
size <path>             # Show directory sizes
```

**Supported archives:** `.tar`, `.tar.gz`, `.zip`, `.rar`, `.7z`, `.bz2`

---

## Network Tools

Quick access to network information and utilities.

### Commands
```bash
myip                    # Show your public IP address
localip                 # Show local network addresses
ports                   # List open ports and processes
weather [city]          # Get weather forecast
```

### Examples
```bash
myip                    # 203.0.113.42
weather Paris           # 5-day forecast for Paris
ports                   # All listening ports with processes
```

---

## Configuration

Manage your shell configuration easily.

### Edit Configuration
```bash
config_edit             # Edit main config
config_edit local       # Edit local customizations
config_edit functions   # Edit custom functions
config_edit aliases     # Edit custom aliases
```

### Backup & Restore
```bash
config_backup           # Create manual backup
config_restore          # Restore from backup
```

**Automatic backups** are created during installation to `~/.config/nivuus-shell-backup/`

### Performance Tuning

Adjust performance vs features:

```bash
# In your ~/.zshrc, add:
export ENABLE_SYNTAX_HIGHLIGHTING=false  # Faster startup
export ENABLE_PROJECT_DETECTION=true     # Show project suggestions
```

---

## Quick Command Reference

### AI & Help
- `??`, `?git`, `?gh` - Command suggestions
- `why`, `explain`, `ask` - Understand commands
- `aihelp` - Show AI features

### Text Editing
- `vedit <file>` - Edit with modern shortcuts
- `Ctrl+C/X/V/A` - Copy/Cut/Paste/Select all

### Navigation
- `↑/↓` - Smart history search
- `..`, `...`, `....` - Go up directories
- `d`, `1-5` - Jump to recent directories

### Git
- `gs`, `ga`, `gc`, `gp` - Status, Add, Commit, Push
- `gl`, `gd`, `gb` - Log, Diff, Branch

### Node.js
- Auto-switches versions with `.nvmrc`
- `nvm-health` - Check installation

### System
- `healthcheck` - System diagnostics
- `cleanup` - Clean cache and temp files
- `benchmark` - Performance test

### Files
- `ll`, `tree` - List files beautifully
- `f <pattern>`, `rg <pattern>` - Search files
- `mkcd`, `extract`, `backup` - File utilities

### Network
- `myip`, `localip`, `ports`, `weather`

### Config
- `config_edit` - Edit configuration
- `config_backup` - Create backup

---

## Installation Modes

### User Installation (Default)
```bash
curl -fsSL https://github.com/maximeallanic/nivuus-shell/releases/latest/download/install.sh | bash
```

Install for current user only.

### System-Wide Installation
```bash
curl -fsSL https://github.com/maximeallanic/nivuus-shell/releases/latest/download/install.sh | sudo bash -s -- --system
```

Install for all users on the system.

### Options
```bash
./install.sh --help              # Show all options
./install.sh --non-interactive   # Silent installation
./install.sh --health-check      # Check installation health
```

---

## What You Get

✅ **Sub-500ms startup** - Lightning-fast shell
✅ **AI command help** - GitHub Copilot integration
✅ **Modern vim** - Ctrl+C/V shortcuts everywhere
✅ **Smart history** - Type prefix then ↑/↓
✅ **Auto Node.js** - Version switching with `.nvmrc`
✅ **Beautiful files** - Modern `ls`, `cat`, `grep`
✅ **Git shortcuts** - Fast git operations
✅ **Auto-maintenance** - Weekly cleanup
✅ **Cross-platform** - Linux, macOS, WSL2

---

## Documentation

- **[README.md](README.md)** - Getting started guide
- **[API.md](API.md)** - Technical function reference
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

---

**License:** MIT
**Last Updated:** January 2025
