#!/usr/bin/env bash
# Publisher: refresh pinned vendors into the repo Published pack at skills/.
# Does not install into ~/.cursor — consumers use npx skills + install-rules.sh.
set -euo pipefail

AI_ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$AI_ROOT/.." && pwd)"
# shellcheck source=vendor-config.sh
source "$AI_ROOT/vendor-config.sh"

PACK_DIR="$REPO_ROOT/skills"
HOUSE_SRC="$AI_ROOT/skills"
VENDOR_DIR="${VENDOR_DIR:-$AI_ROOT/.vendor}"
mkdir -p "$PACK_DIR" "$VENDOR_DIR"

echo "Publisher sync → $PACK_DIR"
echo "Vendors: $VENDOR_DIR"
echo

declare -a INSTALLED=()

install_dir() {
  local name="$1" src="$2" dest_root="$3"
  local dest="$dest_root/$name"
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi
  cp -a "$src" "$dest"
}

install_skill() {
  local name="$1" src="$2" label="${3:-}"
  install_dir "$name" "$src" "$PACK_DIR"
  INSTALLED+=("$name")
  echo "skill $name${label:+ $label}"
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

ensure_vendor_repo() {
  local name="$1" url="$2" ref="${3:-}"
  local dest="$VENDOR_DIR/$name"
  mkdir -p "$VENDOR_DIR"
  if [[ ! -d "$dest/.git" ]]; then
    git clone --quiet "$url" "$dest"
  fi
  if [[ -n "$ref" ]]; then
    git -C "$dest" fetch --quiet origin
    if ! git -C "$dest" cat-file -e "${ref}^{commit}" 2>/dev/null; then
      echo "ERROR: vendor $name: pinned ref $ref not found; update ai/vendor-config.sh" >&2
      return 1
    fi
    git -C "$dest" checkout --quiet --detach "$ref"
  fi
  echo "vendor $name $(git -C "$dest" rev-parse --short HEAD) $(git -C "$dest" describe --tags --always 2>/dev/null || true)"
}

patch_file_glossary_to_context() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  sed \
    -e 's/GLOSSARY-MAP\.md/CONTEXT-MAP.md/g' \
    -e 's/GLOSSARY-FORMAT\.md/CONTEXT-FORMAT.md/g' \
    -e 's/GLOSSARY\.md/CONTEXT.md/g' \
    -e 's|docs/adr/|context/adr/|g' \
    -e 's|├── docs/|├── context/|g' \
    -e 's|│   ├── docs/adr/|│   ├── context/adr/|g' \
    -e 's|│   └── docs/adr/|│   └── context/adr/|g' \
    "$file" >"$tmp"
  mv "$tmp" "$file"
}

patch_matt_layout() {
  local skill_dir name
  for name in domain-modeling grill-with-docs grilling grill-me ask-matt setup-matt-pocock-skills \
    to-spec to-tickets implement implement-spec wayfinder triage codebase-design \
    improve-codebase-architecture code-review wait-what retro pr prototype research wizard; do
    skill_dir="$PACK_DIR/$name"
    [[ -d "$skill_dir" ]] || continue
    local f
    while IFS= read -r -d '' f; do
      patch_file_glossary_to_context "$f"
    done < <(find "$skill_dir" -type f \( -name '*.md' -o -name '*.txt' -o -name '*.yaml' -o -name '*.yml' \) -print0 2>/dev/null)
  done
  echo "patch matt layout → CONTEXT.md / context/adr/"
}

