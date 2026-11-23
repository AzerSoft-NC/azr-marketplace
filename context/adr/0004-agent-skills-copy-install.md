# ADR 0004 — Install par copie et catalogue à 7 skills

## Status

Accepted

Amended by [ADR 0010](./0010-pinned-vendors-skill-inspector.md) (pinned vendors; catalog skill count no longer fixed at 7).

## Context

L'install par symlink (`install-symlinks.sh`) rendait les edits du catalogue immédiats dans `~/.cursor/skills/`, mais empêchait de contrôler ce qui est réellement chargé : Cursor parcourt les skills **récursivement** et ne documente **aucun** moyen de désactiver un skill installé (`disabled`, ignore file, etc.). Un dossier `skills/deprecated/` sous le catalogue aurait pu être symlinké par le glob `skills/*/*/` et devenir actif par accident.

Par ailleurs, `domain-modeling` dupliquait les formats ADR/CONTEXT de `grill-me` et était affamé par `architecture-forks.mdc`, qui route les arbitrages vers `grill-me` par défaut — deux skills pour une même discipline.

Enfin, `.cursor/` était gitignoré en bloc, ce qui empêchait de versionner `.cursor/mcp.json` (MCP servers) tout en laissant du bruit généré (`.cursor/plans/`).

## Decision

- Remplacer `install-symlinks.sh` par **`install-skills.sh`** : **copie** des skills et rules catalogués, manifeste `~/.cursor/skills/.azr-installed` pour retirer les skills retirés du catalogue, catégories explicites **`engineering`**, **`productivity`**, **`misc`** — jamais **`deprecated/`**.
- Copier aussi les skills superpowers depuis `~/.cursor/vendor/superpowers` après `git pull` ; toujours exclure `using-superpowers`.
- **Fusionner `domain-modeling` dans `grill-me`** : glossaire, ADR, multi-contexte `CONTEXT-MAP`, heuristiques de design ; catalogue maison à **7** skills.
- Gitignore **`.cursor/plans/`** et **`.cursor/handoffs/`** (pas tout `.cursor/`) ; versionner `.cursor/mcp.json`. Session handoffs/plans are local-only — [ADR 0015](./0015-cursor-handoffs-plans.md).

## Consequences

- Après edit du catalogue, **`ai/install-skills.sh` est obligatoire** — plus d'effet immédiat via symlink.
- Mise à jour superpowers : **`git pull` dans vendor puis reinstall** — dérive upstream **voulue**, pas un bug d'épinglage (cf. ADR 0002).
- ~21 skills actifs (7 catalogués + 14 vendor) tant que superpowers n'ajoute pas de skill.
- `teach-me/CONTEXT-FORMAT.md` reste jumeau byte-identique de `grill-me` pour installation isolée.

## Alternatives rejected

- **Garder les symlinks** : édition à chaud, mais pas de garde-fou sur `deprecated/` ni sur skills retirés du manifeste.
- **Garder domain-modeling** : duplication de formats et déclencheurs qui se chevauchent avec `grill-me`.
- **Archiver deprecated dans `skills/` sans garde** : risque d'activation dès qu'un glob ou un symlink change.
