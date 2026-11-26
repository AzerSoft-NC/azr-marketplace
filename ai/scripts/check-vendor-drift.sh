#!/usr/bin/env bash
# Report commits on allowlisted vendor skill paths since the pinned SHAs.
# Exit 0 = in sync; exit 1 = drift (or new upstream skills outside allowlist needing a decision).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../vendor-config.sh
source "$ROOT/vendor-config.sh"

# Publisher clones live under ai/.vendor (gitignored). Override with VENDOR_DIR.
VENDOR_DIR="${VENDOR_DIR:-$ROOT/.vendor}"

ensure_clone() {
  local name="$1"
  local url="$2"
  local dest="$VENDOR_DIR/$name"
  mkdir -p "$VENDOR_DIR"
  if [[ ! -d "$dest/.git" ]]; then
    git clone --quiet "$url" "$dest"
  fi
  git -C "$dest" fetch --quiet origin
  echo "$dest"
}

default_branch() {
  local dest="$1"
  local ref
  ref="$(git -C "$dest" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "$ref" ]]; then
    echo "${ref#origin/}"
  else
    echo main
  fi
}

in_list() {
  local needle="$1"
  shift
  local x
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

# List immediate child dir names under a path at a git tree-ish (e.g. skills or skills/engineering).
list_skill_dirs() {
  local dest="$1" treeish="$2" prefix="$3"
  git -C "$dest" ls-tree -d --name-only "${treeish}:${prefix}" 2>/dev/null
}

DRIFT=0

echo "=== vendor drift check ==="
echo "config: $ROOT/vendor-config.sh"
echo "vendor dir: $VENDOR_DIR"
echo

# --- Superpowers ---
SP="$(ensure_clone superpowers "$SUPERPOWERS_URL")"
SP_BRANCH="$(default_branch "$SP")"
SP_REMOTE="origin/$SP_BRANCH"
if ! git -C "$SP" cat-file -e "${SUPERPOWERS_REF}^{commit}" 2>/dev/null; then
  echo "ERROR: SUPERPOWERS_REF $SUPERPOWERS_REF not in $SP after fetch" >&2
  exit 2
fi

SP_PATHS=()
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  if in_list "$name" "${SUPERPOWERS_DENYLIST[@]}"; then
    continue
  fi
  SP_PATHS+=("skills/$name")
done < <(list_skill_dirs "$SP" "$SUPERPOWERS_REF" skills)

echo "## superpowers  pin=$(git -C "$SP" rev-parse --short "$SUPERPOWERS_REF")  remote=$(git -C "$SP" rev-parse --short "$SP_REMOTE") ($SP_BRANCH)"
if [[ "${#SP_PATHS[@]}" -eq 0 ]]; then
  echo "(no installed skill paths at pin)"
else
  SP_LOG="$(git -C "$SP" log --oneline "${SUPERPOWERS_REF}..${SP_REMOTE}" -- "${SP_PATHS[@]}" || true)"
  if [[ -n "$SP_LOG" ]]; then
    DRIFT=1
    echo "DRIFT — commits touching installed skills:"
    echo "$SP_LOG"
  else
    echo "OK — no commits on installed skill paths"
  fi
fi

# New skill dirs on remote tip not present at pin (and not denylisted)
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  if in_list "$name" "${SUPERPOWERS_DENYLIST[@]}"; then
    continue
  fi
  if ! git -C "$SP" cat-file -e "${SUPERPOWERS_REF}:skills/$name" 2>/dev/null; then
    DRIFT=1
    echo "NEW skill on remote (not in pin): skills/$name — decide: install or add to SUPERPOWERS_DENYLIST"
  fi
done < <(list_skill_dirs "$SP" "$SP_REMOTE" skills)
echo

# --- Matt ---
MATT="$(ensure_clone mattpocock-skills "$MATT_URL")"
MATT_BRANCH="$(default_branch "$MATT")"
MATT_REMOTE="origin/$MATT_BRANCH"
if ! git -C "$MATT" cat-file -e "${MATT_REF}^{commit}" 2>/dev/null; then
  echo "ERROR: MATT_REF $MATT_REF not in $MATT after fetch" >&2
  exit 2
fi

MATT_PATHS=()
for rel in "${MATT_ALLOWLIST[@]}"; do
  MATT_PATHS+=("skills/$rel")
done

echo "## mattpocock-skills  pin=$(git -C "$MATT" rev-parse --short "$MATT_REF")  remote=$(git -C "$MATT" rev-parse --short "$MATT_REMOTE") ($MATT_BRANCH)"
MATT_LOG="$(git -C "$MATT" log --oneline "${MATT_REF}..${MATT_REMOTE}" -- "${MATT_PATHS[@]}" || true)"
if [[ -n "$MATT_LOG" ]]; then
  DRIFT=1
  echo "DRIFT — commits touching allowlisted skills:"
  echo "$MATT_LOG"
else
  echo "OK — no commits on allowlisted skill paths"
fi

for bucket in engineering productivity; do
  while IFS= read -r name; do
    [[ -z "$name" || "$name" == "README.md" ]] && continue
    rel="$bucket/$name"
    if in_list "$rel" "${MATT_ALLOWLIST[@]}" || in_list "$rel" "${MATT_EXCLUDE[@]}"; then
      continue
    fi
    DRIFT=1
    echo "NEW skill on remote (not in allowlist/exclude): skills/$rel — decide: allowlist or MATT_EXCLUDE"
  done < <(list_skill_dirs "$MATT" "$MATT_REMOTE" "skills/$bucket")
done
echo

# --- SkillSpector ---
SS="$(ensure_clone skillspector "$SKILLSPECTOR_URL")"
SS_BRANCH="$(default_branch "$SS")"
SS_REMOTE="origin/$SS_BRANCH"
if git -C "$SS" cat-file -e "${SKILLSPECTOR_REF}^{commit}" 2>/dev/null; then
  SS_LOG="$(git -C "$SS" log --oneline "${SKILLSPECTOR_REF}..${SS_REMOTE}" -- skills/skill-inspector || true)"
  echo "## skillspector  pin=$(git -C "$SS" rev-parse --short "$SKILLSPECTOR_REF")  remote=$(git -C "$SS" rev-parse --short "$SS_REMOTE") ($SS_BRANCH)"
  if [[ -n "$SS_LOG" ]]; then
    DRIFT=1
    echo "DRIFT — commits touching skill-inspector:"
    echo "$SS_LOG"
  else
    echo "OK — no commits on skill-inspector"
  fi
else
  echo "## skillspector  WARN: pin $SKILLSPECTOR_REF missing after fetch"
  DRIFT=1
fi
echo

if [[ "$DRIFT" -eq 0 ]]; then
  echo "=== in sync ==="
  exit 0
fi
echo "=== drift detected — bump pins via catalog PR (see docs/ai/README.md) ==="
exit 1
