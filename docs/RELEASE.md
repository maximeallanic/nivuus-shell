# Release Automation

Le script `release.sh` automatise la création de versions et de tags Git.

## Usage

```bash
./release.sh [OPTIONS] <bump_type>
```

### Types de version

- `patch` : 1.0.0 → 1.0.1 (corrections de bugs)
- `minor` : 1.0.0 → 1.1.0 (nouvelles fonctionnalités)
- `major` : 1.0.0 → 2.0.0 (breaking changes)

### Options

- `-d, --dry-run` : Aperçu des changements sans les appliquer
- `-y, --yes` : Ignorer les confirmations
- `-h, --help` : Aide

### Exemples

```bash
# Version patch (recommandé pour les corrections)
./release.sh patch

# Version minor (nouvelles fonctionnalités)
./release.sh minor

# Aperçu sans changements
./release.sh -d patch

# Release automatique sans confirmation
./release.sh -y patch
```

## Processus automatisé

Le script effectue automatiquement :

1. ✅ Vérification du repo Git et de l'état propre
2. 📝 Lecture de la version actuelle depuis `VERSION`
3. 🔢 Calcul de la nouvelle version
4. 📄 Mise à jour du fichier `VERSION`
5. 💾 Commit des changements
6. 🏷️ Création du tag `v{version}`
7. 🚀 Push vers origin
8. 🤖 Déclenchement automatique de la GitHub Action

## Sécurité

- Vérification que le working directory est propre
- Confirmation avant exécution (sauf avec `-y`)
- Mode dry-run pour tester sans risque
- Validation du format de version sémantique
