#!/usr/bin/env bash
# Install Cursor always-on rules (.mdc) into ~/.cursor/rules.
# Run after: npx skills add AzerSoft-NC/azr-marketplace -g -a cursor
set -euo pipefail

AI_ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  TARGET_USER="$SUDO_USER"
else
  TARGET_HOME="${HOME}"
  TARGET_USER="$(id -un)"
fi

RULES_DIR="$TARGET_HOME/.cursor/rules"
RULES_MANIFEST="$RULES_DIR/.azr-installed"
mkdir -p "$RULES_DIR"

echo "Installing rules into $RULES_DIR (user=$TARGET_USER)"

declare -a RULES_INSTALLED=()
for f in no-read-secrets.mdc architecture-forks.mdc caveman-default.mdc architecture-graph.mdc skill-router.mdc clean-code.mdc; do
  src="$AI_ROOT/rules/$f"
  if [[ ! -f "$src" ]]; then
    echo "ERROR: missing $src" >&2
    exit 1
  fi
  cp -a "$src" "$RULES_DIR/$f"
  RULES_INSTALLED+=("$f")
  echo "rule $f"
done

if [[ -f "$RULES_MANIFEST" ]]; then
  while IFS= read -r old || [[ -n "$old" ]]; do
    [[ -z "$old" ]] && continue
    found=0
    for entry in "${RULES_INSTALLED[@]}"; do
      [[ "$entry" == "$old" ]] && found=1 && break
    done
    if [[ "$found" -eq 0 && -e "$RULES_DIR/$old" ]]; then
      rm -f "$RULES_DIR/$old"
      echo "pruned $old"
    fi
  done < "$RULES_MANIFEST"
fi
printf '%s\n' "${RULES_INSTALLED[@]}" > "$RULES_MANIFEST"

if [[ "$(id -un)" == "root" && "$TARGET_USER" != "root" ]]; then
  for f in "${RULES_INSTALLED[@]}"; do
    chown "$TARGET_USER:$TARGET_USER" "$RULES_DIR/$f" 2>/dev/null || true
  done
  chown "$TARGET_USER:$TARGET_USER" "$RULES_MANIFEST" "$RULES_DIR" 2>/dev/null || true
fi

echo "Installed ${#RULES_INSTALLED[@]} rules"
