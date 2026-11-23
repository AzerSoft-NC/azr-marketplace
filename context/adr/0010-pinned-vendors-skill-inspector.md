# ADR 0010 — Pinned vendor refs and SkillSpector

## Status

Accepted (amends unpinned vendor drift in [ADR 0002](./0002-agent-skills-vendoring.md) and the skill-count note in [ADR 0004](./0004-agent-skills-copy-install.md)).

## Context

ADR 0002 chose to clone superpowers under `~/.cursor/vendor/` and refresh with unpinned `git pull`, keeping the vendor tree unedited and pushing behavior changes into house `rules/`. That worked until the upstream `ai-skills` catalog showed a repeatable bump process: pin each vendor to a reviewed commit, re-read the diff on bump, and scan skills with NVIDIA [SkillSpector](https://github.com/NVIDIA/SkillSpector) before merging a pin change.

SkillSpector adds `skill-inspector` (static review) and an optional `skillspector` CLI installed via `uv`. The AzerSoft `ai/` catalog is Cursor-only and omits CAFAT-only vendors (e.g. Google's `angular-developer`).

## Decision

- Pin **superpowers** and **skillspector** in `ai/install-skills.sh` (`SUPERPOWERS_REF`, `SKILLSPECTOR_REF`); `ensure_vendor_repo` checks out detached HEAD at the pin.
- Install vendored **`skill-inspector`** alongside superpowers skills; attempt **`uv tool install`** for the CLI when `uv` is available (warn-only if missing).
- A vendor bump is a catalog PR: read upstream changes, run `skill-inspector` / `skillspector` on affected skills, then update the pin constant.

## Consequences

- Machines need network on install to fetch pinned commits; vendor dir remains under `~/.cursor/vendor/`, not tracked in git.
- Unpinned drift is no longer intentional — stale pins are a maintenance task, not silent auto-update.
- Skill count grows by one catalog-visible vendor skill (`skill-inspector`).

## Alternatives rejected

- **Keep unpinned superpowers only** — simpler, but upstream skill changes land without review.
- **Vendor superpowers inside `ai/`** — same rejection as ADR 0002; pins stay in the installer against remote clones.
