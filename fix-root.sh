#!/bin/bash
# Fix Root/Sudo Issues
# ===================

echo "🔧 Fixing root/sudo access issues..."

# Fix locale for root
echo "1️⃣  Setting up root locale..."
sudo locale-gen en_US.UTF-8 2>/dev/null || true
sudo update-locale LANG=en_US.UTF-8 2>/dev/null || true

# Ensure root has proper shell
echo "2️⃣  Configuring root shell..."
sudo chsh -s /bin/zsh root 2>/dev/null || echo "   ⚠️  Could not set zsh for root (normal on some systems)"

# Create minimal root zshrc
echo "3️⃣  Creating minimal root configuration..."
sudo tee /root/.zshrc > /dev/null << 'EOF'
# Minimal root zshrc
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Simple prompt
PROMPT='[root] %~ # '

# Basic aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
EOF

# Fix permissions
sudo chmod 644 /root/.zshrc

# Test root shell
echo "4️⃣  Testing root shell..."
if sudo zsh -c 'echo "Root shell works"' >/dev/null 2>&1; then
    echo "   ✅ Root shell configured successfully"
else
    echo "   ⚠️  Root shell may need manual configuration"
fi

echo ""
echo "✅ Root issues fixed!"
echo "🔄 Try 'sudo su' again"
