# ADR 0020 — Matt orchestration + Superpowers execution (pinned hybrid)

## Status

Accepted (amends [0002](./0002-agent-skills-vendoring.md), [0010](./0010-pinned-vendors-skill-inspector.md), [0011](./0011-agent-docs-under-context-ai-catalog.md)).

## Context

The house catalog already followed Matt Pocock’s domain/grill lineage (`CONTEXT.md`, ADRs) while vendoring [superpowers](https://github.com/obra/superpowers) for TDD, debugging, and skill authoring. Upstream [mattpocock/skills](https://github.com/mattpocock/skills) now owns a full idea→ship flow (`grill-with-docs` → `to-spec` → `to-tickets` → `implement` → `code-review`). Installing both catalogs wholesale collides on TDD, debug, review, and hooks (`using-superpowers` vs `caveman-default` / `architecture-forks`).

## Decision

- **Orchestration and domain** come from Matt, pinned as `MATT_REF` in [`ai/vendor-config.sh`](../../ai/vendor-config.sh), installed by **allowlist** only.
- **TDD and debug** stay Superpowers (`test-driven-development`, `systematic-debugging`). Matt `tdd` and `diagnosing-bugs` are **not** installed; install-time patches rewrite Matt Skill calls to the Superpowers names.
- **Code review product** is Matt `code-review`. Superpowers `requesting-code-review` is denylisted. `brainstorming` is denylisted so it cannot race `grill-with-docs` / `architecture-forks`.
- **Layout sovereignty:** patches rewrite Matt `GLOSSARY.md` / `docs/adr/` to `CONTEXT.md` / `context/adr/`; house overlays supply layered-glossary + ADR-archive rules. House `handoff` wins (`.cursor/handoffs/`); Matt `handoff` is excluded.
- **No plugins** for Matt or Superpowers; never install `using-superpowers`. Caveman stays always-on.
- **Drop** house `teach-me` and the fused house `grill-me` (moved to `ai/skills/deprecated/`). Do not install Matt `teach`.
- **Update model:** pinned SHAs; [`ai/scripts/check-vendor-drift.sh`](../../ai/scripts/check-vendor-drift.sh) reports allowlist-scoped drift; bumps are reviewed catalog PRs (no silent `git pull`). Pins for Matt and Superpowers bump independently.

## Consequences

- Agents follow Matt’s flow with house paths and Superpowers execution depth.
- New upstream skills appear as drift “NEW skill” warnings until allowlisted or excluded.
- Patch functions in `install-skills.sh` must be re-validated on every bump.

## Alternatives rejected

- Full Matt execution (tdd/debug) — loses Superpowers depth already chosen in ADR 0002.
- Hybrid call rewrites avoided by renaming Superpowers skills to Matt names — forks Superpowers away from upstream.
- skills.sh / marketplace auto-update — conflicts with pin + review model.
