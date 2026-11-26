# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Initial import of the AzerSoft Cursor skills marketplace from [`azr-infra`](https://github.com/AzerSoft-NC/azr-infra) `ai/` (house skills, rules, overlays, install + drift scripts, vendor pins)
- Catalog docs (`docs/ai-catalog.md`), skills ADRs (0002, 0004, 0010, 0011, 0015, 0020) and provenance ADRs (0007, 0018)
- Weekly `vendor-drift` GitHub Actions workflow (alert only, no auto-bump)
- Repo scaffolding: glossary, architecture hub, changelog, `.gitignore`
- [ADR 0021](context/adr/0021-skills-cli-published-pack.md) — Skills CLI consumer + committed Published pack under `skills/`
- Publisher `ai/sync-vendors.sh`, consumer `ai/install-rules.sh`, flat pack `skills/` (41 skills)

### Changed

- Consumer install: `npx skills add/update -g -a cursor` (+ rules script) instead of `ai/install-skills.sh`
- ADR 0020 archived (superseded by 0021); hybrid ownership kept
- Drift script default vendor dir → `ai/.vendor/`

### Fixed
