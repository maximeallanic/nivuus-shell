# Nivuus Shell

> A modern, fast, AI-powered ZSH shell with Nord theme and intelligent features

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-ZSH-green.svg)
![Performance](https://img.shields.io/badge/startup-<300ms-brightgreen.svg)

## ✨ Features

- ⚡ **Lightning Fast** - Sub-300ms startup time
- 🎨 **Nord Theme** - Beautiful, consistent color scheme
- 🤖 **AI-Powered** - Command suggestions via gemini-cli
- 📝 **Modern Vim** - Ctrl+C/V/X/A shortcuts
- 🔍 **Smart Navigation** - History prefix search with ↑/↓
- 📦 **Auto Node.js** - Version switching with .nvmrc
- 🌿 **Git Integration** - Fast shortcuts + beautiful prompt
- 🛠️ **Zero Config** - Works out of the box

## 🚀 Quick Start

### One-Line Installation

Install Nivuus Shell with a single command:

```bash
git clone https://github.com/maximeallanic/nivuus-shell.git /tmp/nivuus-shell && /tmp/nivuus-shell/install.sh --non-interactive && rm -rf /tmp/nivuus-shell && exec zsh
```

This will:
1. Clone the repository to `/tmp/nivuus-shell`
2. Run the installation automatically (no prompts)
3. Clean up the temporary directory
4. Restart your shell with Nivuus

### Manual Installation

#### User Installation (Recommended)
```bash
git clone https://github.com/maximeallanic/nivuus-shell.git
cd nivuus-shell
./install.sh
```

#### System-Wide Installation
```bash
git clone https://github.com/maximeallanic/nivuus-shell.git
cd nivuus-shell
sudo ./install.sh --system
```

### Restart Your Terminal

```bash
exec zsh
# or just restart your terminal
```

## 📖 Usage

### AI Commands

Get intelligent command suggestions powered by Gemini:

```bash
??                      # Get command suggestions
?? "find large files"   # Ask for specific task
?git "undo commit"      # Git-specific help
why "tar -xzf file"     # Explain a command
explain "complex cmd"   # Detailed explanation
ask "how to compress"   # General question
aihelp                  # Show all AI commands
```

**Setup AI:**
1. Get API key from: https://makersuite.google.com/app/apikey
2. Add to `~/.zsh_local`:
   ```bash
   export GEMINI_API_KEY='your-api-key'
   ```

### Modern Vim Editing

Edit files with familiar keyboard shortcuts:

```bash
vedit myfile.txt        # Edit with auto environment detection
vim.modern myfile.txt   # Full-featured local vim
vim.ssh myfile.txt      # Optimized for SSH
vim_help                # Show all shortcuts
```

**Shortcuts in Vim:**
- **Ctrl+C** - Copy
- **Ctrl+X** - Cut
- **Ctrl+V** - Paste
- **Ctrl+A** - Select all
- **Ctrl+S** - Save
- **Ctrl+Z** - Undo

### Smart Navigation

Type a command prefix, then press ↑ or ↓ to search history:

```bash
# Type 'git' then press ↑/↓ to cycle through:
git status
git add .
git commit -m "..."
git push
```

**Directory shortcuts:**
```bash
..                      # Go up one directory
...                     # Go up two directories
....                    # Go up three directories
d                       # List recent directories
1-5                     # Jump to directory in stack
```

### Git Shortcuts

```bash
gs                      # git status
ga                      # git add
gc                      # git commit
gp                      # git push
gl                      # git log (beautiful)
gd                      # git diff
gb                      # git branch
gco                     # git checkout
```

### Node.js Auto-Switching

Nivuus automatically switches Node.js versions when you enter a directory with `.nvmrc`:

```bash
# Just cd into a project
cd my-project           # Automatically loads correct Node.js version

# NVM utilities
nvm-install             # Install NVM
nvm-health              # Check NVM status
```

### File Management

```bash
ll                      # Beautiful file list
tree                    # Directory tree
f <pattern>             # Fast file search
search <pattern>        # Search file contents
mkcd mydir              # Create and enter directory
extract archive.tar.gz  # Extract any archive
backup myfile           # Create timestamped backup
```

### Network Tools

```bash
myip                    # Show public IP
localip                 # Show local IPs
ports                   # List open ports
weather Paris           # Get weather forecast
```

### System Monitoring

```bash
healthcheck             # Complete system diagnostics
benchmark               # Performance testing
cleanup                 # Clean cache and temp files
zsh_info                # Show shell configuration
```

## 🎨 Nord Theme

Nivuus uses the beautiful [Nord color scheme](https://www.nordtheme.com/) throughout:

### Prompt Format

```
[hostname] > ~/path [firebase-project] git:(branch)x
```

- **Green `>`** - Last command succeeded
- **Red `>`** - Last command failed
- **[hostname]** - Shows in SSH sessions
- **`x`** - Indicates uncommitted changes
- **Cyan path** - Current directory
- **Yellow [project]** - Active Firebase project
- **Git info** - Current branch with status

### Customization

Edit `~/.zsh_local` to customize:

```bash
# Performance tuning
export GIT_PROMPT_CACHE_TTL=5          # Git cache (default: 2s)
export ENABLE_FIREBASE_PROMPT=false    # Disable Firebase info
export ENABLE_PROJECT_DETECTION=false  # Disable project detection

# AI configuration
export GEMINI_API_KEY='your-key'
export GEMINI_MODEL='gemini-2.5-flash-lite'
```

## 📊 Performance

Nivuus is optimized for speed:

- **Target:** <300ms startup time
- **Lazy loading** for NVM and heavy features
- **Git caching** with 2s TTL
- **Compiled ZSH files** for faster loading
- **No external plugins** - pure ZSH

### Benchmark Your Shell

```bash
benchmark               # Run performance tests
```

## 🛠️ Configuration

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

Automatic backups are created at:
- During installation: `~/.config/nivuus-shell-backup/`
- Auto-maintenance: Weekly cleanup

## 🔄 Updating

Nivuus Shell includes an automatic update system that checks for updates weekly and installs them automatically.

### Automatic Updates

- **Weekly checks** - Checks for updates every 7 days
- **Automatic installation** - Updates are installed automatically with backup
- **Safe rollback** - Previous versions backed up to `~/.config/nivuus-shell-backup/`

### Manual Update

```bash
nivuus-update               # Check for and install updates manually
```

### Configuration

Customize auto-update behavior in `~/.zsh_local`:

```bash
# Disable auto-updates
export ENABLE_AUTOUPDATE=false

# Change check frequency (days)
export AUTOUPDATE_CHECK_FREQUENCY_DAYS=14

# Change remote repository
export NIVUUS_REMOTE_REPO=git@github.com:yourfork/nivuus-shell.git

# Change branch
export NIVUUS_BRANCH=master
```

### Rollback

If an update causes issues, restore from the timestamped backup:

```bash
# List backups
ls ~/.config/nivuus-shell-backup/

# Restore from backup
cp -r ~/.config/nivuus-shell-backup/pre-update-YYYYMMDD-HHMMSS/nivuus-shell ~/.nivuus-shell
exec zsh
```

## 🔧 Development

Test changes without installing:

```bash
git clone https://github.com/maximeallanic/nivuus-shell.git
cd nivuus-shell
./dev.sh
```

This launches a dev shell with:
- No file copying (uses repo directly)
- No compilation (instant reload)
- All changes take effect immediately

Edit any file, then restart the shell to see changes:
```bash
exec zsh
```

## 📁 Project Structure

```
nivuus-shell/
├── .zshrc                  # Main entry point
├── .vimrc.nord             # Vim configuration with Nord theme
├── install.sh              # Installation script
├── config/                 # Modular configuration
│   ├── 00-core.zsh        # Core ZSH settings
│   ├── 05-prompt.zsh      # Nord prompt
│   ├── 06-git.zsh         # Git aliases
│   ├── 07-navigation.zsh  # Smart navigation
│   ├── 08-vim.zsh         # Vim integration
│   ├── 09-nodejs.zsh      # Node.js/NVM
│   ├── 10-ai.zsh          # AI commands
│   ├── 20-autoupdate.zsh  # Auto-update system
│   └── ...                # Other modules
├── themes/
│   └── nord.zsh           # Nord color palette
├── bin/
│   ├── healthcheck        # System diagnostics
│   └── benchmark          # Performance testing
├── FEATURES.md            # Complete feature list
├── PROMPT.md              # Prompt documentation
└── README.md              # This file
```

## 🔧 Requirements

### Required
- **ZSH** 5.0+
- **Git** 2.0+
- **Curl** 7.0+

### Optional
- **gemini-cli** - For AI commands (`npm install -g gemini-cli`)
- **NVM** - For Node.js version management
- **fd** - Fast file search (`cargo install fd-find`)
- **ripgrep** - Fast content search (`cargo install ripgrep`)
- **bat** - Better cat (`cargo install bat`)
- **eza** - Modern ls (`cargo install eza`)

## 📚 Documentation

- **[FEATURES.md](FEATURES.md)** - Complete feature guide
- **[PROMPT.md](PROMPT.md)** - Prompt configuration details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Credits

- **Nord Theme** - [Arctic Ice Studio](https://www.nordtheme.com/)
- **Gemini AI** - [Google](https://ai.google.dev/)

## 🐛 Troubleshooting

### Shell loads slowly

```bash
# Disable features in ~/.zsh_local
export ENABLE_SYNTAX_HIGHLIGHTING=false
export ENABLE_PROJECT_DETECTION=false
export GIT_PROMPT_CACHE_TTL=5
```

### AI commands not working

```bash
# Install gemini-cli
npm install -g gemini-cli

# Add API key to ~/.zsh_local
export GEMINI_API_KEY='your-key'
```

### Git prompt not showing

```bash
# Check if in git repository
git status

# Increase cache if needed
export GIT_PROMPT_CACHE_TTL=5
```

### Vim shortcuts not working

```bash
# Check clipboard support
vim --version | grep clipboard

# Use fallback if needed
vim.ssh myfile  # Uses internal clipboard
```

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/maximeallanic/nivuus-shell/issues)
- **Discussions**: [GitHub Discussions](https://github.com/maximeallanic/nivuus-shell/discussions)

---

**Made with ❄️ and the Nord theme**

