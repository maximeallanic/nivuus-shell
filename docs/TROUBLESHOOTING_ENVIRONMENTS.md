# Guide de Dépannage - Environnements Problématiques

## Problèmes fréquents et solutions

### 🌍 Erreur "Failed setting locale from environment variables"

**Symptômes :**
- `Failed setting locale from environment variables`
- `locale: Cannot set LC_ALL to default locale: No such file or directory`

**Solutions :**

1. **Solution rapide (temporaire) :**
   ```bash
   export LANG=C.UTF-8
   export LC_ALL=C.UTF-8
   ```

2. **Solution permanente :**
   ```bash
   # Installer les locales sur Debian/Ubuntu
   sudo apt-get update && sudo apt-get install -y locales
   sudo locale-gen en_US.UTF-8
   
   # Sur CentOS/RHEL
   sudo yum install -y glibc-locale-source glibc-langpack-en
   
   # Puis ajouter à ~/.bashrc ou ~/.zshrc
   echo 'export LANG=C.UTF-8' >> ~/.bashrc
   echo 'export LC_ALL=C.UTF-8' >> ~/.bashrc
   ```

3. **Test automatique :**
   ```bash
   ./scripts/env-diagnostic.sh
   ```

### 🔐 Problème "sudo su" - "No such file or directory"

**Symptômes :**
- `sudo su`: command not found
- `su`: command not found

**Causes possibles :**
- PATH restreint
- Système minimal (container, chroot)
- Installation incomplète

**Solutions :**

1. **Vérifier la disponibilité :**
   ```bash
   which sudo
   which su
   ls -la /usr/bin/sudo /bin/su
   ```

2. **Alternative avec sudo -i :**
   ```bash
   sudo -i  # Au lieu de sudo su
   ```

3. **Forcer le mode root-safe :**
   ```bash
   export FORCE_ROOT_SAFE=1
   bash install.sh
   ```

4. **Installation en mode utilisateur :**
   ```bash
   bash install.sh --user-mode
   ```

### 🛡️ Mode Root-Safe automatique

Le système active automatiquement le mode root-safe dans ces cas :

- `EUID=0` ou `UID=0`
- `USER=root` ou `HOME=/root`
- `SUDO_USER` ou `SUDO_UID` défini
- `LANG=C` + pas de `DISPLAY` + HOME non accessible
- `PATH=/usr/bin:/bin` (PATH minimal)
- `FORCE_ROOT_SAFE=1` ou `MINIMAL_MODE=1`

**Diagnostic :**
```bash
./scripts/env-diagnostic.sh
```

### 🐳 Environnements conteneurisés

**Docker/Podman :**
```bash
# Utiliser l'installation minimale
export MINIMAL_MODE=1
bash install.sh

# Ou forcer le mode conteneur
export CONTAINER_ENV=1
bash install.sh
```

**LXC/SystemD-nspawn :**
```bash
# Installer les locales dans le conteneur
apt-get update && apt-get install -y locales
locale-gen C.UTF-8

# Puis installer
export LANG=C.UTF-8
bash install.sh
```

### 🚨 Environnements très restreints

**Chroot/Jail :**
```bash
# Mode minimal obligatoire
export MINIMAL_MODE=1
export SKIP_GLOBAL_CONFIG=1
bash install.sh --user-mode --minimal
```

**Systèmes embarqués :**
```bash
# Vérifier les prérequis
./scripts/env-diagnostic.sh

# Installation ultra-légère
export MINIMAL_MODE=1
export SKIP_PACKAGE_INSTALL=1
bash install.sh --no-packages --minimal
```

### 🔧 Commandes de diagnostic

1. **Diagnostic complet :**
   ```bash
   ./scripts/env-diagnostic.sh
   ```

2. **Test du mode root-safe :**
   ```bash
   export DEBUG_MODE=true
   source config/99-root-safe.zsh
   ```

3. **Test des locales :**
   ```bash
   export DEBUG_MODE=true
   source config/10-environment.zsh
   ```

4. **Vérification PATH :**
   ```bash
   echo $PATH
   which bash zsh sudo su
   ```

### 📞 Demande d'aide

Si les problèmes persistent :

1. **Exécuter le diagnostic :**
   ```bash
   ./scripts/env-diagnostic.sh > diagnostic.txt
   ```

2. **Partager le diagnostic** avec votre demande d'aide

3. **Informations utiles à inclure :**
   - Type de système (Ubuntu, CentOS, Alpine, etc.)
   - Environnement (bare metal, VM, container, etc.)
   - Contexte d'exécution (utilisateur, sudo, root, etc.)
   - Message d'erreur complet

### ✅ Vérification post-installation

```bash
# Test rapide
zsh -c "echo 'Installation OK'"

# Test complet
make test-environments

# Vérification manuelle
source ~/.zshrc
echo $SHELL
locale
```

## Variables d'environnement de secours

| Variable | Usage | Exemple |
|----------|--------|---------|
| `FORCE_ROOT_SAFE=1` | Force le mode root-safe | `export FORCE_ROOT_SAFE=1` |
| `MINIMAL_MODE=1` | Mode minimal (pas d'antigen) | `export MINIMAL_MODE=1` |
| `DEBUG_MODE=true` | Affiche les diagnostics | `export DEBUG_MODE=true` |
| `SKIP_GLOBAL_CONFIG=1` | Ignore la config globale | `export SKIP_GLOBAL_CONFIG=1` |
| `CONTAINER_ENV=1` | Mode conteneur | `export CONTAINER_ENV=1` |
