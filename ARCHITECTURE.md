# Cross-Platform In### 🚀 Auto-Detection
- **OS Detection**: Automatically identifies Linux distribution or macOS
- **Package Manager Detection**: Finds and validates available package manager
- **Local Mode**: If modules are present, runs directly
- **Remote Mode**: If modules missing, auto-clones repository and re-executes

### 📦 Cross-Platform Installation
```bash
# Works for all supported platforms
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | bash

# System-wide installation (all platforms)
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | sudo bash -s -- --system
```rchitecture

## Overview

The shell configuration now uses a **cross-platform unified installer** that automatically detects the operating system and package manager, then handles both local and remote installations seamlessly.

## Supported Platforms

### ✅ **Fully Supported**
- **Ubuntu/Debian** - `apt` package manager
- **macOS** - `brew` (Homebrew) package manager  
- **CentOS/RHEL/Fedora** - `dnf`/`yum` package managers
- **Alpine Linux** - `apk` package manager
- **Arch/Manjaro** - `pacman` package manager
- **openSUSE/SUSE** - `zypper` package manager
- **WSL2** - Auto-detects underlying distribution

## Key Features

### 🚀 Auto-Detection
- **Local Mode**: If modules are present, runs directly
- **Remote Mode**: If modules missing, auto-clones repository and re-executes

### 📦 Single Command Installation
```bash
# Works for both local and remote installation
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | bash

# System-wide installation
curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/master/install.sh | sudo bash -s -- --system
```

## Architecture

```
shell/
├── install.sh                 # Cross-platform unified installer (340+ lines)
│   ├── OS & package manager detection
│   ├── Auto-clone detection
│   ├── Remote download logic
│   └── Local module loading
├── install/                   # Modular components
│   ├── common.sh             # Cross-platform utilities & OS detection
│   ├── packages.sh           # Multi-platform package management
│   ├── nvm.sh                # Node.js/NVM setup
│   ├── backup.sh             # Backup operations
│   ├── config.sh             # Configuration setup
│   ├── system.sh             # System-wide operations
│   └── verification.sh       # Health checks
├── config/                   # ZSH configuration files
├── test-install.sh           # Simple testing script
└── uninstall.sh              # Removal script
```

## Installation Modes

### User Installation (Default)
```bash
./install.sh
```

### System-wide Installation
```bash
sudo ./install.sh --system
```

### Non-interactive Installation
```bash
./install.sh --non-interactive
```

### Health Check
```bash
./install.sh --health-check
```

## Remote Installation Flow

1. **Script downloaded** via curl (cross-platform compatible)
2. **OS & package manager detection** - Identifies system and tools
3. **Git installation** - Uses appropriate package manager if needed
4. **Auto-detection** checks for install/common.sh
5. **If missing**: Clone repository to /tmp/shell-install-$$
6. **Re-execute** from cloned directory with full platform support
7. **Normal installation** proceeds with detected package manager

## Package Manager Support

### Package Installation Matrix
| Tool | apt | dnf/yum | apk | pacman | zypper | brew |
|------|-----|---------|-----|--------|--------|------|
| zsh | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eza | ✅ | ✅ | ⚠️¹ | ✅ | ⚠️¹ | ✅ |
| bat | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| fd | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| ripgrep | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| GitHub CLI | ✅ | ✅ | ⚠️² | ✅ | ⚠️² | ✅ |

¹ *Fallback to GitHub releases*  
² *Skipped if unavailable*

## Remote Uninstallation Flow

1. **Uninstall script downloaded** via curl
2. **Auto-detection** checks for repository structure
3. **If remote execution**: Clone repository to /tmp/shell-uninstall-$$
4. **Re-execute** from cloned directory
5. **Normal uninstallation** proceeds with backup/restore

## Benefits

- ✅ **Cross-platform compatibility** - Works on Linux, macOS, WSL2
- ✅ **Multi-distro support** - Ubuntu, CentOS, Alpine, Arch, openSUSE, macOS
- ✅ **Smart package detection** - Auto-detects and uses appropriate package manager
- ✅ **Fallback strategies** - GitHub releases when packages unavailable
- ✅ **Single script** for all scenarios (install & uninstall)
- ✅ **No platform-specific installers** needed
- ✅ **Automatic repository cloning**
- ✅ **Maintains modular architecture**
- ✅ **Simplified maintenance**
- ✅ **Clean, minimal structure**

## Testing

```bash
./test-install.sh      # Test unified installer
./test-uninstall.sh    # Test remote uninstaller
```

This architecture provides maximum cross-platform compatibility while maintaining all the power and modularity of the original system. The installer automatically adapts to any supported platform without requiring user intervention.
