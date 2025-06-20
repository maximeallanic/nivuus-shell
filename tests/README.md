# 🧪 Guide de Tests - Nivuus Shell

## Vue d'ensemble

Ce projet utilise un environnement de tests complet avec **BATS** (Bash Automated Testing System) pour assurer la qualité et la fiabilité de la configuration shell.

## 🏗️ Architecture des Tests

```
tests/
├── test_helper.bash          # Utilitaires communs
├── main.bats                 # Tests principaux  
├── unit/                     # Tests unitaires
│   ├── test_performance.bats
│   ├── test_functions.bats
│   └── test_aliases.bats
├── integration/              # Tests d'intégration
│   └── test_full_config.bats
├── performance/              # Benchmarks
│   └── test_benchmarks.bats
├── compatibility/            # Tests de compatibilité
│   └── test_environments.bats
├── fixtures/                 # Données de test
└── helpers/                  # Outils d'aide
```

## 🚀 Utilisation

### Lancement rapide

```bash
# Tous les tests
make test

# Tests spécifiques
make test-unit
make test-integration
make test-performance
make test-compatibility
make test-syntax

# Avec rapport détaillé
make test-report
```

### Script de test avancé

```bash
# Tests complets
./test-runner.sh all

# Tests spécifiques
./test-runner.sh unit
./test-runner.sh integration
./test-runner.sh performance
./test-runner.sh compatibility

# Avec rapport
./test-runner.sh all --report
```

## 📋 Types de Tests

### 🔬 Tests Unitaires
- **Objectif** : Valider chaque module individuellement
- **Couverture** : Fonctions, aliases, variables d'environnement
- **Rapidité** : < 10 secondes par module

### 🔗 Tests d'Intégration  
- **Objectif** : Vérifier l'interaction entre modules
- **Couverture** : Configuration complète, conflits potentiels
- **Scénarios** : Chargement complet, compatibilité inter-modules

### ⚡ Tests de Performance
- **Objectif** : Maintenir les performances < 300ms au démarrage
- **Métriques** : Temps de démarrage, usage mémoire, latence
- **Benchmarks** : Comparaison avec versions précédentes

### 🌐 Tests de Compatibilité
- **Objectif** : Support multi-environnements
- **Couverture** : ZSH versions, OS, modes spéciaux (root, SSH, containers)
- **Validation** : Dégradation gracieuse

## 🛠️ Ajout de Nouveaux Tests

### Test unitaire
```bash
#!/usr/bin/env bats

load ../test_helper

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "Mon nouveau test" {
    # Arrange
    load_config_module "mon-module.zsh"
    
    # Act
    run ma_fonction
    
    # Assert
    [ "$status" -eq 0 ]
    assert_contains "$output" "résultat attendu"
}
```

### Test d'intégration
```bash
@test "Integration avec autre module" {
    # Charger plusieurs modules
    load_config_module "module1.zsh"
    load_config_module "module2.zsh"
    
    # Tester l'interaction
    run fonction_integration
    [ "$status" -eq 0 ]
}
```

## 📊 Métriques et Rapports

### Métriques collectées
- ✅ Temps de démarrage shell (objectif < 300ms)
- 💾 Usage mémoire (objectif < 50MB)
- 🔧 Couverture des modules (100%)
- 🌐 Compatibilité OS/versions

### Rapports générés
- `test-report.txt` : Rapport détaillé
- Métriques de performance
- Couverture des tests
- Statut de compatibilité

## 🔧 Configuration Avancée

### Variables d'environnement de test
```bash
TEST_MODE=1              # Mode test actif
MINIMAL_MODE=1           # Configuration minimale
SKIP_UPDATES_CHECK=true  # Pas de vérifications de MAJ
TEST_HOME=/tmp/test_home # Répertoire home temporaire
```

### Utilitaires disponibles
```bash
setup_test_env()         # Initialise l'environnement
teardown_test_env()      # Nettoie après test
assert_file_exists()     # Vérifie existence fichier
assert_command_exists()  # Vérifie disponibilité commande
measure_startup_time()   # Mesure performance démarrage
```

## 🚨 Dépannage

### BATS non installé
```bash
# Installation automatique
./test-runner.sh all
# ou manuel
make test
```

### Tests qui échouent
```bash
# Mode verbose
bats -t tests/unit/test_performance.bats

# Test individuel
bats -t -f "nom du test" tests/main.bats
```

### Problèmes de performance
```bash
# Benchmark individuel
./test-runner.sh performance
# Profiling détaillé disponible dans test-report.txt
```

## 📈 Amélioration Continue

### Métriques cibles
- 🚀 Démarrage : < 300ms
- 💾 Mémoire : < 50MB
- 🧪 Couverture : 100%
- ⚡ CI/CD : < 5min

### Bonnes pratiques
1. **Test d'abord** : Écrire les tests avant les fonctionnalités
2. **Isolation** : Chaque test indépendant
3. **Performance** : Valider impact performance
4. **Compatibilité** : Tester sur environnements variés

## 🔄 CI/CD

Les tests s'exécutent automatiquement :
- ✅ Sur chaque push/PR
- 🌙 Tests nocturnes complets  
- 📊 Rapports automatiques
- 🚀 Multi-plateformes (Ubuntu, macOS)

---

**Pour plus d'informations** : `./test-runner.sh --help`
