# azr-marketplace

AzerSoft Cursor skills marketplace: a published pack of house skills plus vendored Matt Pocock (orchestration) and Superpowers (execution), installed with the Skills CLI.

## Language

**Published pack**:
The committed skill folders under `skills/` that consumers install from this repository. Includes house skills and the patched Matt / Superpowers hybrid; never `deprecated/`.
_Avoid_: Live vendor clone as what consumers install, `ai/skills` as the install root

**Skills CLI**:
The `npx skills` tool consumers use to add and update the Published pack into Cursor (`npx skills add` / `npx skills update`, global `-g`). On-demand update, not a silent background refresh.
_Avoid_: `ai/install-skills.sh` as the consumer path, marketplace daemon auto-update, unreviewed silent pin bump

**Rules install**:
A separate step that copies Cursor always-on rules (`.mdc`) after the Skills CLI install. Skills CLI does not install rules.
_Avoid_: Embedding always-on rules only inside skill bodies, assuming `npx skills` installs `.mdc`

**Publisher sync**:
Maintainer process that refreshes vendor pins, applies hybrid patches, and writes the Published pack. Consumers never run this.
_Avoid_: Consumer `git pull` of vendor remotes, treating publisher scripts as the install UX

**Vendor pin**:
A reviewed git SHA in `ai/vendor-config.sh` (`MATT_REF`, `SUPERPOWERS_REF`, `SKILLSPECTOR_REF`) used only by Publisher sync. Bumps land as catalog PRs that rewrite the Published pack.
_Avoid_: Unpinned vendor HEAD as consumer source of truth

**Skill allowlist**:
The Matt skill paths included in the Published pack (orchestration / domain / review). Skills outside the allowlist stay out until explicitly added or listed in `MATT_EXCLUDE`. Superpowers uses a denylist instead (`using-superpowers`, `brainstorming`, `requesting-code-review`).
_Avoid_: Installing the full upstream catalogs, plugin hooks

**House skill**:
A skill authored in this repository and shipped in the Published pack. Distinct from vendored Matt / Superpowers skills that Publisher sync copies in.
_Avoid_: Treating vendored upstream skills as house-owned

**Hybrid (Matt + Superpowers)**:
Pack composition from ADR 0021 (was 0020): Matt owns orchestration / domain / `code-review`; Superpowers owns TDD and debug. No plugins; caveman stays always-on via Rules install. Target harness for now: **Cursor only**.
_Avoid_: Full Matt execution stack, full Superpowers plugin hooks, Claude Code as a current install target
