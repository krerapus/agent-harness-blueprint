#!/usr/bin/env bash
# Smoke tests for the Blueprint CLI terminal UX.
# Run from package root: ./tests/cli/smoke.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BP="${ROOT}/blueprint"
TMP="${ROOT}/.tmp-consumer-test"
PASS=0
FAIL=0

# Pack content lives in assets-blueprint (sibling or BLUEPRINT_ASSETS_ROOT).
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
    echo "  FAIL  $label (unexpected file $path)"
    FAIL=$((FAIL + 1))
  fi
}

assert_dir() {
  local label="$1" path="$2"
  if [[ -d "$path" ]]; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (missing $path)"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local label="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF -- "$needle"; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (missing '$needle')"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local label="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF -- "$needle"; then
    echo "  FAIL  $label (unexpected '$needle')"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  fi
}

assert_line() {
  local label="$1" file="$2" line="$3"
  if grep -qxF -- "$line" "$file" 2>/dev/null; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label (missing exact line '$line' in $file)"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_line() {
  local label="$1" file="$2" line="$3"
  if grep -qxF -- "$line" "$file" 2>/dev/null; then
    echo "  FAIL  $label (unexpected exact line '$line' in $file)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  fi
}

cleanup() {
  rm -rf "$TMP" "${TMP}-xdg" "${TMP}-empty" "${TMP}-remote-consumer" "${TMP}-targets.json" \
    "${TMP}-merge" "${TMP}-merge-claude" "${TMP}-merge-gitlab" "${TMP}-merge-targets.json" \
    "${TMP}-del-custom" "${TMP}-auth" "${TMP}-auth-targets.json" "${TMP}-targets-registry.json"
}
trap cleanup EXIT

export CI=1
export NO_COLOR=1
export BLUEPRINT_HISTORY_LIMIT=10
# Isolate history/cache/targets/config for tests
export XDG_DATA_HOME="${TMP}-xdg/data"
export XDG_CACHE_HOME="${TMP}-xdg/cache"
export XDG_CONFIG_HOME="${TMP}-xdg/config"
export BLUEPRINT_TARGETS_FILE="${TMP}-targets.json"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
rm -rf "$TMP" "${TMP}-targets.json"
mkdir -p "$TMP"
echo "== install (bootstrap) =="
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" 2>&1)"
assert_file "AGENTS.md written" "$TMP/AGENTS.md"
assert_file "HARNESS.md written" "$TMP/HARNESS.md"
assert_file "state written" "$TMP/.agent-blueprint.yaml"
assert_dir "cursor from bootstrap install" "$TMP/.cursor/commands"
assert_contains "gitignore ignores .agents/" "$(cat "$TMP/.gitignore")" $'.agents/'
assert_contains "gitignore ignores .testiny/" "$(cat "$TMP/.gitignore")" $'.testiny/'
assert_line "install gitignore rebases .cursor/" "$TMP/.gitignore" ".cursor/"
assert_line "install gitignore rebases .claude/" "$TMP/.gitignore" ".claude/"
assert_line "install gitignore rebases .agents/" "$TMP/.gitignore" ".agents/"
assert_not_contains "install gitignore has no placeholder" "$(cat "$TMP/.gitignore")" "{{RUNTIME_IGNORES}}"
assert_contains "install summary" "$out" "Blueprint synchronization completed"
assert_contains "install harness banner" "$out" "Blueprint initialized"
assert_contains "managed harness markers" "$(cat "$TMP/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_contains "run id present" "$out" "Run  bp-"
assert_not_contains "no ANSI clear in CI" "$out" $'\033[2J'
set +e
out_init="$(CI=1 NO_COLOR=1 "$BP" init --target "$TMP" 2>&1)"
rc_init=$?
set -e
assert_eq "init command removed" "$rc_init" "1"
assert_contains "init points to install" "$out_init" "init was removed"

echo "== auth =="
out="$(CI=1 NO_COLOR=1 "$BP" auth --help 2>&1)"
assert_contains "auth help mentions login" "$out" "login github"
out="$(CI=1 NO_COLOR=1 "$BP" auth git --name "Blueprint Tester" --email "tester@example.com" 2>&1)"
assert_contains "auth git saved" "$out" "saved git identity"
assert_file "git identity file" "${XDG_CONFIG_HOME}/blueprint/credentials/git"
assert_contains "identity name" "$(cat "${XDG_CONFIG_HOME}/blueprint/credentials/git")" "name=Blueprint Tester"
assert_contains "identity email" "$(cat "${XDG_CONFIG_HOME}/blueprint/credentials/git")" "email=tester@example.com"
out="$(CI=1 NO_COLOR=1 "$BP" auth status 2>&1)"
assert_contains "auth status shows identity" "$out" "tester@example.com"
auth_t="${TMP}-auth"
saved_targets_auth="$BLUEPRINT_TARGETS_FILE"
export BLUEPRINT_TARGETS_FILE="${TMP}-auth-targets.json"
rm -rf "$auth_t" "$BLUEPRINT_TARGETS_FILE"
mkdir -p "$auth_t"
git -C "$auth_t" init -q
git -C "$auth_t" config user.email "before@example.com"
git -C "$auth_t" config user.name "Before"
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$auth_t" 2>&1)"
assert_contains "install applied git name" "$out" "git user.name"
assert_eq "local user.name from blueprint" "$(git -C "$auth_t" config --local user.name)" "Blueprint Tester"
assert_eq "local user.email from blueprint" "$(git -C "$auth_t" config --local user.email)" "tester@example.com"
set +e
out="$(CI=1 NO_COLOR=1 "$BP" doctor --target "$auth_t" 2>&1)"
set -e
assert_contains "doctor reports git identity" "$out" "git identity"
rm -rf "$auth_t" "$BLUEPRINT_TARGETS_FILE"
export BLUEPRINT_TARGETS_FILE="$saved_targets_auth"

