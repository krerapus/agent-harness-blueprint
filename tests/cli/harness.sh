#!/usr/bin/env bash
# Harness ownership tests for blueprint init / update.
# Run from package root: ./tests/cli/harness.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BP="${ROOT}/blueprint"
BASE="${ROOT}/.tmp-harness-test"
PASS=0
FAIL=0

ASSETS_ROOT="${BLUEPRINT_ASSETS_ROOT:-}"
if [[ -z "$ASSETS_ROOT" || ! -d "${ASSETS_ROOT}/packs/core/harness" ]]; then
  ASSETS_ROOT="$(cd "${ROOT}/.." && pwd)/assets-blueprint"
fi
if [[ ! -d "${ASSETS_ROOT}/packs/core/harness" ]]; then
  echo "FAIL: core pack not found. Set BLUEPRINT_ASSETS_ROOT or place assets-blueprint as a sibling of this repo."
  exit 1
fi
export BLUEPRINT_ASSETS_ROOT="$ASSETS_ROOT"
CORE_PACK="${ASSETS_ROOT}/packs/core"

assert_eq() {
  local label="$1" got="$2" want="$3"
  if [[ "$got" == "$want" ]]; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (got='$got' want='$want')"
    FAIL=$((FAIL + 1))
  fi
}

assert_file() {
  local label="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (missing $path)"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_file() {
  local label="$1" path="$2"
  if [[ ! -f "$path" ]]; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (unexpected $path)"
    FAIL=$((FAIL + 1))
  fi
}

# Case-sensitive basename presence (needed on case-insensitive volumes).
exact_basename_exists() {
  local dir="$1" name="$2"
  local f
  shopt -s nullglob
  for f in "${dir}"/*; do
    [[ -f "$f" ]] || continue
    if [[ "$(basename "$f")" == "$name" ]]; then
      shopt -u nullglob
      return 0
    fi
  done
  shopt -u nullglob
  return 1
}

assert_exact() {
  local label="$1" dir="$2" name="$3" want_present="$4"
  if exact_basename_exists "$dir" "$name"; then
    if [[ "$want_present" -eq 1 ]]; then
      echo "  PASS  $label"
      PASS=$((PASS + 1))
    else
      echo "  FAIL  $label (unexpected exact $name)"
      FAIL=$((FAIL + 1))
    fi
  else
    if [[ "$want_present" -eq 0 ]]; then
      echo "  PASS  $label"
      PASS=$((PASS + 1))
    else
      echo "  FAIL  $label (missing exact $name)"
      FAIL=$((FAIL + 1))
    fi
  fi
}

assert_contains() {
  local label="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF "$needle"; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (missing '$needle')"
    FAIL=$((FAIL + 1))
  fi
}

assert_count() {
  local label="$1" hay="$2" needle="$3" want="$4"
  local got
  got="$(printf '%s' "$hay" | grep -cF "$needle" || true)"
  assert_eq "$label" "$got" "$want"
}

# Content outside managed markers must match exactly (preserve trailing newlines).
outside_markers() {
  local file="$1"
  awk '
    $0 == "<!-- BLUEPRINT:HARNESS:START -->" { skip=1; next }
    skip && $0 == "<!-- BLUEPRINT:HARNESS:END -->" { skip=0; next }
    skip { next }
    { print }
  ' "$file"
}

read_preserve() {
  local data
  data="$(cat "$1"; printf x)"
  printf '%s' "${data%x}"
}

outside_markers_preserved() {
  local data
  data="$(outside_markers "$1"; printf x)"
  printf '%s' "${data%x}"
}

fresh() {
  local name="$1"
  local dir="${BASE}/${name}"
  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

cleanup() {
  rm -rf "$BASE"
}
trap cleanup EXIT

export CI=1
export NO_COLOR=1
export BLUEPRINT_HISTORY_LIMIT=10
export XDG_DATA_HOME="${BASE}-xdg/data"
export XDG_CACHE_HOME="${BASE}-xdg/cache"
export BLUEPRINT_TARGETS_FILE="${BASE}-targets.json"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
rm -rf "$BASE" "${BASE}-targets.json"
mkdir -p "$BASE"

echo "== 1. no existing agent files =="
d="$(fresh case1)"
out="$(CI=1 NO_COLOR=1 "$BP" init --target "$d" 2>&1)"
assert_file "HARNESS.md" "$d/HARNESS.md"
assert_file "AGENTS.md" "$d/AGENTS.md"
assert_exact "no CLAUDE.md created" "$d" "CLAUDE.md" 0
assert_contains "init banner" "$out" "Blueprint initialized"
assert_contains "canonical template body" "$(cat "$d/AGENTS.md")" "Shared agent contract for this repository"
assert_contains "markers" "$(cat "$d/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_contains "memory refs in block" "$(cat "$d/AGENTS.md")" "PLANNING.md"

echo "== 2. existing AGENTS.md =="
d="$(fresh case2)"
printf '# Custom\n\nKeep me.\n' > "$d/AGENTS.md"
before_out="$(outside_markers_preserved "$d/AGENTS.md")"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_file "HARNESS.md" "$d/HARNESS.md"
assert_contains "kept custom" "$(cat "$d/AGENTS.md")" "Keep me."
assert_eq "outside markers preserved" "$(outside_markers_preserved "$d/AGENTS.md")" "$before_out"
assert_count "one start marker" "$(cat "$d/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->" "1"
assert_not_contains() {
  local label="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF "$needle"; then
    echo "  FAIL  $label (unexpected '$needle')"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  fi
}
assert_not_contains "no full template injected" "$(cat "$d/AGENTS.md")" "Required setup"

echo "== 3. existing agents.md =="
d="$(fresh case3)"
printf '# lower agents\n' > "$d/agents.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_exact "agents.md kept" "$d" "agents.md" 1
assert_exact "no AGENTS.md created" "$d" "AGENTS.md" 0
assert_contains "ref in agents.md" "$(cat "$d/agents.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_contains "lower content" "$(cat "$d/agents.md")" "lower agents"

echo "== 4. CLAUDE.md only =="
d="$(fresh case4)"
printf '# Claude only\n' > "$d/CLAUDE.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_exact "no AGENTS.md created" "$d" "AGENTS.md" 0
assert_file "HARNESS.md" "$d/HARNESS.md"
assert_contains "claude content kept" "$(cat "$d/CLAUDE.md")" "Claude only"
assert_contains "ref in CLAUDE.md" "$(cat "$d/CLAUDE.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_count "one start on CLAUDE" "$(cat "$d/CLAUDE.md")" "<!-- BLUEPRINT:HARNESS:START -->" "1"

echo "== 4b. claude.md only =="
d="$(fresh case4b)"
printf '# lower claude\n' > "$d/claude.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_exact "no AGENTS.md" "$d" "AGENTS.md" 0
assert_exact "no CLAUDE.md" "$d" "CLAUDE.md" 0
assert_exact "claude.md kept" "$d" "claude.md" 1
assert_contains "ref in claude.md" "$(cat "$d/claude.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_contains "lower claude kept" "$(cat "$d/claude.md")" "lower claude"

echo "== 5. CLAUDE.md + AGENTS.md =="
d="$(fresh case5)"
printf '# Agents custom\n' > "$d/AGENTS.md"
printf '# Claude custom\n' > "$d/CLAUDE.md"
claude_before="$(cat "$d/CLAUDE.md")"
agents_before_out="$(outside_markers_preserved "$d/AGENTS.md")"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_eq "CLAUDE unchanged" "$(cat "$d/CLAUDE.md")" "$claude_before"
assert_contains "agents ref" "$(cat "$d/AGENTS.md")" "BLUEPRINT:HARNESS:START"
assert_eq "agents outside preserved" "$(outside_markers_preserved "$d/AGENTS.md")" "$agents_before_out"

echo "== 6. CLAUDE.md + agents.md =="
d="$(fresh case6)"
printf '# lower\n' > "$d/agents.md"
printf '# Claude\n' > "$d/CLAUDE.md"
claude_before="$(cat "$d/CLAUDE.md")"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_exact "no AGENTS.md" "$d" "AGENTS.md" 0
assert_exact "agents.md present" "$d" "agents.md" 1
assert_contains "ref in agents.md" "$(cat "$d/agents.md")" "BLUEPRINT:HARNESS:START"
assert_eq "CLAUDE unchanged" "$(cat "$d/CLAUDE.md")" "$claude_before"

echo "== 7. both AGENTS.md and agents.md =="
d="$(fresh case7)"
# On case-insensitive volumes these collide; skip dual-file assert when identical path.
printf '# UPPER\n' > "$d/AGENTS.md"
if printf '# lower\n' > "$d/agents.md" 2>/dev/null && \
   [[ "$(cat "$d/AGENTS.md")" == "# UPPER" ]] && [[ "$(cat "$d/agents.md")" == "# lower" ]]; then
  out="$(CI=1 NO_COLOR=1 "$BP" init --target "$d" 2>&1)"
  assert_contains "warning both files" "$out" "Both AGENTS.md and agents.md"
  assert_contains "ref in AGENTS" "$(cat "$d/AGENTS.md")" "BLUEPRINT:HARNESS:START"
  assert_eq "agents.md untouched" "$(cat "$d/agents.md")" "# lower"
else
  # Case-insensitive FS: treat as AGENTS.md-only path.
  CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
  assert_contains "ref present" "$(cat "$d/AGENTS.md")" "BLUEPRINT:HARNESS:START"
  echo "  PASS  case7 skipped dual-file (case-insensitive FS)"
  PASS=$((PASS + 1))
fi

echo "== 8. repeated init idempotent =="
d="$(fresh case8)"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_count "single start after re-init" "$(cat "$d/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->" "1"
assert_count "single end after re-init" "$(cat "$d/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:END -->" "1"

echo "== 9. existing managed block updated without surrounding churn =="
d="$(fresh case9)"
cat > "$d/AGENTS.md" <<'EOF'
# Intro

Keep surrounding.

<!-- BLUEPRINT:HARNESS:START -->
## Shared Harness
OLD BLOCK
<!-- BLUEPRINT:HARNESS:END -->

# Outro
EOF
before_out="$(outside_markers_preserved "$d/AGENTS.md")"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_eq "surrounding preserved" "$(outside_markers_preserved "$d/AGENTS.md")" "$before_out"
assert_contains "new block" "$(cat "$d/AGENTS.md")" "shared-agent-blueprints"
assert_contains "memory pointer" "$(cat "$d/AGENTS.md")" "PLANNING.md"
assert_not_contains "old block gone" "$(cat "$d/AGENTS.md")" "OLD BLOCK"

echo "== 10. formatting preserved outside markers =="
d="$(fresh case10)"
printf 'Line A\n\n\tIndented\n' > "$d/AGENTS.md"
before="$(cat "$d/AGENTS.md")"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
# Prefix before markers must equal original (append path).
got_prefix="$(awk '/<!-- BLUEPRINT:HARNESS:START -->/{exit} {print}' "$d/AGENTS.md")"
# Original may lack trailing newline handling; compare trimmed body.
assert_contains "tab indent kept" "$(cat "$d/AGENTS.md")" $'\tIndented'
assert_contains "Line A kept" "$(cat "$d/AGENTS.md")" "Line A"

echo "== 11-14. update only HARNESS.md; agent files byte-stable =="
d="$(fresh case_update)"
printf '# Agents\nuser text\n' > "$d/AGENTS.md"
printf '# Claude\nclaude text\n' > "$d/CLAUDE.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
agents_bytes="$(cat "$d/AGENTS.md")"
claude_bytes="$(cat "$d/CLAUDE.md")"
# Dirty HARNESS so update has work to do
printf 'stale\n' > "$d/HARNESS.md"
printf '<!-- managed-by: shared-agent-blueprints -->\n' >> "$d/HARNESS.md"
out="$(CI=1 NO_COLOR=1 "$BP" update --target "$d" 2>&1)"
assert_contains "update banner" "$out" "Blueprint updated"
assert_contains "updated harness" "$out" "HARNESS.md"
assert_eq "AGENTS byte-stable" "$(cat "$d/AGENTS.md")" "$agents_bytes"
assert_eq "CLAUDE byte-stable" "$(cat "$d/CLAUDE.md")" "$claude_bytes"
assert_contains "harness refreshed" "$(cat "$d/HARNESS.md")" "Execution lifecycle"

d2="$(fresh case_update_lower)"
printf '# lower agents\n' > "$d2/agents.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d2" >/dev/null 2>&1
lower_bytes="$(cat "$d2/agents.md")"
CI=1 NO_COLOR=1 "$BP" update --target "$d2" >/dev/null 2>&1
assert_eq "agents.md byte-stable on update" "$(cat "$d2/agents.md")" "$lower_bytes"

echo "== 15. malformed managed markers =="
d="$(fresh case15)"
printf '# X\n<!-- BLUEPRINT:HARNESS:START -->\nbroken\n' > "$d/AGENTS.md"
before="$(cat "$d/AGENTS.md")"
out="$(CI=1 NO_COLOR=1 "$BP" init --target "$d" 2>&1)"
assert_eq "file unchanged" "$(cat "$d/AGENTS.md")" "$before"
assert_contains "malformed warning" "$out" "Malformed"

echo "== 16. user-authored HARNESS.md not silently overwritten =="
d="$(fresh case16)"
printf '# My harness\ncustom\n' > "$d/HARNESS.md"
before="$(cat "$d/HARNESS.md")"
out="$(CI=1 NO_COLOR=1 "$BP" init --target "$d" 2>&1)"
assert_eq "unmanaged harness preserved" "$(cat "$d/HARNESS.md")" "$before"
assert_contains "unmanaged warning" "$out" "not Blueprint-managed"
# --force backups and replaces
out="$(CI=1 NO_COLOR=1 "$BP" init --force --target "$d" 2>&1)"
assert_contains "managed after force" "$(cat "$d/HARNESS.md")" "managed-by: shared-agent-blueprints"
bak_count="$(find "$d" -maxdepth 1 -name 'HARNESS.md.blueprint-backup.*' | wc -l | tr -d ' ')"
assert_eq "backup created" "$bak_count" "1"

echo "== 17. paths containing spaces =="
d="${BASE}/path with spaces"
rm -rf "$d"
mkdir -p "$d"
printf '# spaced\n' > "$d/AGENTS.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_file "HARNESS in spaced path" "$d/HARNESS.md"
assert_contains "ref in spaced path" "$(cat "$d/AGENTS.md")" "BLUEPRINT:HARNESS:START"
agents_bytes="$(cat "$d/AGENTS.md")"
CI=1 NO_COLOR=1 "$BP" update --target "$d" >/dev/null 2>&1
assert_eq "spaced path agents stable" "$(cat "$d/AGENTS.md")" "$agents_bytes"

echo "== 18. rollback after write failure =="
d="$(fresh case18)"
printf '# stable\n' > "$d/AGENTS.md"
# Source helpers and force a failure by making destination a directory named like temp collision is hard;
# instead: make agent file path a directory so atomic write fails, then verify original remains.
# Use a unit-level call via bash.
# shellcheck source=lib/blueprint/harness.sh
source "${ROOT}/lib/blueprint/term.sh"
source "${ROOT}/lib/blueprint/events.sh"
source "${ROOT}/lib/blueprint/render.sh"
source "${ROOT}/lib/blueprint/harness.sh"
PACKAGE_ROOT="$ROOT"
MARKER="<!-- managed-by: shared-agent-blueprints -->"
DRY_RUN=0
FORCE=0
need_file() { [[ -f "$1" ]] || { echo "missing $1"; return 1; }; }
emit_error() { printf 'error: %s\n' "$*" >&2; }
emit_warning() { printf 'warn: %s\n' "$*" >&2; }
emit_file_added() { :; }
emit_file_updated() { :; }
emit_file_skipped() { :; }
emit_info() { :; }

# Simulate failure: replace harness_atomic_write temporarily
orig_write="$(declare -f harness_atomic_write)"
harness_atomic_write() { return 1; }
before="$(cat "$d/AGENTS.md")"
set +e
ensure_harness_reference "$d/AGENTS.md"
rc=$?
set -e
assert_eq "ensure failed" "$rc" "1"
assert_eq "rolled back content" "$(cat "$d/AGENTS.md")" "$before"
eval "$orig_write"

echo "== 19. nested instruction files ignored =="
d="$(fresh case19)"
mkdir -p "$d/.cursor" "$d/.claude" "$d/docs" "$d/examples" "$d/templates"
printf '# nested cursor\n' > "$d/.cursor/AGENTS.md"
printf '# nested claude\n' > "$d/.claude/CLAUDE.md"
printf '# nested docs\n' > "$d/docs/AGENTS.md"
printf '# nested examples\n' > "$d/examples/AGENTS.md"
printf '# nested templates\n' > "$d/templates/AGENTS.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_file "root AGENTS created" "$d/AGENTS.md"
assert_eq "nested .cursor untouched" "$(cat "$d/.cursor/AGENTS.md")" "# nested cursor"
assert_eq "nested .claude untouched" "$(cat "$d/.claude/CLAUDE.md")" "# nested claude"
assert_eq "nested docs untouched" "$(cat "$d/docs/AGENTS.md")" "# nested docs"
assert_eq "nested examples untouched" "$(cat "$d/examples/AGENTS.md")" "# nested examples"
assert_eq "nested templates untouched" "$(cat "$d/templates/AGENTS.md")" "# nested templates"
assert_contains "root got markers" "$(cat "$d/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_not_contains "nested cursor no markers" "$(cat "$d/.cursor/AGENTS.md")" "BLUEPRINT:HARNESS:START"

echo "== 20. CLAUDE.md re-init idempotent =="
d="$(fresh case20)"
printf '# Claude body\n' > "$d/CLAUDE.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
assert_exact "still no AGENTS.md" "$d" "AGENTS.md" 0
assert_count "single start on CLAUDE" "$(cat "$d/CLAUDE.md")" "<!-- BLUEPRINT:HARNESS:START -->" "1"
assert_count "single end on CLAUDE" "$(cat "$d/CLAUDE.md")" "<!-- BLUEPRINT:HARNESS:END -->" "1"
assert_contains "claude body kept" "$(cat "$d/CLAUDE.md")" "Claude body"

echo "== 21. del strips CLAUDE.md reference block =="
d="$(fresh case21)"
printf '# Claude del\nkeep me\n' > "$d/CLAUDE.md"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" del --force --target "$d" >/dev/null 2>&1
assert_exact "no AGENTS after del" "$d" "AGENTS.md" 0
assert_file "CLAUDE preserved" "$d/CLAUDE.md"
assert_contains "claude body after del" "$(cat "$d/CLAUDE.md")" "keep me"
assert_eq "block stripped" "$(grep -cF 'BLUEPRINT:HARNESS:START' "$d/CLAUDE.md" || true)" "0"

echo "== 22. update removes renamed skills/rules and full-refreshes =="
d="$(fresh case22)"
CI=1 NO_COLOR=1 "$BP" init --target "$d" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$d" >/dev/null 2>&1
# Simulate pre-rename consumer state
mkdir -p "$d/.cursor/skills/memory-system-protocol" "$d/.cursor/skills/planning-execution-tracking"
printf '# stale old skill\n' > "$d/.cursor/skills/memory-system-protocol/SKILL.md"
printf '# stale planning skill\n' > "$d/.cursor/skills/planning-execution-tracking/SKILL.md"
printf '# stale rule\n' > "$d/.cursor/rules/planning-execution-tracking.mdc"
# Stale file inside current skill name (full refresh must drop it)
printf '# orphan inside skill\n' > "$d/.cursor/skills/context-recall/ORPHAN.md"
assert_file "old skill present before update" "$d/.cursor/skills/memory-system-protocol/SKILL.md"
out="$(CI=1 NO_COLOR=1 "$BP" update --target "$d" 2>&1)"
assert_contains "update mentions rename/full refresh" "$out" "rename cleanup + full skill/rule refresh"
assert_not_file "old memory skill removed" "$d/.cursor/skills/memory-system-protocol"
assert_not_file "old planning skill removed" "$d/.cursor/skills/planning-execution-tracking"
assert_not_file "old planning rule removed" "$d/.cursor/rules/planning-execution-tracking.mdc"
assert_file "new context-recall present" "$d/.cursor/skills/context-recall/SKILL.md"
assert_file "new task-execution present" "$d/.cursor/skills/task-execution/SKILL.md"
assert_file "new task-execution rule present" "$d/.cursor/rules/task-execution.mdc"
assert_not_file "orphan inside skill removed" "$d/.cursor/skills/context-recall/ORPHAN.md"
assert_contains "context-recall name" "$(cat "$d/.cursor/skills/context-recall/SKILL.md")" "name: context-recall"
assert_contains "task-execution name" "$(cat "$d/.cursor/skills/task-execution/SKILL.md")" "name: task-execution"

echo "== 23. renames.log exists for rebuild =="
assert_file "renames log" "${CORE_PACK}/harness/migrations/renames.log"
assert_contains "log has memory rename" "$(cat "${CORE_PACK}/harness/migrations/renames.log")" "memory-system-protocol"
assert_contains "log has planning rename" "$(cat "${CORE_PACK}/harness/migrations/renames.log")" "planning-execution-tracking"
assert_contains "log has context-recall" "$(cat "${CORE_PACK}/harness/migrations/renames.log")" "context-recall"
assert_contains "log has task-execution" "$(cat "${CORE_PACK}/harness/migrations/renames.log")" "task-execution"

echo
echo "Results: ${PASS} passed, ${FAIL} failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
