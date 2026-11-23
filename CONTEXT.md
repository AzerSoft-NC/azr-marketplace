# azr-marketplace

AzerSoft Cursor skills marketplace: house catalog plus pinned Matt Pocock (orchestration) and Superpowers (execution) skills.

## Language

**Agent catalog**:
Cursor skills and rules under `ai/`, installed onto machines via `ai/install-skills.sh`. This repository is the standalone home of that catalog (formerly nested remote `azr-ai`, then folded into `azr-infra` under ADR 0018).
_Avoid_: AI tools, calling this repo azr-infra, marketplace auto-update as the update model

**Vendor pin**:
A reviewed git SHA in `ai/vendor-config.sh` (`MATT_REF`, `SUPERPOWERS_REF`, `SKILLSPECTOR_REF`) that `install-skills.sh` checks out under `~/.cursor/vendor/`. Drift is detected by `ai/scripts/check-vendor-drift.sh`; bumps are catalog PRs, never silent `git pull`.
_Avoid_: Unpinned vendor HEAD, marketplace auto-update, skills.sh live copy as source of truth

**Skill allowlist**:
The Matt skill paths installed from the pin (orchestration / domain / review). Skills outside the allowlist are ignored until explicitly added or listed in `MATT_EXCLUDE`. Superpowers uses a denylist instead (`using-superpowers`, `brainstorming`, `requesting-code-review`).
_Avoid_: Installing the full upstream catalogs, plugin hooks

**House skill**:
A skill authored and versioned in this repo under `ai/skills/{engineering,productivity,misc}/` (never `deprecated/` for install). Distinct from vendored Matt/Superpowers skills.
_Avoid_: Treating vendored upstream skills as house-owned

**Hybrid (Matt + Superpowers)**:
Install model from ADR 0020: Matt owns orchestration / domain / `code-review`; Superpowers owns TDD and debug. No plugins; caveman stays always-on.
_Avoid_: Full Matt execution stack, full Superpowers plugin hooks
