#!/bin/bash
# Environment Diagnostic Tool
# Aide à diagnostiquer les problèmes d'environnement shell

set -eo pipefail  # Removed 'u' to handle undefined variables gracefully

echo "🔍 DIAGNOSTIC ENVIRONNEMENT SHELL"
echo "=================================="
echo "Date: $(date)"
echo ""

# Informations système de base
echo "📋 INFORMATIONS SYSTÈME"
echo "------------------------"
echo "OS: $(uname -s) $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Distribution: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'Unknown')"
echo "Shell: $SHELL ($$)"
echo "Terminal: ${TERM:-unknown}"
echo ""

# Informations utilisateur
echo "👤 INFORMATIONS UTILISATEUR"
echo "----------------------------"
echo "Utilisateur actuel: $(whoami 2>/dev/null || echo 'whoami failed')"
echo "UID: ${UID:-unset}"
echo "EUID: ${EUID:-unset}"
echo "USER: ${USER:-unset}"
echo "HOME: ${HOME:-unset}"
echo "PWD: ${PWD:-unset}"
echo ""

# Informations sudo/root
echo "🔐 INFORMATIONS ROOT/SUDO"
echo "-------------------------"
echo "SUDO_USER: ${SUDO_USER:-unset}"
echo "SUDO_UID: ${SUDO_UID:-unset}"
echo "SUDO_GID: ${SUDO_GID:-unset}"
echo "Commande sudo disponible: $(command -v sudo >/dev/null && echo 'oui' || echo 'non')"
echo "Commande su disponible: $(command -v su >/dev/null && echo 'oui' || echo 'non')"
echo ""

# Test sudo/su
echo "🧪 TEST SUDO/SU"
echo "---------------"
if command -v sudo >/dev/null; then
    echo "sudo --version: $(sudo --version 2>/dev/null | head -1 || echo 'échec')"
    echo "sudo -n true: $(sudo -n true 2>/dev/null && echo 'OK' || echo 'échec (normal si pas de sudo sans mot de passe)')"
else
    echo "sudo: command not found"
fi

if command -v su >/dev/null; then
    echo "su --version: $(su --version 2>/dev/null | head -1 || echo 'échec/pas de --version')"
    echo "su -c 'echo test': $(echo | su -c 'echo test' 2>/dev/null || echo 'échec (normal sans mot de passe root)')"
else
    echo "su: command not found"
fi
echo ""

# Informations locales
echo "🌍 INFORMATIONS LOCALES"
echo "-----------------------"
echo "LANG: ${LANG:-unset}"
echo "LC_ALL: ${LC_ALL:-unset}"
echo "LC_CTYPE: ${LC_CTYPE:-unset}"
echo "Locales disponibles (5 premières):"
if command -v locale >/dev/null; then
    locale -a 2>/dev/null | head -5 || echo "  locale -a failed"
    echo ""
    echo "Locale actuelle:"
    locale 2>/dev/null || echo "  locale command failed"
else
    echo "  commande locale non disponible"
fi
echo ""

# PATH et commandes
echo "🛤️  PATH ET COMMANDES"
echo "--------------------"
echo "PATH: $PATH"
echo ""
echo "Commandes essentielles:"
for cmd in bash zsh git curl wget; do
    echo "  $cmd: $(command -v $cmd 2>/dev/null || echo 'non trouvé')"
done
echo ""

# Permissions et accès
echo "🔒 PERMISSIONS"
echo "--------------"
echo "Permissions HOME: $(ls -ld "$HOME" 2>/dev/null || echo 'HOME inaccessible')"
echo "Écriture dans HOME: $(touch "$HOME/.test_write" 2>/dev/null && rm "$HOME/.test_write" && echo 'OK' || echo 'échec')"
echo "Lecture /etc/passwd: $(head -1 /etc/passwd 2>/dev/null >/dev/null && echo 'OK' || echo 'échec')"
echo "Lecture /etc/os-release: $(cat /etc/os-release 2>/dev/null >/dev/null && echo 'OK' || echo 'échec')"
echo ""

# Variables d'environnement shell
echo "⚙️  ENVIRONNEMENT SHELL NIVUUS"
echo "------------------------------"
echo "MINIMAL_MODE: ${MINIMAL_MODE:-unset}"
echo "FORCE_ROOT_SAFE: ${FORCE_ROOT_SAFE:-unset}"
echo "DEBUG_MODE: ${DEBUG_MODE:-unset}"
echo "SKIP_GLOBAL_CONFIG: ${SKIP_GLOBAL_CONFIG:-unset}"
echo "ANTIGEN_DISABLE: ${ANTIGEN_DISABLE:-unset}"
echo ""

# Test de détection root-safe
echo "🛡️  TEST DÉTECTION ROOT-SAFE"
echo "----------------------------"
if [[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]] || [[ "$(whoami 2>/dev/null)" == "root" ]] || [[ "$USER" == "root" ]] || [[ "$HOME" == "/root" ]] || \
   [[ -n "$SUDO_USER" ]] || [[ -n "$SUDO_UID" ]] || \
   [[ "$LANG" == "C" && -z "$DISPLAY" && ! -w "$HOME" ]] || \
   [[ "$PATH" == "/usr/bin:/bin" ]] || \
   [[ "$FORCE_ROOT_SAFE" == "1" ]] || [[ "$MINIMAL_MODE" == "1" ]]; then
    echo "✅ Root-safe serait ACTIVÉ"
    echo "Raisons:"
    [[ $EUID -eq 0 ]] && echo "  - EUID=0"
    [[ $UID -eq 0 ]] && echo "  - UID=0"
    [[ "$(whoami 2>/dev/null)" == "root" ]] && echo "  - whoami=root"
    [[ "$USER" == "root" ]] && echo "  - USER=root"
    [[ "$HOME" == "/root" ]] && echo "  - HOME=/root"
    [[ -n "$SUDO_USER" ]] && echo "  - SUDO_USER défini"
    [[ -n "$SUDO_UID" ]] && echo "  - SUDO_UID défini"
    [[ "$LANG" == "C" && -z "$DISPLAY" && ! -w "$HOME" ]] && echo "  - Environnement restreint détecté"
    [[ "$PATH" == "/usr/bin:/bin" ]] && echo "  - PATH minimal détecté"
    [[ "$FORCE_ROOT_SAFE" == "1" ]] && echo "  - FORCE_ROOT_SAFE=1"
    [[ "$MINIMAL_MODE" == "1" ]] && echo "  - MINIMAL_MODE=1"
else
    echo "❌ Root-safe serait DÉSACTIVÉ"
fi
echo ""

# Recommandations
echo "💡 RECOMMANDATIONS"
echo "-------------------"
if [[ "$LANG" == "C" ]] || [[ -z "$LANG" ]]; then
    echo "⚠️  Problème de locale détecté. Essayez:"
    echo "   export LANG=C.UTF-8"
    echo "   export LC_ALL=C.UTF-8"
fi

if ! command -v sudo >/dev/null && ! command -v su >/dev/null; then
    echo "⚠️  Ni sudo ni su disponible. Installation en mode utilisateur recommandée."
fi

if [[ ! -w "$HOME" ]]; then
    echo "⚠️  HOME non accessible en écriture. Vérifiez les permissions."
fi

echo ""
echo "✅ Diagnostic terminé. Partagez cette sortie pour obtenir de l'aide."
