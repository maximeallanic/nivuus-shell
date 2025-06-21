#!/bin/bash

# Script de test pour le système de debug
# Usage: ./debug-test.sh

echo "🧪 Test du système de debug de l'installateur"
echo "=============================================="

echo ""
echo "1. Test du mode debug:"
echo "./install.sh --debug --help"
echo ""

echo "2. Test de génération de rapport:"
echo "./install.sh --generate-report"
echo ""

echo "3. Test du mode verbose:"
echo "./install.sh --verbose --help"
echo ""

echo "4. Test d'une erreur avec debug:"
echo "./install.sh --debug --unknown-option"
echo ""

echo "5. Pour une installation réelle avec debug:"
echo "./install.sh --debug --non-interactive"
echo ""

echo "6. Pour générer un rapport après échec:"
echo "./install.sh --generate-report"
echo ""

echo "Les logs seront dans:"
echo "- ~/.cache/shell-install-*.log (mode utilisateur)"
echo "- /tmp/shell-install-*.log (mode system)"
echo ""

echo "💡 En cas de problème sur un autre système:"
echo "1. Lancer: curl -fsSL https://raw.githubusercontent.com/maximeallanic/nivuus-shell/main/install.sh | bash -s -- --debug"
echo "2. Ou: ./install.sh --generate-report"
echo "3. Envoyer le fichier *_debug_report.txt généré"
