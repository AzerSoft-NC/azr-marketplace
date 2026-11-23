# Agent Skills & Rules

> **Author:** kako  
> **Last updated:** November 2026  
> **Purpose:** Versioned catalog of Cursor skills and always-on rules — source of truth under `ai/`, installed globally via `install-skills.sh`.

Portable agent skill definitions and rules. Skills make agent behavior **predictable and repeatable**: same process every run, not necessarily the same output.

**Language:** English is the default for all skills, rules, and templates in this catalog.

## Install (Cursor personal)

From the workspace root:

```bash
ai/install-skills.sh
```

Copies house catalog skills (categories `engineering`, `productivity`, `misc` only — never `deprecated/`), pinned Matt + Superpowers + SkillSpector skills, and always-on rules into `~/.cursor/`. Re-run after editing the catalog or after bumping a vendor pin in [`ai/vendor-config.sh`](../ai/vendor-config.sh).

| Tool | Personal | Project |
|------|----------|---------|
| Cursor | `~/.cursor/skills/` + `~/.cursor/rules/` | `.cursor/skills/` + `.cursor/rules/` |

**Router:** the always-on rule [skill-router.mdc](../ai/rules/skill-router.mdc) is installed by the script — nothing to paste into Cursor User Rules. [global-config/user-CURSOR.md](../ai/global-config/user-CURSOR.md) is a pointer only.

**Hybrid (ADR 0020):** Matt owns orchestration / domain / `code-review`. Superpowers owns TDD + debug (+ plans, writing-skills, worktrees, verification). Layout stays `CONTEXT.md` + `context/adr/` + `.cursor/handoffs|plans`. Caveman stays default. No Matt/Superpowers plugins; `using-superpowers` is never installed.

---

## Vendor bumps (stay in sync with upstream)

**No silent `git pull`.** Each upstream is a **pinned SHA** in [`ai/vendor-config.sh`](../ai/vendor-config.sh). Detect lag with the drift script; absorb changes in a **reviewed catalog PR**.

| Vendor | Constant | Clone |
|--------|----------|--------|
| Superpowers | `SUPERPOWERS_REF` | `~/.cursor/vendor/superpowers` |
| Matt | `MATT_REF` | `~/.cursor/vendor/mattpocock-skills` |
| SkillSpector | `SKILLSPECTOR_REF` | `~/.cursor/vendor/skillspector` |

### Drift check

```bash
ai/scripts/check-vendor-drift.sh
```

- Exit `0` — pins cover allowlisted paths (in sync)
- Exit `1` — commits on allowlisted skills and/or **NEW** upstream skills outside allowlist/exclude (decide add vs ignore)
- Exit `2` — pin missing after fetch

Matt is checked only on the **allowlist**. Superpowers is checked on every installed skill (everything except the **denylist**). Pins bump **independently**.

Optional CI: [`.github/workflows/vendor-drift.yml`](../.github/workflows/vendor-drift.yml) (weekly cron) fails the job on drift — it does **not** auto-bump pins.

### Bump checklist (catalog PR)

1. Run `ai/scripts/check-vendor-drift.sh` — paste the log into the PR
2. Choose candidate SHA (often `origin/main` or a release tag)
3. `git -C ~/.cursor/vendor/<name> diff $PIN..$NEW -- <allowlisted paths>` — read skill by skill
4. If upstream renamed glossary/ADR paths or Skill call strings (`tdd`, `diagnosing-bugs`) — update `patch_*` in [`ai/install-skills.sh`](../ai/install-skills.sh)
5. Run `skill-inspector` / `skillspector` on changed skill folders
6. Update the `*_REF` in `ai/vendor-config.sh`
7. Run `ai/install-skills.sh` and confirm assertions:
   - installed `domain-modeling` writes `CONTEXT.md` (not `GLOSSARY.md`)
   - Matt `implement` calls `test-driven-development`
   - `using-superpowers` absent; `caveman-default.mdc` present; `teach-me` / `teach` absent
8. Merge — each machine re-runs `ai/install-skills.sh` to pick up the new pin

### What “in sync” does not mean

- Not installing Matt/Superpowers **plugins** (hooks fight caveman + architecture-forks)
- Not tracking Matt `in-progress/` or `misc/`
- Not auto-allowlisting new upstream skills — drift **signals**; allowlist **accepts**
- Not using `npx skills update` / marketplace auto-update

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

`everything-claude-code` was evaluated and rejected (see [ADR 0002](../context/adr/0002-agent-skills-vendoring.md)). CAFAT-only skills are omitted. House `teach-me` and fused house `grill-me` are deprecated (ADR 0020).
