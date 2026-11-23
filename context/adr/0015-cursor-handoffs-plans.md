# Agent session artifacts under `.cursor/` (handoffs + plans)

Handoffs and implementation plans are **per Cursor workspace root** (the folder open in the IDE), not under shared `context/`. Save to `<workspace>/.cursor/handoffs/YYYY-MM-DD-<topic>.md` and `<workspace>/.cursor/plans/YYYY-MM-DD-<feature>.md`. Nested remotes opened alone (`ci/`, an app) get their own `.cursor/` tree. Design specs from brainstorming stay under `context/specs/`. ADRs and glossary stay under `context/`.

This supersedes the handoff/plan path decision in [ADR 0011](0011-agent-docs-under-context-ai-catalog.md) (that ADR remains for install-time patches and `context/specs/`).

## Considered Options

- **`.cursor/handoffs` + `.cursor/plans` per workspace** (retenu) — isolé par projet ouvert ; aligné usage historique workspace.
- **`context/handoffs` + `context/plans`** (ADR 0011) — versionnés avec ADRs ; mélange session jetable et vérité partagée.
- **OS temp / chat only** — pas de reprise fiable.

## Consequences

- House skill `handoff` and `install-skills.sh` patches for `writing-plans` target `.cursor/…`.
- `skill-router` Knowledge Capture updated; do **not** write new handoffs/plans under `context/handoffs` or `context/plans`.
- `.gitignore` ignores both `.cursor/plans/` and `.cursor/handoffs/` (ephemeral session artifacts; `init-repo` gitignore-core).
- Re-run `ai/install-skills.sh` after changing patch targets.
