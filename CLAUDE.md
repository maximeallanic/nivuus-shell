# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Instructions pour Claude

**IMPORTANT:** Si tu découvres un élément important à retenir lors de ton travail (pattern récurrent, contrainte critique, bug résolu, architecture cachée), ajoute-le immédiatement à ce fichier. Garde le contenu condensé et sans duplication - fusionne avec les sections existantes si possible.

## Project Overview

Nivuus Shell: Framework ZSH modulaire haute performance (22 modules, cible <300ms startup, support multi-OS).

## Commandes Essentielles

```bash
# Tests (BATS) - TOUJOURS valider <300ms avec test-performance
make test                   # Tous les tests
make test-unit              # Tests unitaires
make test-performance       # Benchmarks <300ms (CRITIQUE)
make test-integration       # Tests d'intégration
bats -t -f "name" file.bats # Test spécifique

# Développement
make dev-setup              # Setup complet: deps + backup + install + test
make install                # Installation user
sudo ./install.sh --system  # Installation system-wide
make lint                   # Shellcheck
make benchmark              # Profiling startup (5 runs)

# Release (requiert git clean)
make release-{patch|minor|major}
./scripts/release.sh patch --auto-changelog  # Génère changelog des commits
```

## Architecture Critique

### Ordre de Chargement des Modules (00-99)
**NE JAMAIS changer les numéros** - l'ordre prévient les conflits :
- **00-*** Init (PATH, root protection, VS Code)
- **01-03** Core perf (performance, history, completion)
- **04-07** UX (keybindings, prompt, aliases, functions)
- **08-09** Enhancements (AI, syntax highlighting)
- **10-17** Features (env, maintenance, diagnostics, vim, NVM)
- **99-*** Final fixes (PATH final, root-safe)

Nouveaux modules → position 10-17.

### Installation Modulaire
`install.sh` orchestre `install/{common,packages,backup,config,nvm,system,verification}.sh` dans cet ordre.

**Pattern clé:** Si exécuté en remote (curl pipe) sans modules → auto-clone dans `/tmp/shell-install-$$` et re-exécute.

### Patterns de Détection

**Root (3 niveaux - NE JAMAIS compromettre la sécurité root) :**
```bash
[[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]] || [[ "$(whoami)" == "root" ]]
# → Antigen DÉSACTIVÉ, config minimale (99-root-safe.zsh), vim isolé (/root/.vimrc.*)
```

**Environnement (SSH/VS Code/Web) :**
```bash
[[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]                              # SSH
[[ "$TERM_PROGRAM" == "vscode" || -n "$VSCODE_IPC_HOOK_CLI" ]]      # VS Code
[[ -n "$CODESPACES" || -n "$GITPOD_WORKSPACE_ID" ]]                  # Web
```

**Tests :**
```bash
TEST_MODE=1 MINIMAL_MODE=1 SKIP_UPDATES_CHECK=true  # Variables pour tests
```

### Performance <300ms (HARD REQUIREMENT) - ÉTAT: ~350-550ms (amélioration 95%+)

**Objectif:** <300ms | **Actuel:** ~350-550ms (selon config) | **Baseline:** 6000ms

**Optimisations implémentées (oct 2025 - commit e32c073):**

1. **Ultra-lazy NVM loading v2** (16-nvm-integration.zsh + .zshrc) - Sauvegarde ~1000ms
   - **CRITIQUE**: Supprimé chargement direct dans `.zshrc` (lignes 10-12)
   - NVM n'est PAS chargé au startup (même pas `nvm.sh`)
   - Wrappers pour `nvm`, `node`, `npm`, `npx` chargent à la demande
   - Hook `chpwd` optimisé: `_NIVUUS_LAST_PWD="$(pwd)"` au init (skip premier call)
   - Variables: `_NIVUUS_NVM_LOADED`, `_NIVUUS_NODE_LAZY_LOADED`
   - **NE JAMAIS** ajouter `source nvm.sh` dans `.zshrc` ou `07-functions.zsh`!

2. **Compinit optimisé** (03-completion.zsh) - Sauvegarde 160ms
   - Toujours utiliser `compinit -C` (skip compaudit security check)
   - Background zcompile avec `&!`
   - Vérification manuelle: `compinit` (sans -C)

3. **PATH diagnostics optionnel** (00-path-diagnostic.zsh) - Sauvegarde 140ms
   - Désactivé par défaut (variable `ENABLE_PATH_DIAGNOSTICS=false`)
   - Commande manuelle: `diagnose_path`

4. **Vim lazy setup** (13-vim-integration.zsh) - Sauvegarde ~100ms
   - Configs créées à la première utilisation
   - `smart_vim()` appelle setup si nécessaire

5. **Async auto-suggestions** (09-syntax-highlighting.zsh) - Sauvegarde ~20-40ms
   - `ZSH_AUTOSUGGEST_USE_ASYNC=true` (non-bloquant)

6. **Syntax highlighting optionnel** - Sauvegarde ~27ms (si désactivé)
   - Variable: `ENABLE_SYNTAX_HIGHLIGHTING=true` (défaut: activé)
   - Désactiver: `export ENABLE_SYNTAX_HIGHLIGHTING=false` dans `~/.zshrc`

7. **Project detection silencieux** - Sauvegarde ~10-20ms
   - Variable: `ENABLE_PROJECT_DETECTION=false` (défaut: silencieux)
   - Activer: `export ENABLE_PROJECT_DETECTION=true`

