# ADR 0007 — Nested remotes for `ci/` (`azr-ci`) and `ai/` (`azr-ai`)

## Status

**Superseded** — [ADR 0018](0018-azr-infra-monorepo.md) folds `ci/`, `ai/`, `services/azr-pg`, and `services/azr-mailer` back into `azr-infra` (renamed from `azr-workspace`).

## Context

`ci/` (Terraform, Ansible, Helm, justfile, GHA) and `ai/` (Cursor skills/rules) lived as umbrella-tracked trees inside `azr-workspace`. Infra services and product apps already use nested remotes under `infra/` and `src/`. Keeping CI and the agent catalog in the umbrella blocked independent publish/CI history and mixed orchestration with docs/context.

Fork: remotes-only init, full nested split (fresh history), or history-preserving filter. Chose full nested split to match `infra/azr-*`.

## Decision

- `ci/` is nested remote **`azr-ci`** (`git@github.com:AzerSoft-NC/azr-ci.git`).
- `ai/` is nested remote **`azr-ai`** (`git@github.com:AzerSoft-NC/azr-ai.git`).
- Umbrella gitignores `ci/` and `ai/` (same pattern as `infra/azr-*` / `src/*/*/`).
- Fresh root commits on each remote (no `filter-repo` from umbrella history).

## Consequences

- Clone of `azr-workspace` alone no longer contains CI charts or skills; checkout nested remotes (or keep local trees) for day-to-day work.
- Reusable GHA under `ci/.github/workflows/` can live at the `azr-ci` repo root as expected by GitHub.
- Umbrella keeps `docs/`, `context/`, `CONTEXT.md`, and orchestration narrative; paths `ci/` and `ai/` remain the on-disk layout.
- Prior umbrella history for those trees stays only in `azr-workspace` commits (not rewritten into the new remotes).

## Alternatives rejected

- **Remotes only (nested `.git`, still umbrella-tracked)** — nested-repo confusion; rejected.
- **History-preserving split (`filter-repo`)** — higher cost; deferred unless blame in new remotes is required.
