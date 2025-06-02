#!/bin/bash
# Fix ZSH Cache Issues
# ===================

echo "🔧 Fixing ZSH cache issues..."

# Clear Antigen cache
if [ -d "$HOME/.antigen" ]; then
    echo "📁 Clearing Antigen cache..."
    rm -rf "$HOME/.antigen"
    mkdir -p "$HOME/.antigen"
    chmod 755 "$HOME/.antigen"
fi

# Remove problematic .zwc files
echo "🗑️  Removing problematic .zwc files..."
sudo rm -f /etc/zsh/zshrc.zwc 2>/dev/null || true
rm -f "$HOME/.zshrc.zwc" 2>/dev/null || true

# Fix permissions for /opt/modern-shell
echo "🔐 Fixing permissions..."
if [ -d "/opt/modern-shell" ]; then
    sudo chmod -R 755 /opt/modern-shell
    sudo chown -R root:root /opt/modern-shell
fi

# Create proper zsh directories with correct permissions
sudo mkdir -p /etc/zsh/zshrc.d
sudo chmod 755 /etc/zsh/zshrc.d

echo "✅ Cache issues fixed!"
echo "🔄 Please restart your terminal or run: source ~/.zshrc"
