# Installation Debug Guide

## Comment debugger les problèmes d'installation

### 1. Options de debug disponibles

```bash
# Mode debug complet (verbose + debug logs)
./install.sh --debug

# Mode verbose seulement
./install.sh --verbose

# Spécifier un fichier de log personnalisé
./install.sh --debug --log-file /tmp/my-install.log

# Générer un rapport de debug complet
./install.sh --generate-report
```

### 2. Tests d'installation avec BATS

```bash
# Tester toutes les fonctions d'installation
make test-install

# Tester des parties spécifiques
bats tests/install/test_installation.bats --filter "Debug mode"
bats tests/install/test_install_script.bats --filter "Installation script"
```

### 3. Test manuel des fonctions

```bash
# Script de test des fonctions d'installation
./scripts/test-installation.sh --debug
```

### 4. Fichiers de logs automatiques

Les logs sont automatiquement créés dans :
- Mode utilisateur : `$HOME/.cache/shell-install-TIMESTAMP.log`  
- Mode système : `/tmp/shell-install-TIMESTAMP.log`

### 5. Rapport de debug

Le rapport de debug inclut :
- Informations système complètes
- Variables d'environnement
- Permissions des fichiers
- Gestionnaires de paquets disponibles
- Versions des shells
- Log complet de l'installation

### 6. Fonctions de debug disponibles

Dans `install/common.sh` :

```bash
# Messages de debug (seulement en mode --debug)
print_debug "Message de debug"

# Messages verbeux (en modes --verbose et --debug)
print_verbose "Message verbeux"

# Exécution de commandes avec logging
execute_cmd "ma_commande" "Description" [exit_on_error]

# Vérification de commandes avec logging
check_command "nom_commande" [required]

# Génération du rapport de debug
generate_debug_report
```

### 7. Variables d'environnement utiles

```bash
export DEBUG_MODE=true      # Active le mode debug
export VERBOSE_MODE=true    # Active le mode verbose
export LOG_FILE=/path/to/log # Spécifie le fichier de log
```

### 8. Exemple d'utilisation sur un système à problème

```bash
# 1. Exécuter avec debug complet
./install.sh --debug

# 2. Si l'installation échoue, générer un rapport
./install.sh --generate-report

# 3. Envoyer le fichier de rapport généré pour support
# Le fichier sera dans le même répertoire que le log, avec l'extension _debug_report.txt
```

### 9. Tests automatisés

Les tests BATS vérifient :
- Chargement correct des modules d'installation
- Fonctions de print et debug
- Détection du système d'exploitation
- Gestion des permissions
- Parsing des arguments
- Génération des rapports
- Robustesse du script principal

### 10. Dépannage courant

| Problème | Solution |
|----------|----------|
| Script ne se lance pas | Vérifier les permissions : `chmod +x install.sh` |
| Erreur de chemin | Lancer depuis le répertoire racine du projet |
| Pas de logs | Vérifier les permissions d'écriture dans `~/.cache/` |
| Commandes manquantes | Le rapport de debug listera les commandes disponibles |
| Erreurs de permissions | Utiliser `--debug` pour voir les détails des permissions |
