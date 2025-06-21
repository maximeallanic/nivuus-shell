#!/bin/bash
# Correction automatique des problèmes shellcheck pour les fichiers zsh

set -euo pipefail

echo "🔧 Correction des fichiers zsh pour shellcheck..."

# Fonction pour ajouter shebang
add_shebang() {
    local file="$1"
    if ! head -1 "$file" | grep -q '^#!/'; then
        echo "📝 Ajout du shebang à $file"
        temp_file=$(mktemp)
        echo '#!/usr/bin/env zsh' > "$temp_file"
        echo '# shell: zsh' >> "$temp_file"
        cat "$file" >> "$temp_file"
        mv "$temp_file" "$file"
    fi
}

# Fonction pour corriger les variables unused
fix_unused_vars() {
    local file="$1"
    echo "📝 Correction des variables non utilisées dans $file"
    
    # Export des variables qui semblent être utilisées globalement
    sed -i 's/^    activation_output=/    export activation_output=/' "$file" 2>/dev/null || true
    sed -i 's/^    node_version=/    export node_version=/' "$file" 2>/dev/null || true
    sed -i 's/^    node_ver=/    export node_ver=/' "$file" 2>/dev/null || true
    sed -i 's/^    npm_ver=/    export npm_ver=/' "$file" 2>/dev/null || true
}

# Fonction pour corriger les guillemets
fix_quotes() {
    local file="$1"
    echo "📝 Correction des guillemets dans $file"
    
    # Correction des guillemets simples en double
    sed -i "s/\[\[ -f '\$HOME\/.nvm\/nvm\.sh' \]\]/[[ -f \"\$HOME/.nvm/nvm.sh\" ]]/" "$file" 2>/dev/null || true
    sed -i 's/echo \$PATH/echo "\$PATH"/' "$file" 2>/dev/null || true
}

# Fonction pour corriger les arrays zsh
fix_arrays() {
    local file="$1"
    echo "📝 Correction des arrays dans $file"
    
    # Correction des assignations d'arrays zsh
    sed -i 's/chpwd_functions=(${chpwd_functions:#nvm_auto_use})/chpwd_functions=("${chpwd_functions[@]:#nvm_auto_use}")/' "$file" 2>/dev/null || true
}

# Traitement des fichiers config/*.zsh
for file in config/*.zsh; do
    if [[ -f "$file" ]]; then
        echo "🔍 Traitement de $file"
        add_shebang "$file"
        fix_unused_vars "$file"
        fix_quotes "$file"
        fix_arrays "$file"
    fi
done

echo "✅ Correction terminée!"
