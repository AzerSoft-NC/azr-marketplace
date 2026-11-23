# Architecture

## Stack

- Bash installers (`ai/install-skills.sh`, `ai/scripts/check-vendor-drift.sh`)
- Pinned git vendors: Matt Pocock skills, obra/superpowers, NVIDIA SkillSpector (`ai/vendor-config.sh`)
- Cursor personal install target: `~/.cursor/skills/` + `~/.cursor/rules/` + `~/.cursor/vendor/`
- CI: GitHub Actions `vendor-drift` (ubuntu-latest, weekly cron)

No application runtime (Node/Java). This repo is a skills/rules catalog only.

## Structure

```text
ai/
  install-skills.sh
  vendor-config.sh
  rules/
  skills/{engineering,productivity,misc,deprecated}/
  overlays/domain-modeling/
  scripts/check-vendor-drift.sh
  global-config/
context/adr/
docs/
.github/workflows/vendor-drift.yml
```

## Also read

- [Glossary](../CONTEXT.md)
- [Changelog](../CHANGELOG.md)
- [Catalog reference](ai-catalog.md)
- [ADR 0020 — Matt + Superpowers hybrid](../context/adr/0020-matt-superpowers-hybrid.md)
