#!/bin/bash
# =============================================================================
# POST-INSTALLATION SETUP GUIDE
# =============================================================================

echo "🎉 Installation completed successfully!"
echo "======================================"
echo ""

# Check if NVM auto-install is configured
if [[ "$NVM_AUTO_INSTALL" == "true" ]] || [[ -f "$HOME/.nvm_auto_install" ]]; then
    echo "✅ NVM auto-install is ENABLED"
else
    echo "⚠️  NVM auto-install is DISABLED (recommended)"
    echo "   This prevents automatic Node.js installations"
    echo "   Run 'nvm-auto-install' to configure this setting"
fi

echo ""
echo "🔧 Next Steps:"
echo "=============="
echo ""

echo "1. 📦 Node.js Setup (choose one):"
echo "   a) Manual installation (recommended):"
echo "      nvm install --lts    # Install latest LTS"
echo "      nvm alias default lts/*"
echo ""
echo "   b) Auto-install setup:"
echo "      nvm-auto-install     # Configure auto-installation"
echo ""

echo "2. 🚀 Shell Restart:"
echo "   exec zsh              # Restart your shell"
echo "   # or simply open a new terminal"
echo ""

echo "3. 🧪 Verify Installation:"
echo "   nvm-health            # Check NVM status"
echo "   node --version        # Check Node.js"
echo "   npm --version         # Check npm"
echo ""

echo "4. 🔍 Troubleshooting:"
echo "   cat docs/TROUBLESHOOTING.md    # View troubleshooting guide"
echo "   ./install.sh --debug          # Debug installation"
echo ""

# Show environment-specific recommendations
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  ROOT USER DETECTED:"
    echo "   - Root-safe mode is automatically enabled"
    echo "   - Limited functionality to prevent security issues"
    echo "   - Use regular user account for development"
    echo ""
fi

if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    echo "🌐 SSH SESSION DETECTED:"
    echo "   - Remote session optimizations enabled"
    echo "   - Some features may be limited"
    echo ""
fi

if [[ "$container" == "docker" ]] || [[ -f "/.dockerenv" ]]; then
    echo "🐳 CONTAINER ENVIRONMENT DETECTED:"
    echo "   - Container-specific optimizations enabled"
    echo "   - Minimal mode may be activated"
    echo ""
fi

echo "💡 Useful Commands:"
echo "=================="
echo "   nvm-health           # System health check"
echo "   nvm-status           # Project status"
echo "   nvm-debug            # Debug information"
echo "   nvm-auto-install     # Configure auto-installation"
echo "   nvm-reload           # Reload NVM"
echo ""

echo "📚 Documentation:"
echo "================="
echo "   docs/TROUBLESHOOTING.md      # Problem solutions"
echo "   docs/INSTALLATION_DEBUG.md  # Debug guide"
echo "   API.md                       # API reference"
echo "   ARCHITECTURE.md              # System architecture"
echo ""

echo "✅ Your modern shell environment is ready!"
echo "   Happy coding! 🚀"
