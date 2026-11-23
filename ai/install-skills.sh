#!/usr/bin/env bash
# Copy catalog + vendored skills and rules into ~/.cursor/.
# Safe under sudo: installs into the invoking user's home, not /root.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=vendor-config.sh
source "$ROOT/vendor-config.sh"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  TARGET_USER="$SUDO_USER"
else
  TARGET_HOME="${HOME}"
  TARGET_USER="$(id -un)"
fi

SKILLS_DIR="$TARGET_HOME/.cursor/skills"
RULES_DIR="$TARGET_HOME/.cursor/rules"
VENDOR_DIR="$TARGET_HOME/.cursor/vendor"
MANIFEST="$SKILLS_DIR/.azr-installed"
RULES_MANIFEST="$RULES_DIR/.azr-installed"
mkdir -p "$SKILLS_DIR" "$RULES_DIR" "$VENDOR_DIR"

echo "Installing into $TARGET_HOME/.cursor (user=$TARGET_USER)"
echo "Source: $ROOT"
echo

declare -a INSTALLED=()
declare -a RULES_INSTALLED=()

prepend_target_local_bin() {
  local bin="$TARGET_HOME/.local/bin"
  [[ -d "$bin" ]] || return 0
  case ":${PATH}:" in
    *":${bin}:"*) ;;
    *) PATH="${bin}:${PATH}"; export PATH ;;
  esac
}

run_as_target() {
  if [[ "$(id -un)" == "root" && "${TARGET_USER}" != "root" ]]; then
    if command -v runuser >/dev/null 2>&1; then
      runuser -u "$TARGET_USER" -- "$@"
    else
      sudo -u "$TARGET_USER" -- "$@"
    fi
  else
    "$@"
  fi
}

install_dir() {
  local name="$1"
  local src="$2"
  local dest_root="$3"
  local dest="$dest_root/$name"
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi
  cp -a "$src" "$dest"
}

install_skill() {
  local name="$1" src="$2" label="${3:-}"
  install_dir "$name" "$src" "$SKILLS_DIR"
  INSTALLED+=("$name")
  echo "skill $name${label:+ $label}"
}

install_rule() {
  local rule_file="$1"
  local src="$2"
  local dest="$RULES_DIR/$rule_file"
  rm -f "$dest"
  cp -a "$src" "$dest"
  RULES_INSTALLED+=("$rule_file")
  echo "rule $rule_file"
}

prune_from_manifest() {
  local manifest="$1" dest_root="$2"
  shift 2
  local current=("$@")
  [[ -f "$manifest" ]] || return 0
  local old
  while IFS= read -r old || [[ -n "$old" ]]; do
    [[ -z "$old" ]] && continue
    local found=0 entry
    for entry in "${current[@]}"; do
      [[ "$entry" == "$old" ]] && found=1 && break
    done
    if [[ "$found" -eq 0 && ( -e "$dest_root/$old" || -L "$dest_root/$old" ) ]]; then
      rm -rf "$dest_root/$old" 2>/dev/null || rm -f "$dest_root/$old"
      echo "pruned $old"
    fi
  done < "$manifest"
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
  local name="$1"
  local url="$2"
  local ref="${3:-}"
  local dest="$VENDOR_DIR/$name"
  mkdir -p "$VENDOR_DIR"
  if [[ ! -d "$dest/.git" ]]; then
    git clone --quiet "$url" "$dest"
  fi
  if [[ -n "$ref" ]]; then
    git -C "$dest" fetch --quiet origin
    if ! git -C "$dest" cat-file -e "${ref}^{commit}" 2>/dev/null; then
      echo "ERROR: vendor $name: pinned ref $ref not found upstream; update the pin in ai/vendor-config.sh" >&2
      return 1
    fi
    git -C "$dest" checkout --quiet --detach "$ref"
  else
    if ! git -C "$dest" symbolic-ref -q HEAD >/dev/null; then
      git -C "$dest" checkout --quiet "$(git -C "$dest" rev-parse --abbrev-ref origin/HEAD | cut -d/ -f2-)"
    fi
    git -C "$dest" pull --ff-only --quiet
  fi
  echo "vendor $name $(git -C "$dest" rev-parse --short HEAD) $(git -C "$dest" describe --tags --always)"
}

