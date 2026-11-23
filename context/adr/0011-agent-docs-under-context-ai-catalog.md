# ADR 0011 — Agent docs under `context/` (AzerSoft ai catalog)

## Status

Accepted for **install-time patches** and **`context/specs/`**. Handoff/plan *paths* superseded by [ADR 0015](./0015-cursor-handoffs-plans.md) (`.cursor/handoffs`, `.cursor/plans`).

(Amends the no-local-edits vendor rule in [ADR 0002](./0002-agent-skills-vendoring.md) for install-time patches on copied skills only.)

## Context

The CAFAT `ai-skills` catalog standardized agent-facing paths: plans under `context/plans/`, design specs under `context/specs/`, handoffs under `context/handoffs/`, with human docs staying under `docs/`. Upstream superpowers still defaults to `docs/superpowers/plans/` and `docs/superpowers/specs/` in skill text.

The AzerSoft workspace already uses umbrella `context/` for ADRs and architecture graph; nested app repos follow the same pattern. House skills `handoff`, `grill-me`, and the always-on `skill-router` rule should agree on those paths.

ADR 0002 forbade editing the vendor clone so the diff against upstream stays empty. Patching **after copy** into `~/.cursor/skills/` preserves an pristine vendor git tree while aligning installed behavior with workspace conventions.

## Decision

- **House skills and rules** in `ai/` write and route to `context/plans/`, `context/specs/`, and `context/handoffs/` (never `.cursor/handoffs/` or OS temp for handoffs).
- **`install-skills.sh`** applies idempotent `sed` patches to the **installed** copies of `writing-plans` and `brainstorming` only, rewriting default paths to `context/plans/` and `context/specs/`.
- Do not patch files inside `~/.cursor/vendor/superpowers`.

## Consequences

- Re-run `ai/install-skills.sh` after changing patch logic or reinstalling superpowers skills.
- Installed superpowers skills differ from upstream text for those two path strings; vendor clone remains untouched.
- `init-repo` templates may scaffold `context/plans/`, `context/specs/`, `context/handoffs/` when extended; not required for this ADR alone.

## Alternatives rejected

- **Fork superpowers in-repo** — high maintenance.
- **Router-only override without patching** — agents still read stale paths inside vendored SKILL.md bodies when loaded.
