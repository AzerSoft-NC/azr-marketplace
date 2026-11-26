# Global Config Templates

Pointer and legacy filename for the Cursor router.

| File | Role |
|------|------|
| [user-CURSOR.md](./user-CURSOR.md) | Points at [../rules/skill-router.mdc](../rules/skill-router.mdc) — **not** pasted into User Rules |

Cursor is the only target for now ([ADR 0021](../../context/adr/0021-skills-cli-published-pack.md)).

## Router source of truth

- **Installed:** `~/.cursor/rules/skill-router.mdc` (from [install-rules.sh](../install-rules.sh))
- **Catalog:** [../rules/skill-router.mdc](../rules/skill-router.mdc)

## Skills

Consumers: `npx skills add AzerSoft-NC/azr-marketplace -g -a cursor` then `npx skills update -g`.

Maintainers: [../sync-vendors.sh](../sync-vendors.sh) → Published pack under [`../../skills/`](../../skills/). Pins in [`../vendor-config.sh`](../vendor-config.sh).
