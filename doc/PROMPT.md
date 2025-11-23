# Nivuus Shell - Prompt Format

Documentation du format exact du prompt shell.

## Format Visuel

### Local (succès)
```
> ~/projects/myapp git:(main)●
```

### Local (erreur)
```
> ~/projects/myapp git:(main)○
```

### SSH (succès)
```
[hostname] > ~/projects/myapp git:(feature-branch)●
```

### Root
```
# > /root git:(main)●
```

### Avec Python venv
```
> ~/projects/myapp (venv) git:(main)●
> ~/projects/myapp (conda:myenv) git:(main)●
> ~/projects/myapp (poetry) git:(main)●
```

### Avec Cloud Context
```
> ~/projects/myapp aws:production git:(main)●
> ~/projects/myapp gcp:my-project git:(main)●
> ~/projects/myapp az:subscription git:(main)●
```

### Avec Firebase
```
> ~/projects/myapp [my-firebase-project] git:(main)●
```

### Avec Background Jobs (RPROMPT)
```
> ~/projects/myapp git:(main)●                                    [▶ vim ⏸ npm]
> ~/projects/myapp git:(main)●                                         [▶ 3 ⏸ 1]
```

---

## Composants du Prompt (Main)

### 1. Indicateur SSH
**Format:** `[hostname]`
**Couleur:** Gris (brackets) + Bleu (hostname)
**Condition:** Affiché uniquement si connexion SSH
**Détection:** Variables `$SSH_CLIENT`, `$SSH_TTY`, ou `$SESSION_TYPE`

### 2. Indicateur Root
**Format:** `#`
**Couleur:** Rouge
**Condition:** Affiché uniquement si utilisateur root
**Détection:** `$EUID == 0` ou `whoami == "root"`

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

### 5. Python Virtual Environment (Optionnel)
**Format:** `(venv)`, `(conda:name)`, ou `(poetry)`
**Couleur:** Purple (180)
**Condition:**
- Variable `ENABLE_PYTHON_VENV=true` (défaut)
- Environnement virtuel actif détecté

**Types supportés:**
- **venv/virtualenv** - Affiche `(venv)`
- **Conda** - Affiche `(conda:env-name)`
- **Poetry** - Affiche `(poetry)`

**Désactiver:**
```bash
export ENABLE_PYTHON_VENV=false
```

### 6. Cloud Provider Context (Optionnel)
**Format:** `aws:profile`, `gcp:project`, ou `az:subscription`
**Couleurs:**
- **AWS** - Orange (214)
- **GCP** - Cyan (110)
- **Azure** - Blue (67)

**Condition:**
- Variable `ENABLE_CLOUD_PROMPT=true` (défaut)
- Context cloud actif détecté

**Détection:**
- **AWS:** `$AWS_PROFILE` (sauf "default")
- **GCP:** `$CLOUDSDK_CORE_PROJECT` (si Firebase prompt désactivé)
- **Azure:** `$AZURE_SUBSCRIPTION_ID` ou subscription name

**Désactiver:**
```bash
export ENABLE_CLOUD_PROMPT=false
```

### 7. Projet Firebase (Optionnel)
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

### 8. Information Git
**Format:** `git:(branch)●` ou `git:(branch)○`
**Couleurs:**
- `git:(` - Cyan
- `branch` - Red
- `)` - Cyan
- `●` - Vert (repo propre)
- `○` - Rouge (modifications non commitées)

**Comportement:**
- Affiché uniquement dans un dépôt git
- Cache de 2 secondes pour les performances (configurable)
- `○` (cercle vide) indique des fichiers modifiés/staged/untracked
- `●` (cercle plein) indique un repo propre

---

## Composants du Prompt (Right - RPROMPT)

### Background Jobs
**Format:** `[▶ name1 ⏸ name2]` ou `[▶ 3 ⏸ 1]`
**Couleurs:**
- `▶` + running jobs - Vert (143)
- `⏸` + stopped jobs - Rouge (167)