patch_matt_skill_calls() {
  local skill_dir name f tmp
  for name in implement implement-spec ask-matt grill-with-docs triage wayfinder \
    improve-codebase-architecture codebase-design tdd diagnosing-bugs; do
    skill_dir="$PACK_DIR/$name"
    [[ -d "$skill_dir" ]] || continue
    while IFS= read -r -d '' f; do
      tmp="$(mktemp)"
      sed \
        -e 's/"tdd"/"test-driven-development"/g' \
        -e "s/'tdd'/'test-driven-development'/g" \
        -e 's|`/tdd`|`/test-driven-development`|g' \
        -e 's/"diagnosing-bugs"/"systematic-debugging"/g' \
        -e "s/'diagnosing-bugs'/'systematic-debugging'/g" \
        -e 's|`/diagnosing-bugs`|`/systematic-debugging`|g' \
        "$f" >"$tmp"
      mv "$tmp" "$f"
    done < <(find "$skill_dir" -type f -name '*.md' -print0 2>/dev/null)
  done
  echo "patch matt skill calls → test-driven-development / systematic-debugging"
}

patch_domain_modeling_overlays() {
  local dest="$PACK_DIR/domain-modeling"
  [[ -d "$dest" ]] || return 0
  local overlay="$AI_ROOT/overlays/domain-modeling"
  if [[ -f "$overlay/CONTEXT-FORMAT.md" ]]; then
    rm -f "$dest/GLOSSARY-FORMAT.md"
    cp -a "$overlay/CONTEXT-FORMAT.md" "$dest/CONTEXT-FORMAT.md"
  fi
  if [[ -f "$overlay/ADR-FORMAT.md" ]]; then
    cp -a "$overlay/ADR-FORMAT.md" "$dest/ADR-FORMAT.md"
  fi
  echo "patch domain-modeling overlays (CONTEXT-FORMAT + ADR-FORMAT)"
}

patch_writing_plans_location() {
  local skill="$PACK_DIR/writing-plans/SKILL.md"
  if [[ ! -f "$skill" ]]; then
    echo "WARN: writing-plans SKILL.md missing; skip plan-location patch" >&2
    return 0
  fi
  if grep -q '\.cursor/plans/YYYY-MM-DD-<feature-name>\.md' "$skill"; then
    echo "patch writing-plans plan location (already applied)"
    return 0
  fi
  local tmp
  tmp="$(mktemp)"
  sed \
    -e 's|docs/superpowers/plans/YYYY-MM-DD-<feature-name>\.md|.cursor/plans/YYYY-MM-DD-<feature-name>.md|g' \
    -e 's|docs/superpowers/plans/<filename>\.md|.cursor/plans/<filename>.md|g' \
    -e 's|docs/superpowers/plans/|.cursor/plans/|g' \
    -e 's|context/plans/YYYY-MM-DD-<feature-name>\.md|.cursor/plans/YYYY-MM-DD-<feature-name>.md|g' \
    -e 's|context/plans/<filename>\.md|.cursor/plans/<filename>.md|g' \
    -e 's|context/plans/|.cursor/plans/|g' \
    "$skill" >"$tmp"
  mv "$tmp" "$skill"
  echo "patch writing-plans plan location → .cursor/plans/"
}

# --- House catalog (source under ai/skills/{engineering,productivity,misc}) ---
for category in engineering productivity misc; do
  for d in "$HOUSE_SRC/$category"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    install_skill "$name" "$(cd "$d" && pwd)" "(house)"
  done
done

# --- Matt (allowlist) ---
MATT="$VENDOR_DIR/mattpocock-skills"
ensure_vendor_repo mattpocock-skills "$MATT_URL" "$MATT_REF"
for rel in "${MATT_ALLOWLIST[@]}"; do
  src="$MATT/skills/$rel"
  name="$(basename "$rel")"
  if [[ ! -d "$src" || ! -f "$src/SKILL.md" ]]; then
    echo "ERROR: Matt allowlist entry missing: skills/$rel" >&2
    exit 1
  fi
  install_skill "$name" "$src" "(matt)"
done

patch_matt_layout
patch_domain_modeling_overlays
patch_matt_skill_calls

