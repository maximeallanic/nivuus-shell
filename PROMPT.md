# Nivuus Shell - Prompt Format

Documentation du format exact du prompt shell.

## Format Visuel

### Local (succès)
```
> ~/projects/myapp git:(main)
```

### Local (erreur)
```
> ~/projects/myapp git:(main)x
```

### SSH (succès)
```
[hostname] > ~/projects/myapp git:(feature-branch)
```

### Root
```
# > /root git:(main)
```

### Avec Firebase
```
> ~/projects/myapp [my-firebase-project] git:(main)
```

---

## Composants du Prompt

### 1. Indicateur SSH
**Format:** `[hostname]`
**Couleur:** Gris (brackets) + Bleu (hostname)
**Condition:** Affiché uniquement si connexion SSH
**Détection:** Variables `$SSH_CLIENT`, `$SSH_TTY`, ou `$SESSION_TYPE`

### 2. Indicateur Root
**Format:** `#`
**Couleur:** Rouge
**Condition:** Affiché uniquement si utilisateur root
**Détection:** `whoami == "root"`

### 3. Indicateur de Status
**Format:** `>`
**Couleurs:**
- **Vert (gras)** - Dernière commande réussie (exit code 0)
- **Rouge (gras)** - Dernière commande échouée (exit code ≠ 0)

### 4. Chemin Actuel
**Format:** `~/path/to/directory`
**Couleur:** Cyan
**Comportement:**
- Affiche `~` pour le home directory
- Chemin relatif depuis ~
- Chemin complet si hors du home

### 5. Projet Firebase (Optionnel)
**Format:** `[project-name]`
**Couleur:** Jaune
**Condition:**
- Projet Firebase actif dans le répertoire courant
- Fichier `~/.config/configstore/firebase-tools.json` existe
- Variable `ENABLE_FIREBASE_PROMPT=true` (défaut)

**Désactiver:**
```bash
export ENABLE_FIREBASE_PROMPT=false
```

### 6. Information Git
**Format:** `git:(branch)` ou `git:(branch)x`
**Couleurs:**
- `git:(` - Bleu (gras)
- `branch` - Rouge
- `)` - Bleu (gras)
- `x` - Rouge (si modifications non commitées)

**Comportement:**
- Affiché uniquement dans un dépôt git
- Cache de 2 secondes pour les performances
- `x` indique des fichiers modifiés, staged, ou untracked

---

## Configuration des Couleurs

### Palette Utilisée

| Élément | Couleur ZSH | Code |
|---------|-------------|------|
| SSH hostname | `$fg_bold[blue]` | Bleu (gras) |
| SSH brackets | `$fg_bold[grey]` | Gris (gras) |
| Root indicator | `$fg[red]` | Rouge |
| Success status | `$fg_bold[green]` | Vert (gras) |
| Error status | `$fg_bold[red]` | Rouge (gras) |
| Path | `$fg[cyan]` | Cyan |
| Firebase project | `%F{yellow}` | Jaune |
| Git prefix | `$fg_bold[blue]` | Bleu (gras) |
| Git branch | `$fg[red]` | Rouge |
| Git dirty | `$fg[red]` | Rouge |

---

## Optimisations Performance

### Cache Git (2 secondes)
Le prompt utilise un cache pour éviter les appels git répétés :

**Variables de cache:**
- `_GIT_PROMPT_CACHE_DIR` - Répertoire en cache
- `_GIT_PROMPT_CACHE_TIME` - Timestamp du cache
- `_GIT_PROMPT_CACHE_VALUE` - Valeur en cache

**Configuration du TTL:**
```bash
export GIT_PROMPT_CACHE_TTL=5  # Cache pendant 5 secondes
```

### Désactiver Firebase
Pour améliorer les performances (gain ~10-20ms) :
```bash
export ENABLE_FIREBASE_PROMPT=false
```

---

## Structure Technique

### Ordre de Construction

```
[SSH] [ROOT] STATUS PATH [FIREBASE] GIT
```

