# ADR 0002 — Skills d'agent vendorés depuis superpowers, rules maison souveraines

## Status

Accepted

Amended by [ADR 0010](./0010-pinned-vendors-skill-inspector.md) (pinned vendors, SkillSpector) and [ADR 0011](./0011-agent-docs-under-context-ai-catalog.md) (install-time path patches on copied skills).

## Context

Le catalogue `ai/` maintenait 11 skills écrits maison. Plusieurs recouvraient des collections publiques bien plus profondes : `diagnose` faisait 117 lignes contre 1017 pour `systematic-debugging` de [superpowers](https://github.com/obra/superpowers), `new-skill` 359 contre 2591 pour `writing-skills`, `tdd` 303 contre 528 pour `test-driven-development`. Maintenir ces trois-là revenait à réécrire moins bien ce qui existait déjà.

Deux collections étaient candidates. **superpowers** (MIT) est du process agnostique du langage, versionné, et porte Cursor nativement via `.cursor-plugin/plugin.json`. **everything-claude-code** est la config Claude Code personnelle d'un développeur, publiée en annexe de deux threads X : sur 11 skills, cinq sont des packs de patterns TypeScript / React / Node / ClickHouse, sans rapport avec la stack Jakarta EE + DB2 d'ici, et sa plomberie (hooks Node, `.claude-plugin`) n'a pas d'équivalent Cursor.

Le piège était dans l'installation. Le plugin superpowers embarque un hook `sessionStart` qui injecte son skill `using-superpowers` dans **chaque** conversation, encadré de `<EXTREMELY_IMPORTANT>`, imposant l'invocation d'un skill avant toute réponse — y compris avant une question de clarification ou l'exploration du code — et le passage par `brainstorming` avant le mode plan. Cela contredit `caveman-default.mdc` et court-circuite `architecture-forks.mdc`, qui route les arbitrages d'architecture vers `grill-me`.

## Decision

- **Adopter superpowers, rejeter everything-claude-code.**
- Cloner superpowers dans `~/.cursor/vendor/superpowers`, **hors du repo tracké**, et symlinker ses skills vers `~/.cursor/skills/` depuis `ai/install-symlinks.sh`. Mise à jour par `git pull`.
- **Ne rien éditer localement** : le diff contre upstream reste vide. Toute adaptation de comportement passe par `rules/`.
- **Ne pas enregistrer le plugin** et **ne pas installer `using-superpowers`**. Son noyau utile est réécrit en un paragraphe sous « Core Philosophy » dans `ai/global-config/user-CURSOR.md`, subordonné à `caveman-default`.
- **Supprimer** `diagnose`, `tdd` et `new-skill` du catalogue. Le catalogue ne garde que ce qui n'a pas d'équivalent upstream : `commit`, `caveman`, `teach-me`, `init-repo`, `grill-me`, `domain-modeling`, `handoff`, `less-trouble`.
- Conserver le matériel orphelin que superpowers ne couvre pas : les heuristiques de design (`deep-modules`, `interface-design`, `refactoring`) passent dans `domain-modeling` ; `hitl-loop.template.sh` passe dans `less-trouble`.
- **Abandonner le routeur Claude Code** (`global-config/user-CLAUDE.md`) : Cursor est le seul harnais utilisé.

## Consequences

- Les skills vendorés se déclenchent moins sûrement que sous le hook upstream, puisque rien n'impose leur invocation. C'est le prix assumé de la souveraineté des rules ; le paragraphe « Skill-first » est le contrepoids, et son efficacité réelle reste à observer.
- Le catalogue passait de 11 skills maintenus à 8 au moment de l'ADR ; voir [ADR 0004](./0004-agent-skills-copy-install.md) pour le passage à 7 et le mécanisme d'install par copie.
- `~/.cursor/vendor/` n'est pas versionné : une machine neuve dépend de `ai/install-skills.sh` (historiquement `install-symlinks.sh`) et du réseau, pas seulement d'un `git clone` du workspace.
- La version de superpowers n'est pas épinglée : **`git pull` dans vendor puis reinstall est voulu** — la dérive upstream est un choix, pas un oubli. Épingler un tag reste possible si un release casse un workflow.
- `grill-me` et `brainstorming` se disputent des déclencheurs voisins. Le routeur tranche explicitement en faveur de `grill-me` pour les arbitrages.
- Deux idées d'everything-claude-code restent en réserve, faute d'équivalent : `memory-persistence` et `strategic-compact`, qui couvrent la continuité entre sessions.

## Alternatives rejected

- **Vendorer superpowers dans `ai/`** pour réécrire ton et chemins : 15 skills de plus à maintenir et divergence à chaque release upstream.
- **Garder le catalogue maison comme socle** et ne voler que des idées : cohérence maximale, mais coût de maintien maximal et améliorations upstream perdues.
- **Enregistrer le plugin avec ses hooks** : déclenchement fiable des skills, mais les rules maison deviennent décoratives.
- **Prendre les deux collections avec arbitrage skill par skill** : la collision réelle se limite à TDD, vérification et code review ; après superpowers il ne reste d'ECC que des idées, pas des fichiers.
