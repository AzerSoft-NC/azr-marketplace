# Agent Skills & Rules

> **Author:** kako  
> **Last updated:** November 2026  
> **Purpose:** Published Cursor skills pack under `skills/` plus always-on rules — consumers use Skills CLI + `install-rules.sh` ([ADR 0021](../context/adr/0021-skills-cli-published-pack.md)).

Portable agent skill definitions and rules. Skills make agent behavior **predictable and repeatable**: same process every run, not necessarily the same output.

**Language:** English is the default for all skills, rules, and templates in this catalog.

## Install (Cursor, global)

```bash
npx skills add AzerSoft-NC/azr-marketplace -g -a cursor
npx skills update -g
ai/install-rules.sh    # from a clone; Skills CLI does not install .mdc
```

| Tool | Global (`-g`) | Project |
|------|---------------|---------|
| Cursor skills | `~/.cursor/skills/` | `.agents/skills/` (CLI default; not our recommended path) |
| Cursor rules | `~/.cursor/rules/` via `ai/install-rules.sh` | — |

**Router:** [skill-router.mdc](../ai/rules/skill-router.mdc) via Rules install — nothing to paste into Cursor User Rules. [global-config/user-CURSOR.md](../ai/global-config/user-CURSOR.md) is a pointer only.

**Hybrid (ADR 0021):** Matt owns orchestration / domain / `code-review`. Superpowers owns TDD + debug (+ plans, writing-skills, worktrees, verification). Layout stays `CONTEXT.md` + `context/adr/` + `.cursor/handoffs|plans`. Caveman stays default. No Matt/Superpowers plugins; `using-superpowers` is never in the pack. **Cursor only** for now.

---

## Vendor bumps (publisher)

**No silent pin bump.** Pins in [`ai/vendor-config.sh`](../ai/vendor-config.sh). Drift alerts; absorb via reviewed PR that rewrites [`skills/`](../skills/).

| Vendor | Constant | Publisher clone |
|--------|----------|-----------------|
| Superpowers | `SUPERPOWERS_REF` | `ai/.vendor/superpowers` |
| Matt | `MATT_REF` | `ai/.vendor/mattpocock-skills` |
| SkillSpector | `SKILLSPECTOR_REF` | `ai/.vendor/skillspector` |

### Drift check

```bash
ai/scripts/check-vendor-drift.sh
```

- Exit `0` — pins cover allowlisted paths (in sync)
- Exit `1` — commits on allowlisted skills and/or **NEW** upstream skills outside allowlist/exclude
- Exit `2` — pin missing after fetch

Optional CI: [`.github/workflows/vendor-drift.yml`](../.github/workflows/vendor-drift.yml) — **does not** auto-bump.

### Bump checklist (catalog PR)

1. Run `ai/scripts/check-vendor-drift.sh` — paste the log into the PR
2. Choose candidate SHA
3. Diff pin→new on allowlisted paths under `ai/.vendor/<name>`
4. If upstream renamed glossary/ADR paths or Skill call strings — update `patch_*` in [`ai/sync-vendors.sh`](../ai/sync-vendors.sh)
5. Update `*_REF` in `ai/vendor-config.sh`
6. Run `ai/sync-vendors.sh` and confirm pack assertions (CONTEXT.md, implement→TDD, no `using-superpowers`, no teach-me)
7. Commit `skills/` + pin; merge — consumers `npx skills update -g` (+ rules script if rules changed)

### What “in sync” does not mean

- Not installing Matt/Superpowers **plugins**
- Not tracking Matt `in-progress/` or `misc/`
- Not auto-allowlisting new upstream skills
- Not a background daemon — `npx skills update` is on-demand

---

## Reference

Skills split on **who can invoke them**. **User-invoked** skills fire only when you type them (e.g. `/commit`). **Model-invoked** skills can be invoked by you _or_ reached automatically when the task fits.

### [Engineering](../ai/skills/engineering/README.md) (house)

**User-invoked**

- **[commit](../ai/skills/engineering/commit/SKILL.md)** — Draft commit message (hybrid format) and commit after approval. `/commit`.

**Model-invoked**

