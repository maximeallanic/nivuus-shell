# Unified Installation Architecture

## Overview

The shell configuration now uses a **single unified installer** that handles both local and remote installations automatically.

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
├── install.sh                 # Unified installer (316 lines)
│   ├── Auto-clone detection
│   ├── Remote download logic
│   └── Local module loading
├── install/                   # Modular components
│   ├── common.sh             # Shared utilities
│   ├── packages.sh           # Package management
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

1. **Script downloaded** via curl
2. **Auto-detection** checks for install/common.sh
3. **If missing**: Clone repository to /tmp/shell-install-$$
4. **Re-execute** from cloned directory
5. **Normal installation** proceeds with all modules

## Remote Uninstallation Flow

1. **Uninstall script downloaded** via curl
2. **Auto-detection** checks for repository structure
3. **If remote execution**: Clone repository to /tmp/shell-uninstall-$$
4. **Re-execute** from cloned directory
5. **Normal uninstallation** proceeds with backup/restore

## Benefits

- ✅ **Single script** for all scenarios (install & uninstall)
- ✅ **No separate remote installers** needed
- ✅ **Automatic repository cloning**
- ✅ **Maintains modular architecture**
- ✅ **Simplified maintenance**
- ✅ **Clean, minimal structure**
- ✅ **Both installation and uninstallation work remotely**

## Testing

```bash
./test-install.sh      # Test unified installer
./test-uninstall.sh    # Test remote uninstaller
```

This architecture provides maximum simplicity while maintaining all the power and modularity of the original system.
