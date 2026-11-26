#!/usr/bin/env bash
# Retired consumer installer (ADR 0021).
set -euo pipefail
cat >&2 <<'EOF'
ai/install-skills.sh is retired (ADR 0021).

Consumers (Cursor, global):
  npx skills add AzerSoft-NC/azr-marketplace -g -a cursor
  npx skills update -g
  ai/install-rules.sh

Maintainers (refresh Published pack under skills/):
  ai/sync-vendors.sh
EOF
exit 1
