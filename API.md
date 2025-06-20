# ZSH Ultra Performance - API Documentation

## Core Functions

### System Functions

#### `system_info()`

Displays comprehensive system information including OS, kernel, shell, and hardware details.

```bash
system_info
```

#### `cleanup_system()`

Performs system cleanup including package cache, logs, and temporary files.

```bash
cleanup_system
```

#### `update_system()`

Updates all system packages and ZSH configuration.

```bash
update_system
```

### Development Functions

#### `mkcd(directory)`

Creates a directory and navigates to it in one command.

```bash
mkcd my-project
```

#### `extract(archive)`

Intelligent archive extraction supporting multiple formats (zip, tar, gz, bz2, etc.).

```bash
extract archive.tar.gz
```

#### `backup(file/directory)`

Creates timestamped backups of files or directories.

```bash
backup important-file.txt
backup my-project/
```

### Network Functions

#### `myip()`

Shows public IP address and basic network information.

```bash
myip
```

#### `ports()`

Lists all open ports and associated processes.

```bash
ports
```

#### `weather([city])`

Displays weather information for current location or specified city.

```bash
weather
weather Paris
```

### Process Management

#### `pskill(process_name)`

Intelligent process killer with confirmation.

```bash
pskill firefox
```

#### `psgrep(pattern)`

Enhanced process search with highlighting.

```bash
psgrep node
```

### File Operations

#### `findf(pattern, [path])`

Fast file finder with smart filtering.

```bash
findf "*.js"
findf "config" /etc
```

#### `size(path)`

Shows directory sizes in human-readable format.

```bash
size .
size /var/log
```

### AI Integration

#### `ai(query)`

GitHub Copilot CLI integration for command suggestions.

```bash
ai "how to find large files"
```

#### `explain(command)`

Explains what a command does using AI.

```bash
explain "find . -name '*.log' -delete"
```

### Performance Functions

#### `benchmark_shell()`

Benchmarks shell startup time and performance.

```bash
benchmark_shell
```

#### `profile_zsh()`

Profiles ZSH configuration loading time.

```bash
profile_zsh
```

### Git Integration

#### Enhanced Git aliases:

- `gs` - git status with enhanced formatting
- `ga` - git add with interactive selection
- `gc` - git commit with templates
- `gp` - git push with safety checks
- `gl` - git log with beautiful formatting
- `gd` - git diff with syntax highlighting

### Prompt Features

#### Synchronous Git Status

Real-time git branch and status display with blocking execution for reliability.

#### Performance Monitoring

Shows command execution time for commands > 1 second.

#### Smart Directory Display

Intelligent path truncation and highlighting.

## Configuration Variables

### Performance Settings

- `ZSH_DISABLE_COMPFIX` - Disable completion security checks
- `HISTSIZE` - Command history size (50000)
- `SAVEHIST` - Saved history size (50000)

### AI Integration

- `GITHUB_COPILOT_CLI_PATH` - Path to GitHub Copilot CLI
- `OPENAI_API_KEY` - OpenAI API key for enhanced features

### Theme Settings

- `ZSH_THEME_PROMPT_COLOR` - Primary prompt color
- `ZSH_THEME_GIT_COLOR` - Git status color scheme

## Module Loading Order

1. **Performance** - Core optimizations
2. **History** - Command history configuration
3. **Completion** - Tab completion system
4. **Keybindings** - Keyboard shortcuts
5. **Prompt** - Synchronous prompt
6. **Aliases** - Command aliases
7. **Functions** - Utility functions
8. **AI Integration** - GitHub Copilot
9. **Syntax Highlighting** - Code coloring
10. **Environment** - Environment variables
11. **Maintenance** - Auto-maintenance
12. **Diagnostics** - Performance monitoring

## Troubleshooting

### Common Issues

#### Slow Startup

```bash
# Profile startup time
profile_zsh

# Benchmark performance
benchmark_shell
```

#### Missing Dependencies

```bash
# Run system check
./install.sh --check

# Install missing packages
sudo apt update && sudo apt install -y zsh git curl
```

#### Permission Issues

```bash
# Fix ownership
sudo chown -R $USER:$USER ~/.zsh-config

# Fix permissions
chmod +x ~/.zsh-config/install.sh
```

### Debug Mode

Enable debug mode for troubleshooting:

```bash
export ZSH_DEBUG=1
source ~/.zshrc
```

### Performance Tips

1. Avoid background processes for better reliability
2. Enable completion caching
3. Minimize synchronous operations in prompt  
4. Use manual processes for maintenance tasks
