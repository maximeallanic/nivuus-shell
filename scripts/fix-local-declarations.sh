#!/bin/bash
# Correction spécifique des déclarations locales avec assignation

set -euo pipefail

file="config/16-nvm-integration.zsh"

echo "🔧 Correction des déclarations locales dans $file"

# Créer un fichier temporaire pour les corrections
temp_file=$(mktemp)

# Fonction pour séparer déclaration et assignation
fix_local_assignment() {
    local line="$1"
    
    # Extraire le nom de variable et l'assignation
    if [[ "$line" =~ ^([[:space:]]*)local[[:space:]]+([^=]+)=\"(.*)\"[[:space:]]*$ ]]; then
        local indent="${BASH_REMATCH[1]}"
        local varname="${BASH_REMATCH[2]}"
        local assignment="${BASH_REMATCH[3]}"
        
        echo "${indent}local ${varname}"
        echo "${indent}${varname}=\"${assignment}\""
    elif [[ "$line" =~ ^([[:space:]]*)local[[:space:]]+([^=]+)=\$\((.+)\)[[:space:]]*$ ]]; then
        local indent="${BASH_REMATCH[1]}"
        local varname="${BASH_REMATCH[2]}"
        local assignment="${BASH_REMATCH[3]}"
        
        echo "${indent}local ${varname}"
        echo "${indent}${varname}=\"\$(${assignment})\""
    else
        echo "$line"
    fi
}

# Lire ligne par ligne et corriger
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*local[[:space:]]+[^=]+=.* ]]; then
        fix_local_assignment "$line"
    else
        echo "$line"
    fi
done < "$file" > "$temp_file"

# Remplacer le fichier original
mv "$temp_file" "$file"

echo "✅ Corrections appliquées à $file"