echo "== install =="
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" 2>&1)"
assert_dir "cursor commands" "$TMP/.cursor/commands"
assert_file "start command" "$TMP/.cursor/commands/start.md"
assert_contains "install completed" "$out" "Blueprint synchronization completed"
assert_contains "source validated" "$out" "Validating source repository"
assert_contains "default skill_mode rebase" "$(cat "$TMP/.agent-blueprint.yaml")" "skill_mode: rebase"
assert_line "rebase install keeps .cursor/" "$TMP/.gitignore" ".cursor/"

echo "== skill-mode merge =="
saved_targets_file="$BLUEPRINT_TARGETS_FILE"
export BLUEPRINT_TARGETS_FILE="${TMP}-merge-targets.json"
merge_t="${TMP}-merge"
rm -rf "$merge_t"
mkdir -p "$merge_t"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$merge_t" >/dev/null
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --skill-mode merge --target "$merge_t" 2>&1)"
assert_contains "merge install completed" "$out" "Blueprint synchronization completed"
assert_contains "state skill_mode merge" "$(cat "$merge_t/.agent-blueprint.yaml")" "skill_mode: merge"
assert_not_line "merge does not ignore whole .cursor/" "$merge_t/.gitignore" ".cursor/"
assert_not_line "merge does not ignore whole .claude/" "$merge_t/.gitignore" ".claude/"
assert_not_line "merge does not ignore whole .agents/" "$merge_t/.gitignore" ".agents/"
assert_line "merge ignores skill tree" "$merge_t/.gitignore" ".cursor/skills/task-execution/*"
assert_line "merge ignores cursor rule" "$merge_t/.gitignore" ".cursor/rules/task-execution.mdc"
assert_line "merge ignores start command" "$merge_t/.gitignore" ".cursor/commands/start.md"
assert_line "merge ignores adr template" "$merge_t/.gitignore" ".cursor/templates/adr.md"
assert_contains "merge keeps .testiny/" "$(cat "$merge_t/.gitignore")" $'.testiny/'
assert_file "merge still projects skill" "$merge_t/.cursor/skills/task-execution/SKILL.md"

out="$(CI=1 NO_COLOR=1 "$BP" sync --target "$merge_t" 2>&1)"
assert_contains "sync preserves merge" "$out" "skill-mode=merge"
assert_not_line "sync keeps merge gitignore" "$merge_t/.gitignore" ".cursor/"
assert_line "sync keeps merge skill ignore" "$merge_t/.gitignore" ".cursor/skills/task-execution/*"

out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --skill-mode rebase --target "$merge_t" 2>&1)"
assert_contains "rebase switch completed" "$out" "Blueprint synchronization completed"
assert_contains "state skill_mode rebase after switch" "$(cat "$merge_t/.agent-blueprint.yaml")" "skill_mode: rebase"
assert_line "rebase switch restores .cursor/" "$merge_t/.gitignore" ".cursor/"
assert_not_line "rebase switch drops skill glob" "$merge_t/.gitignore" ".cursor/skills/task-execution/*"

merge_c="${TMP}-merge-claude"
rm -rf "$merge_c"
mkdir -p "$merge_c"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$merge_c" >/dev/null
CI=1 NO_COLOR=1 "$BP" install default --runtime claude --skill-mode merge --target "$merge_c" >/dev/null
assert_line "merge claude rule is .md" "$merge_c/.gitignore" ".claude/rules/task-execution.md"
assert_not_line "merge claude rule is not .mdc" "$merge_c/.gitignore" ".claude/rules/task-execution.mdc"

merge_g="${TMP}-merge-gitlab"
rm -rf "$merge_g"
mkdir -p "$merge_g"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$merge_g" >/dev/null
CI=1 NO_COLOR=1 "$BP" install engineering --overlay gitlab --runtime cursor --skill-mode merge --target "$merge_g" >/dev/null
assert_line "merge gitlab overlay command ignored" "$merge_g/.gitignore" ".cursor/commands/pr.md"

set +e
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --skill-mode bogus --target "$merge_t" 2>&1)"
rc=$?
set -e
assert_eq "invalid skill-mode exits 2" "$rc" "2"
assert_contains "invalid skill-mode message" "$out" "unknown --skill-mode"
export BLUEPRINT_TARGETS_FILE="$saved_targets_file"
rm -f "${TMP}-merge-targets.json"

