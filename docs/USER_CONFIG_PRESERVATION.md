# Préservation des Configurations Utilisateur

## Vue d'ensemble

Le système d'installation et de mise à jour a été amélioré pour **préserver automatiquement les configurations personnelles** lors des installations et des mises à jour. Cela inclut notamment les imports de gcloud, NVM, pyenv, et autres outils de développement.

## Fonctionnalités

### 🔒 Configurations Préservées Automatiquement

- **Google Cloud SDK**: `source google-cloud-sdk`, exports `GCLOUD_*`, aliases gcloud
- **Node Version Manager**: `NVM_DIR`, chargement de nvm.sh et bash_completion  
- **Python Environment**: pyenv, conda, anaconda, miniconda
- **Ruby Environment**: rbenv
- **Java**: `JAVA_HOME`, `ANDROID_*`, `FLUTTER_*`, `DART_*`
- **Profiles**: `.bashrc`, `.profile`, `.bash_profile`
- **Aliases personnalisés**: ll, la, grep, etc.
- **Toute configuration dans la section PRESERVED USER CONFIGURATIONS**

### 🚀 Installation Intelligente

```bash
# Installation normale - préserve automatiquement les configs
./install.sh

# Installation système - préserve pour tous les utilisateurs
sudo ./install.sh --system
```

**Processus:**
1. Backup automatique du `.zshrc` existant
2. Extraction des configurations personnelles
3. Installation de la nouvelle configuration
4. Restauration des configurations personnelles dans une section dédiée

### 🔄 Mise à jour Intelligente

```bash
# Mise à jour avec préservation automatique
zsh_update

# Vérification des mises à jour disponibles
zsh_manual_update

# Script de mise à jour autonome
./scripts/update.sh
```

**Processus:**
1. Backup complet avant mise à jour
2. Extraction des configurations utilisateur
3. Mise à jour des fichiers de configuration
4. Régénération du `.zshrc` avec configurations préservées
5. Validation et rapport de mise à jour

### 📁 Structure des Backups

```
~/.config/zsh-ultra-backup/           # Backup initial installation
└── zshrc.backup
└── user_configs.zsh                 # Configurations extraites

~/.config/zsh-update-backup-YYYYMMDD_HHMMSS/  # Backup mise à jour
├── zshrc.backup                     # .zshrc avant mise à jour
├── user_configs.zsh                 # Configurations extraites
└── zsh_local.backup                 # .zsh_local si existant
```

### 🎯 Exemple de .zshrc Généré

```bash
# Modern ZSH Configuration (Updated: Sat Jun  7 10:30:00 2025)
# Configuration directory
export ZSH_CONFIG_DIR="/home/user/.config/zsh-ultra"

# Load all configuration modules
if [[ -d "$ZSH_CONFIG_DIR/config" ]]; then
    for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
        [[ -r "$config_file" ]] && source "$config_file"
    done
fi

# Load local customizations if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# =============================================================================
# PRESERVED USER CONFIGURATIONS
# =============================================================================

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/user/google-cloud-sdk/path.zsh.inc' ]; then . '/home/user/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/user/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/user/google-cloud-sdk/completion.zsh.inc'; fi

export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
```

## Commandes Disponibles

### Mise à jour
- `zsh_update` - Mise à jour intelligente avec préservation
- `zsh_manual_update` - Contrôle manuel des mises à jour
- `./scripts/update.sh update` - Script autonome de mise à jour

### Vérification
- `./scripts/update.sh check` - Vérifier les mises à jour disponibles
- `./scripts/update.sh status` - Statut de la configuration actuelle
- `healthcheck` - Diagnostic complet du système

### Maintenance
- `zsh_cleanup` - Nettoyage des fichiers temporaires
- `backup_restore` - Restauration depuis backup

## Compatibilité

✅ **Systèmes supportés:**
- Ubuntu/Debian
- Installation utilisateur et système
- Mises à jour depuis anciennes versions

✅ **Configurations préservées:**
- Environnements de développement (Node.js, Python, Java, etc.)
- Cloud SDK (Google Cloud, AWS CLI, etc.)
- Aliases et fonctions personnalisées
- Variables d'environnement spécifiques

## Sécurité

- **Validation automatique** des configurations extraites
- **Backups multiples** à chaque étape
- **Rollback possible** via les backups horodatés
- **Préservation des permissions** pour les installations système

## Dépannage

### Restaurer une configuration précédente
```bash
# Lister les backups disponibles
ls ~/.config/zsh-*backup*/

# Restaurer manuellement
cp ~/.config/zsh-ultra-backup/zshrc.backup ~/.zshrc
source ~/.zshrc
```

### Forcer une extraction manuelle
```bash
./install/backup.sh extract_user_configs ~/.zshrc output.zsh
```

### Désactiver la préservation temporairement
```bash
export SKIP_USER_CONFIG_PRESERVATION=true
./install.sh
```

Cette amélioration garantit que vos configurations personnelles importantes (comme gcloud) sont toujours préservées lors des installations et mises à jour du shell.