# --- Superpowers (denylist) ---
SUPERPOWERS="$VENDOR_DIR/superpowers"
ensure_vendor_repo superpowers "$SUPERPOWERS_URL" "$SUPERPOWERS_REF"
for d in "$SUPERPOWERS"/skills/*/; do
  name="$(basename "$d")"
  if in_list "$name" "${SUPERPOWERS_DENYLIST[@]}"; then
    echo "skip superpowers $name (denylist)"
    continue
  fi
  install_skill "$name" "$d" "(superpowers)"
done
patch_writing_plans_location

# --- SkillSpector skill only (CLI install stays optional / local) ---
SKILLSPECTOR="$VENDOR_DIR/skillspector"
ensure_vendor_repo skillspector "$SKILLSPECTOR_URL" "$SKILLSPECTOR_REF"
SKILL_INSPECTOR="$SKILLSPECTOR/skills/skill-inspector"
if [[ -d "$SKILL_INSPECTOR" && -f "$SKILL_INSPECTOR/SKILL.md" ]]; then
  install_skill "skill-inspector" "$SKILL_INSPECTOR" "(vendor)"
else
  echo "WARN: skillspector missing skills/skill-inspector/SKILL.md" >&2
fi

# Prune pack entries not in this sync (keep nothing stale)
for dest in "$PACK_DIR"/*/; do
  [[ -d "$dest" ]] || continue
  name="$(basename "$dest")"
  if ! in_list "$name" "${INSTALLED[@]}"; then
    rm -rf "$dest"
    echo "pruned $name"
  fi
done

# Never publish retired / excluded names
for retired in diagnose tdd new-skill using-superpowers brainstorming requesting-code-review \
  flux-amq revue-java new-app new-rule build-context context-map angular-developer \
  teach-me teach diagnosing-bugs writing-for-agents to-questionnaire; do
  if [[ -e "$PACK_DIR/$retired" ]] && ! in_list "$retired" "${INSTALLED[@]}"; then
    rm -rf "$PACK_DIR/$retired"
    echo "removed retired $retired"
  fi
done

echo
echo "=== verify pack ==="
broken=0
for name in "${INSTALLED[@]}"; do
  if [[ ! -f "$PACK_DIR/$name/SKILL.md" ]]; then
    echo "MISSING SKILL.md: $name"
    broken=1
  else
    echo "OK: skill $name"
  fi
done

if [[ -f "$PACK_DIR/domain-modeling/SKILL.md" ]]; then
  if grep -q 'GLOSSARY\.md' "$PACK_DIR/domain-modeling/SKILL.md"; then
    echo "FAIL: domain-modeling still references GLOSSARY.md"
    broken=1
  elif grep -q 'CONTEXT\.md' "$PACK_DIR/domain-modeling/SKILL.md"; then
    echo "OK: domain-modeling uses CONTEXT.md"
  fi
  if [[ ! -f "$PACK_DIR/domain-modeling/CONTEXT-FORMAT.md" ]]; then
    echo "FAIL: domain-modeling missing CONTEXT-FORMAT.md"
    broken=1
  fi
fi
if [[ -f "$PACK_DIR/implement/SKILL.md" ]]; then
  if grep -E 'Skill tool with "tdd"|with "tdd"' "$PACK_DIR/implement/SKILL.md"; then
    echo "FAIL: implement still calls tdd"
    broken=1
  elif grep -q 'test-driven-development' "$PACK_DIR/implement/SKILL.md"; then
    echo "OK: implement → test-driven-development"
  fi
fi
if [[ -e "$PACK_DIR/using-superpowers" ]]; then
  echo "FAIL: using-superpowers present"
  broken=1
else
  echo "OK: using-superpowers absent"
fi
if [[ -e "$PACK_DIR/teach-me" || -e "$PACK_DIR/teach" ]]; then
  echo "FAIL: teach-me/teach should be absent"
  broken=1
else
  echo "OK: teach-me/teach absent"
fi

[[ "$broken" -eq 0 ]]
echo "Published ${#INSTALLED[@]} skills under skills/"