echo "== sync =="
out="$(CI=1 NO_COLOR=1 "$BP" sync --target "$TMP" 2>&1)"
assert_eq "sync exit" "0" "0"
assert_contains "sync completed" "$out" "Blueprint synchronization completed"

echo "== dry-run =="
before="$(find "$TMP/.cursor" -type f | wc -l | tr -d ' ')"
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" --dry-run 2>&1)"
after="$(find "$TMP/.cursor" -type f | wc -l | tr -d ' ')"
assert_eq "dry-run no new files" "$before" "$after"
assert_contains "dry-run events" "$out" "Run  bp-"

echo "== conflict =="
# Unmanaged local runtime file should get conflict sibling, not overwrite.
mkdir -p "$TMP/.cursor/commands"
printf 'local start\n' > "$TMP/.cursor/commands/start.md"
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" 2>&1)"
assert_file "conflict sibling" "$TMP/.cursor/commands/start.md.blueprint-conflict"
content="$(cat "$TMP/.cursor/commands/start.md")"
assert_eq "local start preserved" "$content" "local start"
assert_contains "conflict message" "$out" "Conflict:"
assert_contains "project conflict warning" "$out" "has "
assert_contains "project conflict warning count" "$out" "conflict"
assert_contains "summary Conflict line" "$out" "Conflict"

echo "== conflict --force =="
printf 'local start force\n' > "$TMP/.cursor/commands/start.md"
# Stale sibling from a prior conflict must be cleared by a successful force write.
printf 'stale package copy\n' > "$TMP/.cursor/commands/start.md.blueprint-conflict"
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" --force 2>&1)"
assert_not_file "no conflict sibling after force" "$TMP/.cursor/commands/start.md.blueprint-conflict"
content="$(cat "$TMP/.cursor/commands/start.md")"
assert_contains "force overwrote local" "$content" "managed-by: shared-agent-blueprints"
if [[ "$content" == "local start force" ]]; then
  echo "  FAIL  force should not leave local-only content"
  FAIL=$((FAIL + 1))
else
  echo "  PASS  force replaced local content"
  PASS=$((PASS + 1))
fi
assert_contains "force cleared stale sibling msg" "$out" "removed stale conflict sibling"

echo "== doctor reports conflicts =="
printf 'local again\n' > "$TMP/.cursor/commands/review.md"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" >/dev/null 2>&1
assert_file "review conflict sibling" "$TMP/.cursor/commands/review.md.blueprint-conflict"
out="$(CI=1 NO_COLOR=1 "$BP" doctor --target "$TMP" 2>&1)"
assert_contains "doctor conflict warning" "$out" "unresolved *.blueprint-conflict"
# Clean sibling so later assertions are not polluted.
rm -f "$TMP/.cursor/commands/"*.blueprint-conflict
# Restore managed review from package on next sync path if needed.
echo "== agent files preserved on install =="
printf 'user agents\n' > "$TMP/AGENTS.md"
before_agents="$(cat "$TMP/AGENTS.md")"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" >/dev/null 2>&1
assert_eq "install leaves AGENTS.md" "$(cat "$TMP/AGENTS.md")" "$before_agents"
echo "== sync without state =="
empty="${TMP}-empty"
rm -rf "$empty"
mkdir -p "$empty"
set +e
out="$(CI=1 NO_COLOR=1 "$BP" sync --target "$empty" 2>&1)"
rc=$?
set -e
assert_eq "sync missing state fails" "$rc" "1"
assert_contains "missing state message" "$out" "no .agent-blueprint.yaml"

echo "== narrow terminal =="
out="$(CI=1 NO_COLOR=1 COLUMNS=40 "$BP" doctor --target "$TMP" 2>&1)"
assert_contains "narrow doctor" "$out" "Healthy"

echo "== monochrome / non-TTY symbols =="
out="$(CI=1 NO_COLOR=1 "$BP" doctor --target "$ROOT" 2>&1)"
assert_contains "doctor package mode" "$out" "package-source"
assert_contains "lib modules checked" "$out" "lib/blueprint"
assert_contains "skill naming ok" "$out" "package skills match naming standard"
assert_file "generate-test-cases skill" "$CORE_PACK/harness/skills/generate-test-cases/SKILL.md"
assert_contains "generate-test-cases name" "$(head -5 "$CORE_PACK/harness/skills/generate-test-cases/SKILL.md")" "name: generate-test-cases"
assert_contains "renames log has testcase rename" "$(cat "$CORE_PACK/harness/migrations/renames.log")" "testcase-generator"

echo "== history written =="
hist="${XDG_DATA_HOME}/blueprint/history.jsonl"
assert_file "history jsonl" "$hist"
assert_contains "history has runId" "$(head -1 "$hist")" '"runId"'

