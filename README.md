# azr-marketplace

AzerSoft Cursor skills marketplace: committed **Published pack** under [`skills/`](skills/) (house + patched Matt Pocock / Superpowers hybrid). Consumers use the Skills CLI; maintainers refresh the pack with publisher scripts.

See [ADR 0021](context/adr/0021-skills-cli-published-pack.md).

## Install (Cursor, global)

```bash
npx skills add AzerSoft-NC/azr-marketplace -g -a cursor
npx skills update -g
# from a clone of this repo (rules are not installed by the Skills CLI):
ai/install-rules.sh
```

Update later: `npx skills update -g` then re-run `ai/install-rules.sh` if rules changed.

## Maintainers (publisher)

Pins live in [`ai/vendor-config.sh`](ai/vendor-config.sh). Refresh the Published pack:

```bash
ai/sync-vendors.sh
# review diff under skills/, commit, PR
ai/scripts/check-vendor-drift.sh   # alert only — no auto-bump
```

House skill sources stay under `ai/skills/{engineering,productivity,misc}/` and are copied into `skills/` by sync. Do not edit vendored copies in `skills/` by hand — re-run sync after pin bumps.

Retired: `ai/install-skills.sh` (exits with migration help).

## Documentation

- [Catalog reference](docs/ai-catalog.md)
- [Architecture](docs/architecture.md)
- [Glossary](CONTEXT.md)
- [Changelog](CHANGELOG.md)
- ADRs under [`context/adr/`](context/adr/)
