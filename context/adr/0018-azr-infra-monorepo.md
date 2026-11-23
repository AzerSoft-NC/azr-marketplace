# ADR 0018 — Monorepo `azr-infra` (fold ci / ai / pg / mail)

## Status

Accepted

## Context

[ADR 0007](0007-nested-ci-ai-remotes.md) split `ci/` (`azr-ci`) and `ai/` (`azr-ai`) out of the umbrella as nested remotes, matching `services/azr-*`. For a small ops footprint that layout is overkill: clone friction, duplicate remotes, and docs that talk about an “umbrella” that owns almost nothing. Edge Compose (`azr-nginx`) is already superseded by Traefik Ingress ([ADR 0017](0017-traefik-ingress-controller.md)).

Fork: keep nested remotes; create a fresh `azr-infra` repo; or **rename `azr-workspace` → `azr-infra` and absorb platform trees**. Chose rename + absorb.

## Decision

- GitHub repo **`azr-workspace` is renamed to `azr-infra`** (history preserved).
- In-tree (tracked by this git): `ci/` (ex-`azr-ci`), `ai/` (ex-`azr-ai`), `services/azr-pg/` (ex-`azr-pg`), `services/azr-mailer/` (ex-`azr-mailer`).
- Shared brick helpers live under **`services/`** (not `infra/` — that name collides with the repo / glossary **Infra**). Charts stay in `ci/k3s/charts/platform`.
- **Do not** absorb `azr-nginx` — removed; edge is Traefik in-cluster ([ADR 0017](0017-traefik-ingress-controller.md)).
- Product apps under `src/<client>/<app>/` stay **nested remotes** (gitignored).
- Reusable / publish GHA live at **repo-root** `.github/workflows/` (mailer path-filtered).
- Snapshot/tree copy into this history (no `filter-repo` of old remotes).

## Consequences

- One clone of `azr-infra` has docs, orchestration, agent catalog, pg helpers, and mailer source.
- Archive GitHub remotes `azr-ci`, `azr-ai`, `azr-pg`, `azr-mailer` after fold lands; point README at `azr-infra`.
- App workflows that `uses: AzerSoft-NC/azr-ci/...` must switch to `AzerSoft-NC/azr-infra/...` (or the renamed path).
- Traefik chart work ([ADR 0017](0017-traefik-ingress-controller.md)) happens in `ci/` of this repo, not a nested remote.
- [ADR 0007](0007-nested-ci-ai-remotes.md) is **Superseded**.

## Alternatives rejected

- **Keep nested remotes** — rejected: too many projects for current scale.
- **New empty `azr-infra` + archive umbrella** — rejected: lose umbrella history / Cursor links; rename is enough.
- **Absorb product apps into the monorepo** — rejected: apps keep independent remotes and deploy lifecycles.