echo "== targets registry =="
# Isolate from earlier install noise on the shared targets file.
saved_targets_registry="$BLUEPRINT_TARGETS_FILE"
export BLUEPRINT_TARGETS_FILE="${TMP}-targets-registry.json"
rm -f "$BLUEPRINT_TARGETS_FILE"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" >/dev/null 2>&1
assert_file "targets.json written" "$BLUEPRINT_TARGETS_FILE"
assert_contains "targets has path" "$(cat "$BLUEPRINT_TARGETS_FILE")" "$TMP"
assert_contains "targets has version" "$(cat "$BLUEPRINT_TARGETS_FILE")" '"version"'
# Second consumer should upsert a distinct path (newest first).
other="${TMP}-other"
rm -rf "$other"
mkdir -p "$other"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$other" >/dev/null 2>&1
tg="$(cat "$BLUEPRINT_TARGETS_FILE")"
assert_contains "targets has second path" "$tg" "$other"
# Count path entries (should be 2 unique).
path_count="$(printf '%s' "$tg" | grep -c '"path"' || true)"
assert_eq "targets unique count" "$path_count" "2"
# Re-install same target should not duplicate.
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$TMP" >/dev/null 2>&1
path_count="$(grep -c '"path"' "$BLUEPRINT_TARGETS_FILE" || true)"
assert_eq "targets upsert no duplicate" "$path_count" "2"
rm -rf "$other" "$BLUEPRINT_TARGETS_FILE"
export BLUEPRINT_TARGETS_FILE="$saved_targets_registry"

echo "== install codex =="
codex_t="${TMP}-codex"
rm -rf "$codex_t"
mkdir -p "$codex_t"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$codex_t" >/dev/null 2>&1
out="$(CI=1 NO_COLOR=1 "$BP" install default --runtime codex --target "$codex_t" 2>&1)"
assert_contains "codex install completed" "$out" "Blueprint synchronization completed"
assert_dir "codex skills" "$codex_t/.agents/skills"
assert_file "codex context-recall" "$codex_t/.agents/skills/context-recall/SKILL.md"
assert_file "codex start command" "$codex_t/.agents/commands/start.md"
assert_file "codex rule md" "$codex_t/.agents/rules/safety-rules.md"
assert_eq "codex no mdc rules" "$([[ -f "$codex_t/.agents/rules/safety-rules.mdc" ]] && echo yes || echo no)" "no"
assert_contains "state lists codex" "$(cat "$codex_t/.agent-blueprint.yaml")" "codex"
rm -rf "$codex_t"

echo "== remote fetchable detection (unit via bash) =="
# shellcheck source=lib/blueprint/repo.sh
source "${ROOT}/lib/blueprint/term.sh"
source "${ROOT}/lib/blueprint/repo.sh"
if repo_is_fetchable "https://github.com/example/shared-blueprint"; then
  echo "  PASS  https URL fetchable"
  PASS=$((PASS + 1))
else
  echo "  FAIL  https URL fetchable"
  FAIL=$((FAIL + 1))
fi
if ! repo_is_fetchable "agent-harness-blueprint"; then
  echo "  PASS  bare name not fetchable"
  PASS=$((PASS + 1))
else
  echo "  FAIL  bare name not fetchable"
  FAIL=$((FAIL + 1))
fi

echo "== file:// cache clone =="
# Create a bare-ish git repo copy for file:// fetch without network.
# Keep outside the package tree so path substring matching cannot confuse identity.
src_repo="$(mktemp -d "${TMPDIR:-/tmp}/bp-src-XXXXXX")"
rm -rf "$src_repo"
mkdir -p "$src_repo"
# Fixture mimics a CLI+pack layout using the assets core pack (no in-tree legacy mirrors).
cp -R "${CORE_PACK}/harness" "${CORE_PACK}/blueprints" "${CORE_PACK}/templates" "${CORE_PACK}/manifest.yaml" "$src_repo/"
cp "${ROOT}/VERSION" "$src_repo/VERSION"
mkdir -p "${src_repo}/prompts/system"
echo "# sys" > "${src_repo}/prompts/system/README.md"
cp "${ROOT}/blueprint" "$src_repo/blueprint"
mkdir -p "${src_repo}/lib"
cp -R "${ROOT}/lib/blueprint" "${src_repo}/lib/"
(
  cd "$src_repo"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  git add -A
  git commit -qm "fixture"
)
consumer="${TMP}-remote-consumer"
rm -rf "$consumer"
mkdir -p "$consumer"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$consumer" >/dev/null 2>&1
abs_src="$(cd "$src_repo" && pwd)"
pkg_ver="$(tr -d '[:space:]' < "${ROOT}/VERSION")"
cat > "${consumer}/.agent-blueprint.yaml" <<EOF
source: file://${abs_src}
version: ${pkg_ver}
blueprint: default
overlay: null
runtimes:
  - cursor
installed_at_utc: 2026-01-01T00:00:00Z
conflict_policy: preserve-local
EOF
out="$(CI=1 NO_COLOR=1 "$BP" sync --target "$consumer" 2>&1)"
assert_contains "fetched from file url" "$out" "Fetching source repository"
assert_dir "remote sync wrote cursor" "$consumer/.cursor/commands"
rm -rf "$src_repo" "$consumer"