- **[contract-first](../ai/skills/engineering/contract-first/SKILL.md)** — One authoritative contract per API or event boundary (OpenAPI, AsyncAPI, JSON Schema); consumer-first workflow and verification.

### [Productivity](../ai/skills/productivity/README.md) (house)

**User-invoked**

- **[handoff](../ai/skills/productivity/handoff/SKILL.md)** — Compact the conversation into a handoff document (`.cursor/handoffs/`).

**Model-invoked**

- **[caveman](../ai/skills/productivity/caveman/SKILL.md)** — Ultra-compressed communication (levels: lite, full, ultra, wenyan-*).
- **[less-trouble](../ai/skills/productivity/less-trouble/SKILL.md)** — Capture resolved env bugs into `docs/troubleshoot/TROUBLESHOOT.md`.
- **[map-architecture](../ai/skills/productivity/map-architecture/SKILL.md)** — Maintain curated `context/architecture-graph.json`.

### [Misc](../ai/skills/misc/README.md)

- **[init-repo](../ai/skills/misc/init-repo/SKILL.md)** — Standardise repo docs (user-invoked `/init-repo`).

### Rules (always-on)

| Rule | Role |
|------|------|
| [skill-router.mdc](../ai/rules/skill-router.mdc) | Philosophy, skill map, knowledge capture |
| [no-read-secrets.mdc](../ai/rules/no-read-secrets.mdc) | Block secret **files** + never echo secret **values** |
| [architecture-forks.mdc](../ai/rules/architecture-forks.mdc) | Architecture trade-offs → load `grill-with-docs` |
| [caveman-default.mdc](../ai/rules/caveman-default.mdc) | Caveman **full** on by default |
| [architecture-graph.mdc](../ai/rules/architecture-graph.mdc) | Read curated `context/architecture-graph.json` before broad workspace exploration |
| [clean-code.mdc](../ai/rules/clean-code.mdc) | Clean code within the requested change only |

---

## Vendored upstream skills

Pins and allow/deny lists: [`ai/vendor-config.sh`](../ai/vendor-config.sh). Installer: [`ai/install-skills.sh`](../ai/install-skills.sh).

### Matt (orchestration — allowlist)

| Need | Skill |
|------|-------|
| Architecture fork / domain + docs | `grill-with-docs` (`grilling` + `domain-modeling`) |
| Flow router | `ask-matt` |
| Spec / tickets / implement | `to-spec`, `to-tickets`, `implement`, `implement-spec` |
| Review (Standards ∥ Spec) | `code-review` |
| Deep modules | `codebase-design`, `improve-codebase-architecture` |
| Setup tracker / labels / doc layout | `setup-matt-pocock-skills` |
| Other | `wayfinder`, `triage`, `prototype`, `research`, `wizard`, `wait-what`, `retro`, `pr`, `grill-me` |

**Not installed from Matt:** `tdd`, `diagnosing-bugs`, `teach`, `handoff`, `writing-for-agents`, `to-questionnaire`.

Install-time patches: `GLOSSARY.md` → `CONTEXT.md`, `docs/adr/` → `context/adr/`; Skill calls `tdd` → `test-driven-development`, `diagnosing-bugs` → `systematic-debugging`; overlays under [`ai/overlays/domain-modeling/`](../ai/overlays/domain-modeling/).

### Superpowers (execution — denylist)

| Need | Skill |
|------|-------|
| Bug / unexpected behavior | `systematic-debugging` |
| Test-first | `test-driven-development` |
| Write or edit a skill | `writing-skills` |
| File-based plans | `writing-plans`, `executing-plans`, `subagent-driven-development` |
| Receiving review feedback | `receiving-code-review` |
| Claim work is done | `verification-before-completion` |
| Isolation / parallelism / branch close | `using-git-worktrees`, `dispatching-parallel-agents`, `finishing-a-development-branch` |
| Skill safety scan | `skill-inspector` (SkillSpector) |

**Not installed from Superpowers:** `using-superpowers`, `requesting-code-review`, `brainstorming`.

### Not installed

`everything-claude-code` was evaluated and rejected (see [ADR 0002](../context/adr/0002-agent-skills-vendoring.md)). CAFAT-only skills are omitted. House `teach-me` and fused house `grill-me` are deprecated (ADR 0021 / archived 0020).