**Exemple complet:**
```
[myserver] # > ~/project [firebase-app] git:(main)x
```

### Fonctions du Prompt

#### `is_ssh()`
Détecte si la session est en SSH.

#### `git_prompt_info()`
Génère l'information git avec cache.

#### `prompt_firebase()`
Génère l'information Firebase (optionnel).

#### `build_prompt()`
Construit le prompt final en combinant tous les composants.

---

## Variables d'Environnement

### Configuration

```bash
# Cache git (défaut: 2 secondes)
export GIT_PROMPT_CACHE_TTL=2

# Firebase dans le prompt (défaut: true)
export ENABLE_FIREBASE_PROMPT=true

# Désactiver la modification du prompt par environnements virtuels
export VIRTUAL_ENV_DISABLE_PROMPT=1
export CONDA_CHANGEPS1=false
```

---

## Exemples de Scénarios

### Développement Local
```bash
> ~/projects/myapp git:(main)
> ~/projects/myapp git:(feature-auth)x
```

### Serveur SSH
```bash
[production] > ~/apps/backend git:(main)
[staging] > ~/apps/backend git:(develop)x
```

### Root sur Serveur
```bash
[server] # > /etc/nginx git:(main)
```

### Projet Firebase + Git
```bash
> ~/projects/webapp [my-app-prod] git:(main)
> ~/projects/webapp [my-app-dev] git:(feature)x
```

### Erreur de Commande
```bash
> ~/projects/myapp git:(main)
❯ invalid-command
zsh: command not found: invalid-command
> ~/projects/myapp git:(main)
```

---

## Comportement Synchrone

Le prompt est **entièrement synchrone** pour garantir la fiabilité :

✅ **Avantages:**
- Information toujours à jour et précise
- Pas de "flash" ou de rafraîchissement visuel
- État git fiable à 100%
- Pas de race conditions

⚡ **Optimisations:**
- Cache git de 2 secondes
- Opérations git optimisées (--porcelain, --short)
- Firebase optionnel et configurable
- Pas d'appels externes inutiles

---

## Modification du Prompt

### Fichier de Configuration
**Emplacement:** `config/05-prompt.zsh`

### Exemple de Personnalisation

```bash
# Dans ~/.zshrc ou ~/.zsh_local

# Modifier le cache git
export GIT_PROMPT_CACHE_TTL=5

# Désactiver Firebase
export ENABLE_FIREBASE_PROMPT=false

# Personnaliser le prompt (après chargement)
PROMPT='%F{green}➜%f %F{cyan}%~%f $(git_prompt_info) '
```

### Recharger le Prompt
```bash
source ~/.zshrc
```

---

## Compatibilité

### Shells Supportés
- ✅ **ZSH** - Support complet
- ❌ **Bash** - Non supporté (utilise syntaxe ZSH spécifique)

### Environnements
- ✅ Local terminal
- ✅ SSH remote
- ✅ VS Code integrated terminal
- ✅ Web terminals (Codespaces, Gitpod)
- ✅ Tmux / Screen

### Outils Respectés
Le prompt désactive automatiquement la modification par :
- Python virtualenv (`VIRTUAL_ENV_DISABLE_PROMPT=1`)
- Conda (`CONDA_CHANGEPS1=false`)

---

## Dépannage

### Le prompt n'affiche pas git
**Vérifier:**
```bash
# Dans un dépôt git
git rev-parse --git-dir

# Vérifier le cache
echo $_GIT_PROMPT_CACHE_DIR
echo $_GIT_PROMPT_CACHE_TIME
```

### Le prompt est lent
**Solutions:**
```bash
# Augmenter le cache git
export GIT_PROMPT_CACHE_TTL=5

# Désactiver Firebase
export ENABLE_FIREBASE_PROMPT=false
```

### Les couleurs ne s'affichent pas
**Vérifier:**
```bash
# Support des couleurs
echo $TERM

# Forcer les couleurs
export TERM=xterm-256color
```

---

**Fichier source:** `config/05-prompt.zsh`
**Dernière mise à jour:** Janvier 2025