echo "== del =="
# Rebuild a clean consumer for removal tests.
del_t="${TMP}-del"
rm -rf "$del_t"
mkdir -p "$del_t"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$del_t" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" install default --runtime all --target "$del_t" >/dev/null 2>&1
printf 'keep this planning\n' > "$del_t/PLANNING.md"
printf 'user note\n' > "$del_t/AGENTS.md"
# Inject managed harness ref so del has something to strip (re-install preserves AGENTS.md).
cat >> "$del_t/AGENTS.md" <<'EOF'
<!-- BLUEPRINT:HARNESS:START -->
## Shared Harness
See [`HARNESS.md`](./HARNESS.md).
<!-- BLUEPRINT:HARNESS:END -->
EOF
assert_contains "agents has ref before del" "$(cat "$del_t/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_file "harness before del" "$del_t/HARNESS.md"
assert_dir "cursor before del" "$del_t/.cursor"
assert_dir "claude before del" "$del_t/.claude"
assert_dir "agents before del" "$del_t/.agents"
assert_file "planning before del" "$del_t/PLANNING.md"

set +e
out="$(CI=1 NO_COLOR=1 "$BP" del --target "$del_t" 2>&1)"
rc=$?
set -e
assert_eq "del without --force fails in CI" "$rc" "1"
assert_contains "del needs force" "$out" "--force"

out="$(CI=1 NO_COLOR=1 "$BP" del --force --target "$del_t" 2>&1)"
assert_contains "del completed" "$out" "Blueprint removal completed"
assert_eq "HARNESS.md removed" "$([[ -f "$del_t/HARNESS.md" ]] && echo yes || echo no)" "no"
assert_eq "state removed" "$([[ -f "$del_t/.agent-blueprint.yaml" ]] && echo yes || echo no)" "no"
assert_eq "cursor removed" "$([[ -d "$del_t/.cursor" ]] && echo yes || echo no)" "no"
assert_eq "claude removed" "$([[ -d "$del_t/.claude" ]] && echo yes || echo no)" "no"
assert_eq "agents removed" "$([[ -d "$del_t/.agents" ]] && echo yes || echo no)" "no"
assert_eq "PLANNING removed" "$([[ -f "$del_t/PLANNING.md" ]] && echo yes || echo no)" "no"
assert_eq "DECISIONS removed" "$([[ -f "$del_t/DECISIONS.md" ]] && echo yes || echo no)" "no"
assert_eq "RUN_LOG removed" "$([[ -f "$del_t/RUN_LOG.md" ]] && echo yes || echo no)" "no"
assert_eq "HOTCACHE removed" "$([[ -f "$del_t/HOTCACHE.md" ]] && echo yes || echo no)" "no"
assert_eq "LEARNING removed" "$([[ -f "$del_t/LEARNING.md" ]] && echo yes || echo no)" "no"
assert_eq "ANTI-PATTERNS removed" "$([[ -f "$del_t/ANTI-PATTERNS.md" ]] && echo yes || echo no)" "no"
assert_file "AGENTS.md preserved" "$del_t/AGENTS.md"
assert_not_contains "harness ref stripped" "$(cat "$del_t/AGENTS.md")" "<!-- BLUEPRINT:HARNESS:START -->"
assert_not_contains "managed gitignore gone" "$(cat "$del_t/.gitignore" 2>/dev/null || true)" "# --- shared-agent-blueprints (managed) ---"
rm -rf "$del_t"

echo "== del preserves custom skills =="
custom_t="${TMP}-del-custom"
rm -rf "$custom_t"
mkdir -p "$custom_t"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$custom_t" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --skill-mode merge --target "$custom_t" >/dev/null 2>&1
mkdir -p "$custom_t/.cursor/skills/my-local-skill" "$custom_t/.cursor/skills/memory-system-protocol"
printf '# custom skill\n' > "$custom_t/.cursor/skills/my-local-skill/SKILL.md"
printf '# leftover renamed blueprint skill\n' > "$custom_t/.cursor/skills/memory-system-protocol/SKILL.md"
printf '{}\n' > "$custom_t/.cursor/mcp.json"
assert_file "blueprint skill present before del" "$custom_t/.cursor/skills/task-execution/SKILL.md"
out="$(CI=1 NO_COLOR=1 "$BP" rm --force --target "$custom_t" 2>&1)"
assert_contains "del custom completed" "$out" "Blueprint removal completed"
assert_file "custom skill preserved" "$custom_t/.cursor/skills/my-local-skill/SKILL.md"
assert_file "custom mcp.json preserved" "$custom_t/.cursor/mcp.json"
assert_dir "cursor root kept for custom files" "$custom_t/.cursor"
assert_not_file "blueprint skill removed" "$custom_t/.cursor/skills/task-execution/SKILL.md"
assert_not_file "obsolete renamed skill removed" "$custom_t/.cursor/skills/memory-system-protocol/SKILL.md"
assert_not_file "blueprint start command removed" "$custom_t/.cursor/commands/start.md"
rm -rf "$custom_t"

