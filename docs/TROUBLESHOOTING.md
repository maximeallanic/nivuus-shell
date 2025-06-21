# Troubleshooting Guide - Solutions aux Problèmes Courants

## 🐛 Problèmes après Installation

### 1. Erreur Antigen Cache
```
-antigen-cache-generate:zcompile:66: can't write zwc file: /etc/zsh/zshrc.zwc
```

**Solution :**
- Le cache antigen est maintenant configuré pour utiliser le répertoire utilisateur
- Si le problème persiste : `rm -rf ~/.cache/antigen && mkdir -p ~/.cache/antigen`

### 2. Installations Node.js Automatiques Répétées
```
📦 Installing Node.js LTS for default use...
📦 Node.js version 18 not installed. Installing...
```

**Solutions :**

**Option A - Désactiver l'auto-installation (recommandé) :**
```bash
# Désactivation permanente
rm -f ~/.nvm_auto_install
unset NVM_AUTO_INSTALL

# Ou utiliser l'outil de configuration
nvm-auto-install
```

**Option B - Activer l'auto-installation :**
```bash
# Activation permanente
touch ~/.nvm_auto_install

# Ou pour la session courante
export NVM_AUTO_INSTALL=true
```

**Option C - Installation manuelle :**
```bash
# Installer les versions nécessaires une fois
nvm install --lts          # Version LTS
nvm install 18             # Version 18 spécifique
nvm alias default lts/*    # Définir par défaut
```

### 3. Erreurs de Locale
```
manpath: can't set the locale; make sure $LC_* and $LANG are correct
```

**Solution :**
- Les locales sont maintenant configurées automatiquement
- Si le problème persiste :
```bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
```

### 4. Problème sudo/root
```
No such file or directory
Failed setting locale from environment variables
```

**Solutions :**

**Pour le mode root :**
```bash
# Le mode root-safe est automatiquement activé
sudo -E zsh    # Préserver l'environnement
# ou
sudo su -      # Shell root complet
```

**Vérifications :**
```bash
# Vérifier que sudo est installé
which sudo

# Vérifier les permissions
ls -la /usr/bin/sudo

# Tester la configuration
sudo -v
```

## 🔧 Commandes Utiles

### NVM et Node.js
```bash
nvm-health              # Diagnostic complet NVM
nvm-status              # Statut du projet Node.js
nvm-debug               # Debug approfondi
nvm-auto-install        # Configuration auto-installation
nvm-reload              # Recharger NVM
```

### Diagnostic Général
```bash
# Vérifier la configuration shell
zsh -c "source ~/.zshrc && echo 'OK'"

# Diagnostic des chemins
echo $PATH | tr ':' '\n'

# Vérifier les permissions
ls -la ~/.config/zsh-ultra

# Test des locales
locale -a | grep -E "(UTF-8|utf8)"
```

### Nettoyage
```bash
# Nettoyer les caches
rm -rf ~/.cache/antigen
rm -rf ~/.cache/zsh

# Réinitialiser NVM
rm -rf ~/.nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Réinstaller la configuration shell
./install.sh --debug
```

## 🚀 Configuration Optimale

### Pour les Développeurs
```bash
# Activer l'auto-installation NVM
touch ~/.nvm_auto_install

# Installer les versions Node.js courantes
nvm install --lts
nvm install 18
nvm install 20
nvm alias default lts/*
```

### Pour les Serveurs
```bash
# Désactiver l'auto-installation
rm -f ~/.nvm_auto_install

# Installer une version stable uniquement
nvm install --lts
nvm alias default lts/*
nvm use default
```

### Pour les Environnements Contraints
```bash
# Mode minimal activé automatiquement
export MINIMAL_MODE=1

# Désactiver les fonctionnalités lourdes
export SKIP_GLOBAL_CONFIG=1
export NVM_AUTO_INSTALL=false
```

## 📞 Support

Si les problèmes persistent :

1. **Générer un rapport de debug :**
   ```bash
   ./install.sh --debug --generate-report
   ```

2. **Vérifier les logs :**
   ```bash
   ls -la ~/.cache/shell-install-*.log
   cat ~/.cache/shell-install-*.log
   ```

3. **Test en mode minimal :**
   ```bash
   MINIMAL_MODE=1 zsh
   ```

4. **Réinstallation propre :**
   ```bash
   ./uninstall.sh
   ./install.sh --debug
   ```

## 🔍 Variables d'Environnement Importantes

```bash
# NVM
NVM_AUTO_INSTALL=true/false     # Auto-installation Node.js
NVM_DIR=~/.nvm                  # Répertoire NVM

# Shell
MINIMAL_MODE=1                  # Mode minimal
SKIP_GLOBAL_CONFIG=1            # Ignorer config globale

# Debug
DEBUG_MODE=true                 # Mode debug
VERBOSE_MODE=true               # Mode verbeux

# Locales
LANG=C.UTF-8                    # Langue système
LC_ALL=C.UTF-8                  # Toutes les locales
```
