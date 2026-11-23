# azr-marketplace

AzerSoft Cursor skills marketplace: house catalog plus a pinned hybrid of [Matt Pocock skills](https://github.com/mattpocock/skills) (orchestration / domain / review) and [Superpowers](https://github.com/obra/superpowers) (TDD / debug / plans).

Source of truth for installable skills and always-on rules. Extracted from the `ai/` tree previously folded into [`azr-infra`](https://github.com/AzerSoft-NC/azr-infra) (ADR 0018 → this dedicated repo).

## Install

```bash
ai/install-skills.sh
```

Copies house skills (`engineering`, `productivity`, `misc`), pinned Matt + Superpowers + SkillSpector skills, and rules into `~/.cursor/`. Re-run after catalog edits or vendor pin bumps in `ai/vendor-config.sh`.

## Vendor pins

No silent `git pull` / marketplace auto-update. Pins live in [`ai/vendor-config.sh`](ai/vendor-config.sh). Drift check:

```bash
ai/scripts/check-vendor-drift.sh
```

Weekly CI: [`.github/workflows/vendor-drift.yml`](.github/workflows/vendor-drift.yml) (alert only, no auto-bump).

## Documentation

- [Catalog reference](docs/ai-catalog.md) — skill index, bump checklist, hybrid rules
- [Architecture](docs/architecture.md)
- [Glossary](CONTEXT.md)
- [Changelog](CHANGELOG.md)
- ADRs under [`context/adr/`](context/adr/) (0002, 0004, 0010, 0011, 0015, 0020 + history 0007 / 0018)
