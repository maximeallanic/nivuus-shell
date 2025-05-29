# 🚀 Modern ZSH Configuration

Configuration ZSH ultra-performante et modulaire pour développeurs. Installation simple et compatible Debian.

## ✨ Fonctionnalités

- 🔥 **Performance optimisée** - Démarrage < 300ms
- 🎨 **Coloration syntaxique** intelligente
- 💡 **Auto-suggestions** contextuelles
- 🤖 **Intégration GitHub Copilot CLI**
- 📦 **Détection automatique de projets**
- 🔒 **Gestion sécurisée des variables d'environnement**
- 🛠️ **Outils modernes** (eza, bat, fd, rg)
- 📊 **Monitoring et maintenance automatiques**

## 🚀 Installation rapide

```bash
# Cloner et installer
git clone https://github.com/your-username/shell-config.git ~/.config/zsh-config
cd ~/.config/zsh-config
chmod +x install.sh
./install.sh
```

## 📋 Prérequis

- ZSH 5.0+
- Git
- Curl

## 🔧 Configuration modulaire

```
config/
├── 01-performance.zsh      # Optimisations de performance
├── 02-history.zsh          # Configuration de l'historique
├── 03-completion.zsh       # Système d'auto-complétion
├── 04-keybindings.zsh      # Raccourcis clavier
├── 05-prompt.zsh           # Prompt personnalisé
├── 06-aliases.zsh          # Alias et raccourcis
├── 07-functions.zsh        # Fonctions intelligentes
├── 08-ai-integration.zsh   # Intégration IA (Copilot)
├── 09-syntax-highlighting.zsh # Coloration syntaxique
└── 10-environment.zsh      # Variables d'environnement
```

## 🛠️ Commandes utiles

```bash
# Diagnostic de santé
healthcheck

# Nettoyage automatique
cleanup

# Test de performance
benchmark

# Information système
sysinfo

# Analyse de taille de répertoires
analyze_size

# État Git amélioré
gstat
```

## 🤖 Intégration IA

```bash
# Suggestions de commandes shell
?? "find large files"

# Aide Git intelligente
?git "undo last commit"

# Explication de commandes
why "tar -xzf file.tar.gz"
```

## 📊 Performance

- Démarrage : < 300ms
- Complétion : < 50ms
- Git prompt : < 100ms

## 🔧 Personnalisation

Éditez `~/.zsh_local` pour vos configurations personnelles :

```bash
# Vos alias personnalisés
alias myproject='cd ~/dev/my-project'

# Variables d'environnement
export MY_API_KEY="your-key"

# Configurations spécifiques
export EDITOR="code"
```

## 🏥 Maintenance

La configuration inclut un système de maintenance automatique :

- Vérification des mises à jour (quotidienne)
- Nettoyage de l'historique (hebdomadaire)
- Optimisation des complétions (automatique)

## 📦 Dépendances optionnelles

```bash
# Installation des outils modernes recommandés
sudo apt install eza bat fd-find ripgrep jq htop

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh
```

## 🔄 Désinstallation

```bash
~/.config/zsh-config/uninstall.sh
```

## 📝 Licence

MIT - Voir [LICENSE](LICENSE) pour plus de détails.