**Performance attendue:**
- Sans projets Node.js: **~350ms** (avec syntax highlighting)
- Sans projets Node.js + `ENABLE_SYNTAX_HIGHLIGHTING=false`: **~320ms**
- Avec NVM activé (première utilisation): +200-300ms (une seule fois)

**Variables d'optimisation:**
```bash
export ENABLE_SYNTAX_HIGHLIGHTING=false  # Gagne ~27ms
export ENABLE_PROJECT_DETECTION=false    # Défaut, gagne ~10-20ms si true
export ENABLE_PATH_DIAGNOSTICS=false     # Défaut, gagne ~140ms si true
```

**TOUJOURS** `make test-performance` après modifications

### Cross-Platform

`install/common.sh` détecte OS → `install/packages.sh` stratégie de fallback :
1. Package manager système
2. GitHub releases (eza, etc.)
3. Installation user-local si permission denied
4. Skip avec warning

**Nouvelle dépendance** → ajouter à la matrice dans `install/packages.sh` pour tous les OS.

## Tests (BATS)

Template test unitaire :
```bash
#!/usr/bin/env bats
load ../test_helper
setup() { setup_test_env; }
teardown() { teardown_test_env; }

@test "nom descriptif" {
    load_config_module "module.zsh"
    run command_to_test
    [ "$status" -eq 0 ]
    [[ "$output" == *"expected"* ]]
}
```

Tests intégration : charger plusieurs modules, tester interactions.

## Patterns de Configuration

**Template module :**
```bash
#!/usr/bin/env zsh
# Module: XX-name.zsh
[[ -n "$MINIMAL_MODE" ]] && return 0  # Skip si test
[[ $EUID -eq 0 ]] && return 0          # Skip si root (si nécessaire)
# Contenu...
```

**Sourcing sécurisé (chemins multiples) :**
```bash
for dir in "/usr/share/zsh/plugins/name" "/usr/local/share/name" "$HOME/.local/share/name"; do
    [[ -f "$dir/name.zsh" ]] && { source "$dir/name.zsh"; break; }
done
```

## Backup Intelligent

`install/backup.sh` :
1. Backup horodaté : `~/.config/zsh-ultra-backup/backup-YYYYMMDD_HHMMSS/`
2. Extrait configs user (Google Cloud SDK, NVM, aliases custom) par pattern matching
3. Ré-injecte après installation

**Modifier backup** → TOUJOURS préserver customisations user.

## Patterns d'Implémentation

**Chargement modules (globbing auto-sort 00-99) :**
```bash
for config_file in "$ZSH_CONFIG_DIR"/config/*.zsh; do
    [[ -r "$config_file" ]] && source "$config_file"
done
```

**Vim multi-config (`13-vim-integration.zsh`):**
- `~/.vimrc.modern` (local complet) + `~/.vimrc.ssh` (SSH/web optimisé)
- Auto-détection dans `~/.vimrc`
- Fix backspace terminal : `inoremap <Del> <C-h>` (vim) + fixes dans `04-keybindings.zsh` (zsh)

**NVM auto-switch (`16-nvm-integration.zsh`):**
- Hook `chpwd()` → détecte `.nvmrc` → cache last dir → export vars VS Code

**AI conditionnel (`08-ai-integration.zsh`):**
```bash
command -v gh &> /dev/null && gh extension list | grep -q copilot && alias ??='gh copilot suggest'
```

## Modes d'Installation

| Mode | Config dir | Vim | Source |
|------|-----------|-----|---------|
| **User (défaut)** | `~/.config/nivuus-shell/` | `~/.vimrc.*` | `~/.zshrc` |
| **System-wide** | `/opt/nivuus-shell/` | `/etc/vim/vimrc.modern` | `/etc/zsh/zshrc.d/`, `/etc/profile` |

Détection : priorité `/opt/nivuus-shell` → `~/.config/nivuus-shell`

## Release (`scripts/release.sh`)

1. Validation: deps (`git`, `gh`, `sed`, `date`) + git clean
2. Incrémente `VERSION` + `install.sh`
3. Génère `CHANGELOG.md` : auto (`--auto-changelog` parse commits conventionnels feat:/fix: + emoji) ou manuel (timeout 30s)
4. Commit + tag + push (sauf `--no-push`) + GitHub release (`gh`)

## Pièges Courants

1. **Ordre modules** : NE PAS changer numéros (10-17 pour new features)
2. **Root** : NE JAMAIS charger Antigen/plugins lourds pour root → check `$EUID -eq 0` tôt
3. **Performance** : NE PAS appels externes sync dans prompt/hooks → caching + benchmark après modifs
4. **Cross-platform** : NE PAS assumer noms packages (`fd` vs `fd-find`) → conditionals + fallbacks
5. **Tests** : NE PAS update checks/externes → check `$TEST_MODE`/`$SKIP_UPDATES_CHECK`
6. **Backup** : NE PAS écraser configs user → pattern matching dans `install/backup.sh`

## Documentation

- **API.md** - Référence fonctions (50+ utils) | **ARCHITECTURE.md** - Architecture technique
- **README.md** - Features user | **CHANGELOG.md** - Historique versions
- **tests/README.md** - Guide tests | **docs/** - Troubleshooting, debug install, backup strategy