**Comportement:**
- Affiche les jobs en arrière-plan automatiquement
- ≤ 2 jobs: Affiche les noms des commandes
- \> 2 jobs: Affiche les comptes numériques
- Utilise les variables ZSH natives: `${(kv)jobstates}` et `${jobtexts}`
- Mise à jour automatique à chaque prompt

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
| Git clean (●) | `%F{143}` | Vert (143) |
| Git dirty (○) | `%F{167}` | Rouge (167) |
| Python venv | `%F{180}` | Purple (180) |
| AWS context | `%F{214}` | Orange (214) |
| GCP context | `%F{110}` | Cyan (110) |
| Azure context | `%F{67}` | Blue (67) |
| RPROMPT running | `%F{143}` | Vert (143) |
| RPROMPT stopped | `%F{167}` | Rouge (167) |

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
[SSH] [ROOT] STATUS PATH (VENV) CLOUD [FIREBASE] GIT      [JOBS]
                                                           (RPROMPT)
```

**Exemple complet (main prompt):**
```
[myserver] # > ~/project (venv) aws:prod [firebase-app] git:(main)○
```

**Exemple complet (avec RPROMPT):**
```
[myserver] > ~/project gcp:myapp git:(main)●                    [▶ vim ⏸ npm]
```

### Fonctions du Prompt

#### `is_ssh()`
Détecte si la session est en SSH.

#### `prompt_python_venv()`
Détecte et affiche l'environnement virtuel Python actif.

#### `prompt_cloud_context()`
Détecte et affiche le contexte cloud (AWS/GCP/Azure).

#### `prompt_firebase()`
Génère l'information Firebase (optionnel).

#### `git_prompt_info()`
Génère l'information git avec cache et indicateur de statut (●/○).

#### `background_jobs_info()`
Affiche les jobs en arrière-plan pour le RPROMPT.

#### `build_prompt()`
Construit le prompt final en combinant tous les composants.

---

## Variables d'Environnement

### Configuration

```bash
# Cache git (défaut: 2 secondes)
export GIT_PROMPT_CACHE_TTL=2

# Python venv dans le prompt (défaut: true)
export ENABLE_PYTHON_VENV=true

# Auto-activation de venv au cd (défaut: false)
export ENABLE_PYTHON_AUTO_ACTIVATE=false

# Cloud context dans le prompt (défaut: true)
export ENABLE_CLOUD_PROMPT=true

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
> ~/projects/myapp git:(main)●
> ~/projects/myapp git:(feature-auth)○
```

### Serveur SSH
```bash
[production] > ~/apps/backend git:(main)●
[staging] > ~/apps/backend git:(develop)○
```

### Root sur Serveur
```bash
[server] # > /etc/nginx git:(main)●
```

### Python Development avec venv
```bash
> ~/projects/myapp (venv) git:(main)●
> ~/projects/data-science (conda:ml) git:(develop)○
> ~/projects/web (poetry) git:(main)●
```

### Cloud Provider Context
```bash
> ~/projects/backend aws:production git:(main)●
> ~/projects/infra gcp:my-project git:(terraform)○
> ~/projects/webapp az:my-subscription git:(main)●
```

### Projet Firebase + Git
```bash
> ~/projects/webapp [my-app-prod] git:(main)●
> ~/projects/webapp [my-app-dev] git:(feature)○
```

### Avec Background Jobs
```bash
> ~/projects/myapp git:(main)●                                      [▶ vim]
> ~/projects/myapp git:(main)●                                   [▶ npm ⏸ git]
> ~/projects/myapp git:(main)●                                      [▶ 3 ⏸ 1]
```

### Erreur de Commande
```bash
> ~/projects/myapp git:(main)●
❯ invalid-command
zsh: command not found: invalid-command
> ~/projects/myapp git:(main)○
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