# --- Layout / call patches (installed copies only; vendor trees stay pristine) ---

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
    skill_dir="$SKILLS_DIR/$name"
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
    skill_dir="$SKILLS_DIR/$name"
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
  local dest="$SKILLS_DIR/domain-modeling"
  [[ -d "$dest" ]] || return 0
  local overlay="$ROOT/overlays/domain-modeling"
  if [[ -f "$overlay/CONTEXT-FORMAT.md" ]]; then
    rm -f "$dest/GLOSSARY-FORMAT.md"
    cp -a "$overlay/CONTEXT-FORMAT.md" "$dest/CONTEXT-FORMAT.md"
  fi
  if [[ -f "$overlay/ADR-FORMAT.md" ]]; then
    cp -a "$overlay/ADR-FORMAT.md" "$dest/ADR-FORMAT.md"
  fi
  # Description frontmatter still may say GLOSSARY — already sed'd by patch_matt_layout
  echo "patch domain-modeling overlays (CONTEXT-FORMAT + ADR-FORMAT)"
}

patch_writing_plans_location() {
  local skill="$SKILLS_DIR/writing-plans/SKILL.md"
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

install_skillspector_skill() {
  local SKILLSPECTOR="$VENDOR_DIR/skillspector"
  local SKILL_INSPECTOR="$SKILLSPECTOR/skills/skill-inspector"
  ensure_vendor_repo skillspector "$SKILLSPECTOR_URL" "$SKILLSPECTOR_REF"
  if [[ -d "$SKILL_INSPECTOR" && -f "$SKILL_INSPECTOR/SKILL.md" ]]; then
    install_skill "skill-inspector" "$SKILL_INSPECTOR" "(vendor)"
  else
    echo "WARN: skillspector clone missing skills/skill-inspector/SKILL.md" >&2
  fi
}

install_skillspector_cli() {
  local SKILLSPECTOR="$VENDOR_DIR/skillspector"
  prepend_target_local_bin
  local uv_bin=""
  if [[ -x "$TARGET_HOME/.local/bin/uv" ]]; then
    uv_bin="$TARGET_HOME/.local/bin/uv"
  elif command -v uv >/dev/null 2>&1; then
    uv_bin="$(command -v uv)"
  fi
  if [[ -z "$uv_bin" ]]; then
    echo "WARN: uv not found; skip skillspector CLI. Install uv (https://docs.astral.sh/uv/), then re-run." >&2
    return 0
  fi
  if run_as_target env UV_SYSTEM_CERTS=1 "$uv_bin" tool install --force --python 3.12 "$SKILLSPECTOR"; then
    prepend_target_local_bin
    echo "cli skillspector ($(command -v skillspector 2>/dev/null || echo "$TARGET_HOME/.local/bin/skillspector"))"
  else
    echo "WARN: uv tool install skillspector failed; skill-inspector will use manual fallback" >&2
  fi
}

# --- Catalog (house) ---
for category in engineering productivity misc; do
  for d in "$ROOT/skills/$category"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    install_skill "$name" "$(cd "$d" && pwd)" "(catalog)"
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

# --- Superpowers (deny list) ---
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

install_skillspector_skill
install_skillspector_cli

for f in no-read-secrets.mdc architecture-forks.mdc caveman-default.mdc architecture-graph.mdc skill-router.mdc clean-code.mdc; do
  install_rule "$f" "$ROOT/rules/$f"
done

prune_from_manifest "$MANIFEST" "$SKILLS_DIR" "${INSTALLED[@]}"
# Leftovers from dropped catalog entries or excluded upstream skills.
for retired in diagnose tdd new-skill using-superpowers brainstorming requesting-code-review \
  flux-amq revue-java new-app new-rule build-context context-map angular-developer \
  teach-me teach diagnosing-bugs writing-for-agents to-questionnaire; do
  if [[ -e "$SKILLS_DIR/$retired" || -L "$SKILLS_DIR/$retired" ]]; then
    # Do not remove if we just installed it under the same name (e.g. matt grill-me).
    if in_list "$retired" "${INSTALLED[@]}"; then
      continue
    fi
    rm -rf "$SKILLS_DIR/$retired"
    echo "removed retired $retired"
  fi
done
printf '%s\n' "${INSTALLED[@]}" > "$MANIFEST"

prune_from_manifest "$RULES_MANIFEST" "$RULES_DIR" "${RULES_INSTALLED[@]}"
printf '%s\n' "${RULES_INSTALLED[@]}" > "$RULES_MANIFEST"

if [[ "$(id -un)" == "root" && "$TARGET_USER" != "root" ]]; then
  for name in "${INSTALLED[@]}"; do
    chown -R "$TARGET_USER:$TARGET_USER" "$SKILLS_DIR/$name" 2>/dev/null || true
  done
  for f in "${RULES_INSTALLED[@]}"; do
    chown "$TARGET_USER:$TARGET_USER" "$RULES_DIR/$f" 2>/dev/null || true
  done
  chown "$TARGET_USER:$TARGET_USER" "$MANIFEST" "$RULES_MANIFEST" 2>/dev/null || true
  chown "$TARGET_USER:$TARGET_USER" "$SKILLS_DIR" "$RULES_DIR" 2>/dev/null || true
  chown -R "$TARGET_USER:$TARGET_USER" "$VENDOR_DIR" 2>/dev/null || true
fi

echo
echo "=== verify ==="
broken=0
for name in "${INSTALLED[@]}"; do
  if [[ ! -f "$SKILLS_DIR/$name/SKILL.md" ]]; then
    echo "MISSING SKILL.md: $name"
    broken=1
  else
    echo "OK: skill $name"
  fi
done
for f in "${RULES_INSTALLED[@]}"; do
  if [[ ! -f "$RULES_DIR/$f" ]]; then
    echo "MISSING: $f"
    broken=1
  else
    echo "OK: rule $f"
  fi
done

# Patch markers
if [[ -f "$SKILLS_DIR/domain-modeling/SKILL.md" ]]; then
  if grep -q 'GLOSSARY\.md' "$SKILLS_DIR/domain-modeling/SKILL.md"; then
    echo "FAIL: domain-modeling still references GLOSSARY.md"
    broken=1
  fi
  if [[ ! -f "$SKILLS_DIR/domain-modeling/CONTEXT-FORMAT.md" ]]; then
    echo "FAIL: domain-modeling missing CONTEXT-FORMAT.md"
    broken=1
  fi
  if grep -q 'CONTEXT\.md' "$SKILLS_DIR/domain-modeling/SKILL.md"; then
    echo "OK: domain-modeling uses CONTEXT.md"
  fi
fi
if [[ -f "$SKILLS_DIR/implement/SKILL.md" ]]; then
  if grep -E 'Skill tool with "tdd"|with "tdd"' "$SKILLS_DIR/implement/SKILL.md"; then
    echo "FAIL: implement still calls tdd"
    broken=1
  elif grep -q 'test-driven-development' "$SKILLS_DIR/implement/SKILL.md"; then
    echo "OK: implement → test-driven-development"
  fi
fi
if [[ -e "$SKILLS_DIR/using-superpowers" ]]; then
  echo "FAIL: using-superpowers present"
  broken=1
else
  echo "OK: using-superpowers absent"
fi
if [[ ! -f "$RULES_DIR/caveman-default.mdc" ]]; then
  echo "FAIL: caveman-default.mdc missing"
  broken=1
else
  echo "OK: caveman-default.mdc"
fi
if [[ -e "$SKILLS_DIR/teach-me" || -e "$SKILLS_DIR/teach" ]]; then
  echo "FAIL: teach-me/teach should be pruned"
  broken=1
else
  echo "OK: teach-me/teach absent"
fi

[[ "$broken" -eq 0 ]]
echo "Installed ${#INSTALLED[@]} skills, ${#RULES_INSTALLED[@]} rules"
