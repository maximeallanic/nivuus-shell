#!/bin/bash
# Rapport complet shellcheck pour tous les fichiers shell du projet

set -euo pipefail

echo "🔍 Rapport Shellcheck - $(date)"
echo "================================"

total_files=0
clean_files=0
files_with_warnings=0
files_with_errors=0

# Fonction pour analyser un fichier
check_file() {
    local file="$1"
    local file_type="$2"
    
    echo ""
    echo "📁 $file ($file_type)"
    echo "----------------------------"
    
    ((total_files++))
    
    # Choisir les paramètres shellcheck selon le type
    local shellcheck_args="-x"
    if [[ "$file_type" == "bash" ]]; then
        shellcheck_args="$shellcheck_args -s bash"
    fi
    
    # Capturer la sortie shellcheck
    if output=$(shellcheck $shellcheck_args "$file" 2>&1); then
        echo "✅ Aucun problème détecté"
        ((clean_files++))
    else
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            echo "⚠️  Warnings/erreurs détectées :"
            echo "$output"
            
            # Compter les erreurs vs warnings
            if echo "$output" | grep -q "error"; then
                ((files_with_errors++))
            else
                ((files_with_warnings++))
            fi
        else
            echo "❌ Erreur d'analyse shellcheck (code $exit_code)"
            ((files_with_errors++))
        fi
    fi
}

# Analyse des scripts bash principaux
echo "🔧 SCRIPTS BASH PRINCIPAUX"
echo "=========================="
for file in install.sh uninstall.sh test-*.sh; do
    if [[ -f "$file" ]]; then
        check_file "$file" "bash"
    fi
done

# Analyse des scripts d'installation
echo ""
echo "📦 SCRIPTS D'INSTALLATION"
echo "========================="
for file in install/*.sh; do
    if [[ -f "$file" ]]; then
        check_file "$file" "bash"
    fi
done

# Analyse des scripts utilitaires
echo ""
echo "🛠️  SCRIPTS UTILITAIRES"
echo "======================"
for file in scripts/*.sh; do
    if [[ -f "$file" ]]; then
        check_file "$file" "bash"
    fi
done

# Analyse des fichiers de configuration zsh (avec bash pour shellcheck)
echo ""
echo "⚙️  FICHIERS DE CONFIGURATION ZSH"
echo "================================="
for file in config/*.zsh; do
    if [[ -f "$file" ]]; then
        check_file "$file" "zsh-as-bash"
    fi
done

# Analyse des scripts divers
echo ""
echo "📄 AUTRES SCRIPTS"
echo "================="
for file in config/*.sh; do
    if [[ -f "$file" ]]; then
        check_file "$file" "bash"
    fi
done

# Résumé final
echo ""
echo "📊 RÉSUMÉ FINAL"
echo "==============="
echo "Total fichiers analysés: $total_files"
echo "Fichiers sans problème: $clean_files"
echo "Fichiers avec warnings: $files_with_warnings"
echo "Fichiers avec erreurs: $files_with_errors"
echo ""

if [[ $files_with_errors -gt 0 ]]; then
    echo "❌ Des erreurs critiques ont été détectées !"
    exit 1
elif [[ $files_with_warnings -gt 0 ]]; then
    echo "⚠️  Des warnings ont été détectés mais pas d'erreurs critiques"
    exit 0
else
    echo "✅ Tous les fichiers sont conformes aux bonnes pratiques shellcheck !"
    exit 0
fi
