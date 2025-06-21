#!/bin/bash
# =============================================================================
# NVM AUTO-INSTALL CONFIGURATION SCRIPT
# =============================================================================

echo "🔧 NVM Auto-Install Configuration"
echo "================================="
echo ""

# Check current status
if [[ "$NVM_AUTO_INSTALL" == "true" ]] || [[ -f "$HOME/.nvm_auto_install" ]]; then
    echo "✅ Auto-install is currently ENABLED"
    echo "   Node.js versions will be installed automatically when needed"
    echo ""
    echo "To disable auto-install:"
    echo "   1. Run: unset NVM_AUTO_INSTALL"
    echo "   2. Remove: rm -f ~/.nvm_auto_install"
    echo "   3. Restart your shell"
else
    echo "❌ Auto-install is currently DISABLED"
    echo "   You need to manually install Node.js versions"
    echo ""
    echo "To enable auto-install:"
    echo "   Choose one of the following options:"
    echo ""
    echo "   Option 1 - Permanent (recommended):"
    echo "     touch ~/.nvm_auto_install"
    echo ""
    echo "   Option 2 - Session only:"
    echo "     export NVM_AUTO_INSTALL=true"
    echo ""
    echo "   Option 3 - Add to shell profile:"
    echo "     echo 'export NVM_AUTO_INSTALL=true' >> ~/.zshrc"
fi

echo ""
echo "💡 Manual installation commands:"
echo "   nvm install --lts    # Install latest LTS version"
echo "   nvm install 18       # Install specific major version"
echo "   nvm use 18           # Switch to specific version"
echo "   nvm alias default 18 # Set default version"
echo ""

# Offer to enable/disable interactively
read -p "Would you like to change the auto-install setting? (y/N): " response
case $response in
    [Yy]*)
        if [[ "$NVM_AUTO_INSTALL" == "true" ]] || [[ -f "$HOME/.nvm_auto_install" ]]; then
            # Currently enabled, offer to disable
            echo ""
            echo "Auto-install is currently enabled. Choose how to disable it:"
            echo "1. Disable for this session only"
            echo "2. Disable permanently"
            echo "3. Cancel"
            echo ""
            read -p "Choose option (1-3): " disable_option
            case $disable_option in
                1)
                    unset NVM_AUTO_INSTALL
                    echo "✅ Auto-install disabled for this session"
                    ;;
                2)
                    unset NVM_AUTO_INSTALL
                    rm -f "$HOME/.nvm_auto_install"
                    echo "✅ Auto-install disabled permanently"
                    echo "   (restart your shell to take effect)"
                    ;;
                3)
                    echo "❌ Cancelled"
                    ;;
                *)
                    echo "❌ Invalid option"
                    ;;
            esac
        else
            # Currently disabled, offer to enable
            echo ""
            echo "Auto-install is currently disabled. Choose how to enable it:"
            echo "1. Enable for this session only"
            echo "2. Enable permanently"
            echo "3. Cancel"
            echo ""
            read -p "Choose option (1-3): " enable_option
            case $enable_option in
                1)
                    export NVM_AUTO_INSTALL=true
                    echo "✅ Auto-install enabled for this session"
                    ;;
                2)
                    touch "$HOME/.nvm_auto_install"
                    export NVM_AUTO_INSTALL=true
                    echo "✅ Auto-install enabled permanently"
                    echo "   (will be active in new shell sessions)"
                    ;;
                3)
                    echo "❌ Cancelled"
                    ;;
                *)
                    echo "❌ Invalid option"
                    ;;
            esac
        fi
        ;;
    *)
        echo "❌ No changes made"
        ;;
esac

echo ""
echo "✅ Configuration complete!"
