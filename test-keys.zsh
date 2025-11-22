#!/usr/bin/env zsh
# Test pour voir quel code Ctrl+Enter envoie dans votre terminal

echo "Test de détection de touches"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Appuyez sur Ctrl+Enter (SANS Enter après)"
echo "Puis Ctrl+C pour quitter"
echo ""
echo "Le code de la touche sera affiché en direct:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Use cat -v to see the exact key code
cat -v