# Help documents keyword-only del. Run with --target package so contributor help shows.
help_out="$(CI=1 NO_COLOR=1 "$BP" help --target "$ROOT" 2>&1)"
assert_contains "help lists del" "$help_out" "del"
assert_contains "help lists rm alias" "$help_out" "rm | del"
assert_contains "help lists skill-mode" "$help_out" "--skill-mode"
assert_contains "help lists codex runtime" "$help_out" "codex"
assert_contains "help keyword note" "$help_out" "keyword only"
assert_contains "help lists install-contributor" "$help_out" "install-contributor"
assert_contains "help target package names" "$help_out" "agent-harness-blueprint"
assert_contains "help target workspace name" "$help_out" "blueprint                 → workspace root"
assert_contains "help force example" "$help_out" "update --force --target"
assert_contains "help menu force note" "$help_out" 'Typing "update --force" in the'
assert_contains "help lists clean" "$help_out" "clean"
assert_contains "help clean example" "$help_out" "clean --force --target"
help_consumer="$(CI=1 NO_COLOR=1 "$BP" help --target "$TMP" 2>&1)"
assert_not_contains "help hides contributor for consumer" "$help_consumer" "install-contributor"
# Named --target: workspace table vs individual package repos.
help_ws="$(CI=1 NO_COLOR=1 "$BP" help --target blueprint 2>&1)"
assert_contains "help --target blueprint (workspace) shows contrib" "$help_ws" "install-contributor"
assert_contains "help workspace examples" "$help_ws" "--target blueprint"
help_pkg="$(CI=1 NO_COLOR=1 "$BP" help --target agent-harness-blueprint 2>&1)"
assert_contains "help --target agent-harness-blueprint shows contrib" "$help_pkg" "install-contributor"
if [[ -d "${ROOT}/../assets-blueprint" ]]; then
  help_assets="$(CI=1 NO_COLOR=1 "$BP" help --target assets-blueprint 2>&1)"
  assert_contains "help --target assets-blueprint shows contrib" "$help_assets" "install-contributor"
fi
if [[ -d "${ROOT}/../homebrew-blueprint" ]]; then
  help_brew="$(CI=1 NO_COLOR=1 "$BP" help --target homebrew-blueprint 2>&1)"
  assert_contains "help --target homebrew-blueprint shows contrib" "$help_brew" "install-contributor"
fi
set +e
bad_alias="$(CI=1 NO_COLOR=1 "$BP" help --target not-a-blueprint-package 2>&1)"
bad_rc=$?
set -e
assert_eq "unknown name help still exits 0" "$bad_rc" "0"
assert_not_contains "unknown name hides contrib" "$bad_alias" "install-contributor"
rm -rf "$del_t"

echo "== clean backups =="
clean_t="${TMP}-clean"
rm -rf "$clean_t"
mkdir -p "$clean_t/.cursor/commands"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$clean_t" >/dev/null 2>&1
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$clean_t" >/dev/null 2>&1
printf 'old local\n' > "$clean_t/.cursor/commands/start.md.blueprint-backup.20260813T000000Z"
printf 'old local2\n' > "$clean_t/.cursor/commands/review.md.blueprint-backup.20260813T000000Z"
bak_n="$(find "$clean_t" -name '*.blueprint-backup.*' -type f | wc -l | tr -d ' ')"
assert_eq "backup count before clean" "$bak_n" "2"
set +e
out="$(CI=1 NO_COLOR=1 "$BP" clean --target "$clean_t" 2>&1)"
rc=$?
set -e
assert_eq "clean without --force fails in CI" "$rc" "1"
assert_contains "clean needs force" "$out" "--force"
assert_file "backup still present without force" "$clean_t/.cursor/commands/start.md.blueprint-backup.20260813T000000Z"
out="$(CI=1 NO_COLOR=1 "$BP" clean --force --target "$clean_t" 2>&1)"
assert_not_file "backup removed by clean" "$clean_t/.cursor/commands/start.md.blueprint-backup.20260813T000000Z"
assert_not_file "second backup removed" "$clean_t/.cursor/commands/review.md.blueprint-backup.20260813T000000Z"
assert_contains "clean deleted count" "$out" "deleted 2 backup"
out="$(CI=1 NO_COLOR=1 "$BP" doctor --target "$clean_t" 2>&1)"
assert_contains "doctor no backups" "$out" "no *.blueprint-backup.* leftovers"
rm -rf "$clean_t"

echo "== install-contributor =="
set +e
out="$(CI=1 NO_COLOR=1 "$BP" install-contributor --runtime cursor --target "$TMP" 2>&1)"
rc=$?
set -e
assert_eq "install-contributor rejects consumer target" "$rc" "1"
assert_contains "install-contributor package-only msg" "$out" "workspace table or a package repo"
assert_eq "consumer has no contributor-standards" \
  "$([[ -f "$TMP/.cursor/rules/contributor-standards.mdc" ]] && echo yes || echo no)" "no"

