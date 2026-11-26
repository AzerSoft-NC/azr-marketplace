# ADR 0021 — Skills CLI published pack (Cursor)

Consumers install and update this marketplace with `npx skills add` / `npx skills update` (`-g`, Cursor only for now). The repo commits a flat **Published pack** under `skills/` (house + patched Matt/Superpowers hybrid). Vendor pins stay maintainer-only via `ai/sync-vendors.sh`; Cursor rules install separately with `ai/install-rules.sh`. Supersedes [ADR 0020](./0020-matt-superpowers-hybrid_ARCHIVED.md) (hybrid ownership kept; consumer pin+`install-skills.sh` update model replaced).

## Hybrid pack (unchanged ownership)

- Matt: orchestration / domain / `code-review` (allowlist). Superpowers: TDD / debug (denylist excludes `using-superpowers`, `brainstorming`, `requesting-code-review`).
- Layout patches: `CONTEXT.md` / `context/adr/`; Skill calls `tdd` → `test-driven-development`, `diagnosing-bugs` → `systematic-debugging`.
- No Matt/Superpowers plugins. Caveman always-on via Rules install, not the Skills CLI.

## Consumer vs publisher

- **Consumer:** `npx skills add AzerSoft-NC/azr-marketplace -g -a cursor` then `npx skills update -g`; then `ai/install-rules.sh`.
- **Publisher:** bump pins in `ai/vendor-config.sh`, run `ai/sync-vendors.sh`, commit `skills/`, PR. Drift CI alerts; no silent bump.

## Considered options

- Pin + `install-skills.sh` only — rejected; user wants Skills CLI update UX.
- House-only pack + separate upstream `npx skills add` for Matt/Superpowers — rejected; loses hybrid patches and single-add UX.
- Project-scoped install as default — rejected; global `-g` for AzerSoft machines.
- Multi-agent (`claude-code`) in the same tranche — deferred; Cursor only for now.