# Package root without prior install must fail (add-on on top of install).
rm -rf "${ROOT}/.cursor" "${ROOT}/.claude" "${ROOT}/.agents"
rm -f "${ROOT}/.agent-blueprint.local.yaml" "${ROOT}/.agent-blueprint.yaml"
set +e
out="$(CI=1 NO_COLOR=1 "$BP" install-contributor --runtime cursor --target "$ROOT" 2>&1)"
rc=$?
set -e
assert_eq "install-contributor needs install first" "$rc" "1"
assert_contains "install-contributor install-first msg" "$out" "run install first"

# Install harness, then layer contributor add-on (gitignored), verify doctor, clean up.
# Preserve committed package AGENTS.md (install may reconcile harness markers).
agents_bak="$(mktemp "${TMP}.agents.bak.XXXXXX")"
cp "${ROOT}/AGENTS.md" "$agents_bak"
rm -rf "${ROOT}/.cursor" "${ROOT}/.claude" "${ROOT}/.agents"
rm -f "${ROOT}/.agent-blueprint.local.yaml" "${ROOT}/.agent-blueprint.yaml"
rm -f "${ROOT}/HARNESS.md" "${ROOT}/PLANNING.md" "${ROOT}/DECISIONS.md" "${ROOT}/RUN_LOG.md" \
  "${ROOT}/HOTCACHE.md" "${ROOT}/LEARNING.md" "${ROOT}/ANTI-PATTERNS.md"
CI=1 NO_COLOR=1 "$BP" install default --runtime cursor --target "$ROOT" >/dev/null 2>&1
out="$(CI=1 NO_COLOR=1 "$BP" install-contributor --runtime cursor --target "$ROOT" 2>&1)"
assert_contains "install-contributor completed" "$out" "Blueprint synchronization completed"
assert_contains "install-contributor add-on note" "$out" "contributor add-on"
assert_file "contributor commit command" "$ROOT/.cursor/commands/commit.md"
assert_file "contributor pr command" "$ROOT/.cursor/commands/pr.md"
assert_file "contributor standards rule" "$ROOT/.cursor/rules/contributor-standards.mdc"
assert_file "skill-creator projected" "$ROOT/.cursor/skills/skill-creator/SKILL.md"
assert_file "update-changelog projected" "$ROOT/.cursor/skills/update-changelog/SKILL.md"
assert_file "contributor local marker" "$ROOT/.agent-blueprint.local.yaml"
assert_contains "marker profile" "$(cat "$ROOT/.agent-blueprint.local.yaml")" "package-contributor"
assert_contains "contributor commit no jira" "$(cat "$ROOT/.cursor/commands/commit.md")" "No JIRA"
set +e
out="$(CI=1 NO_COLOR=1 "$BP" doctor --target "$ROOT" 2>&1)"
set -e
assert_contains "doctor healthy with contributor runtime" "$out" "Healthy"
assert_contains "doctor allows local cursor" "$out" "package-contributor local runtime"
rm -rf "${ROOT}/.cursor" "${ROOT}/.claude" "${ROOT}/.agents"
rm -f "${ROOT}/.agent-blueprint.local.yaml" "${ROOT}/.agent-blueprint.yaml"
rm -f "${ROOT}/HARNESS.md" "${ROOT}/PLANNING.md" "${ROOT}/DECISIONS.md" "${ROOT}/RUN_LOG.md" \
  "${ROOT}/HOTCACHE.md" "${ROOT}/LEARNING.md" "${ROOT}/ANTI-PATTERNS.md"
cp "$agents_bak" "${ROOT}/AGENTS.md"
rm -f "$agents_bak"
set +e
out="$(CI=1 NO_COLOR=1 "$BP" doctor --target "$ROOT" 2>&1)"
set -e
assert_contains "doctor healthy after contributor cleanup" "$out" "Healthy"

echo
echo "== landing update check =="
UPD_CACHE="$(mktemp -d "${TMP}/upd-cache.XXXXXX")"
export XDG_CACHE_HOME="$UPD_CACHE"
# Shell helpers under test (same modules the CLI sources).
# shellcheck disable=SC1091
source "${ROOT}/lib/blueprint/term.sh"
# shellcheck disable=SC1091
source "${ROOT}/lib/blueprint/xdg.sh"
# shellcheck disable=SC1091
source "${ROOT}/lib/blueprint/assets.sh"
normalize_version() {
  local v="${1:-}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  v="${v#v}"
  v="${v#V}"
  printf '%s' "$v"
}
package_version() {
  tr -d '[:space:]' < "${ROOT}/VERSION"
}
# shellcheck disable=SC1091
source "${ROOT}/lib/blueprint/updates.sh"
# shellcheck disable=SC1091
source "${ROOT}/lib/blueprint/render.sh"
term_init
BP_IS_TTY=0
BP_USE_COLOR=0
BP_IS_CI=1

if updates_version_gt "1.6.0" "1.5.0"; then
  echo "  PASS  updates_version_gt newer"
  PASS=$((PASS + 1))
else
  echo "  FAIL  updates_version_gt newer"
  FAIL=$((FAIL + 1))
fi
if updates_version_gt "1.5.0" "1.5.0"; then
  echo "  FAIL  updates_version_gt equal should be false"
  FAIL=$((FAIL + 1))
else
  echo "  PASS  updates_version_gt equal false"
  PASS=$((PASS + 1))
fi
if updates_version_lt "1.5.0" "1.6.0"; then
  echo "  PASS  updates_version_lt older"
  PASS=$((PASS + 1))
else
  echo "  FAIL  updates_version_lt older"
  FAIL=$((FAIL + 1))
fi

LOCAL_CLI="$(package_version)"
LOCAL_CORE="$(assets_pack_version_file "${CORE_PACK}")"

# Offline + no force → silent
unset BLUEPRINT_UPDATE_FORCE_CLI_LATEST BLUEPRINT_UPDATE_FORCE_CORE_LATEST || true
unset BLUEPRINT_UPDATE_FORCE_CORE_LATEST || true
export BLUEPRINT_OFFLINE=1
export BLUEPRINT_UPDATE_TTL=0
updates_ensure_checked
panel="$(render_update_announcement 2>&1 || true)"
assert_not_contains "offline: no UPDATE AVAILABLE panel" "$panel" "UPDATE AVAILABLE"
assert_eq "offline: has_update=0" "${BP_UPDATE_HAS_UPDATE:-0}" "0"
unset BLUEPRINT_OFFLINE

# Both outdated
export BLUEPRINT_UPDATE_FORCE_CLI_LATEST="9.9.9"
export BLUEPRINT_UPDATE_FORCE_CORE_LATEST="9.9.9"
export BLUEPRINT_UPDATE_TTL=0
rm -f "$(updates_cache_path)" 2>/dev/null || true
updates_ensure_checked
panel="$(render_update_announcement 2>&1 || true)"
assert_contains "both: panel title" "$panel" "UPDATE AVAILABLE"
assert_contains "both: CLI row" "$panel" "blueprint CLI"
assert_contains "both: brew command" "$panel" "brew upgrade blueprint"
assert_contains "both: skills row" "$panel" "skills core"
assert_contains "both: assets command" "$panel" "blueprint assets update core"
assert_eq "both: has_update" "${BP_UPDATE_HAS_UPDATE}" "1"

# CLI only
export BLUEPRINT_UPDATE_FORCE_CLI_LATEST="9.9.9"
export BLUEPRINT_UPDATE_FORCE_CORE_LATEST="$LOCAL_CORE"
rm -f "$(updates_cache_path)" 2>/dev/null || true
updates_ensure_checked
panel="$(render_update_announcement 2>&1 || true)"
assert_contains "cli-only: panel" "$panel" "UPDATE AVAILABLE"
assert_contains "cli-only: CLI row" "$panel" "blueprint CLI"
assert_not_contains "cli-only: no skills row" "$panel" "skills core"

# Core only
export BLUEPRINT_UPDATE_FORCE_CLI_LATEST="$LOCAL_CLI"
export BLUEPRINT_UPDATE_FORCE_CORE_LATEST="9.9.9"
rm -f "$(updates_cache_path)" 2>/dev/null || true
updates_ensure_checked
panel="$(render_update_announcement 2>&1 || true)"
assert_contains "core-only: panel" "$panel" "UPDATE AVAILABLE"
assert_contains "core-only: skills row" "$panel" "skills core"
assert_not_contains "core-only: no CLI row" "$panel" "blueprint CLI"

# Up to date → silent
export BLUEPRINT_UPDATE_FORCE_CLI_LATEST="$LOCAL_CLI"
export BLUEPRINT_UPDATE_FORCE_CORE_LATEST="$LOCAL_CORE"
rm -f "$(updates_cache_path)" 2>/dev/null || true
updates_ensure_checked
panel="$(render_update_announcement 2>&1 || true)"
assert_not_contains "uptodate: no panel" "$panel" "UPDATE AVAILABLE"
assert_eq "uptodate: has_update=0" "${BP_UPDATE_HAS_UPDATE}" "0"

# Cache hit: write outdated cache, then ensure with high TTL and no force → still shows
unset BLUEPRINT_UPDATE_FORCE_CLI_LATEST BLUEPRINT_UPDATE_FORCE_CORE_LATEST
export BLUEPRINT_UPDATE_TTL=99999
BP_UPDATE_CLI_CURRENT="1.0.0"
BP_UPDATE_CLI_LATEST="9.9.9"
BP_UPDATE_CLI_OUTDATED=1
BP_UPDATE_CORE_CURRENT=""
BP_UPDATE_CORE_LATEST=""
BP_UPDATE_CORE_OUTDATED=0
BP_UPDATE_HAS_UPDATE=1
updates_write_cache
updates_ensure_checked
panel="$(render_update_announcement 2>&1 || true)"
assert_contains "cache-hit: panel from cache" "$panel" "UPDATE AVAILABLE"
assert_contains "cache-hit: CLI from cache" "$panel" "blueprint CLI"
unset BLUEPRINT_UPDATE_TTL
rm -rf "$UPD_CACHE"

echo
echo "Results: ${PASS} passed, ${FAIL} failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
