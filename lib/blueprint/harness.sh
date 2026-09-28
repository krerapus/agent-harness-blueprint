# HARNESS.md install + managed agent-entrypoint reference helpers.
# shellcheck shell=bash

HARNESS_FILE_NAME="HARNESS.md"
HARNESS_REF_START="<!-- BLUEPRINT:HARNESS:START -->"
HARNESS_REF_END="<!-- BLUEPRINT:HARNESS:END -->"
HARNESS_FILE_MARKER="<!-- managed-by: shared-agent-blueprints -->"

# Populated by detect_agent_entrypoint
HARNESS_SELECTED_PATH=""
# AGENTS.md | agents.md | CLAUDE.md | claude.md | created
HARNESS_SELECTED_SOURCE=""
HARNESS_CLAUDE_DETECTED=0
HARNESS_WARNINGS=()

# Summary fields for CLI output
HARNESS_SUMMARY_HARNESS=""
HARNESS_SUMMARY_AGENT=""
HARNESS_SUMMARY_REF=""
HARNESS_SUMMARY_CLAUDE=""

harness_template_path() {
  echo "${PACKAGE_ROOT}/templates/entrypoints/HARNESS.md"
}

# Case-sensitive exact basename match (important on case-insensitive volumes).
harness_exact_exists() {
  local dir="$1"
  local name="$2"
  local f base
  shopt -s nullglob dotglob
  for f in "${dir}"/* "${dir}"/.[!.]* "${dir}"/..?*; do
    [[ -e "$f" ]] || continue
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    if [[ "$base" == "$name" ]]; then
      shopt -u nullglob dotglob
      return 0
    fi
  done
  shopt -u nullglob dotglob
  return 1
}

harness_exact_path() {
  local dir="$1"
  local name="$2"
  local f base
  shopt -s nullglob dotglob
  for f in "${dir}"/* "${dir}"/.[!.]* "${dir}"/..?*; do
    [[ -e "$f" ]] || continue
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    if [[ "$base" == "$name" ]]; then
      printf '%s\n' "$f"
      shopt -u nullglob dotglob
      return 0
    fi
  done
  shopt -u nullglob dotglob
  return 1
}

agents_template_path() {
  echo "${PACKAGE_ROOT}/templates/entrypoints/AGENTS.md"
}

# Compact managed integration block for existing instruction files.
# References Blueprint-managed files only — does not duplicate full harness context.
harness_managed_block() {
  cat <<EOF
${HARNESS_REF_START}
## Shared Harness

This repository uses **shared-agent-blueprints**. Before starting work, read:

- [\`HARNESS.md\`](./HARNESS.md) — lifecycle, safety, quality gates, and workflow
- Memory trackers when executing planned work: \`PLANNING.md\`, \`DECISIONS.md\`, \`RUN_LOG.md\`, \`HOTCACHE.md\`, \`LEARNING.md\`, \`ANTI-PATTERNS.md\`

Existing project-specific instructions in this file remain applicable. When instructions conflict, follow the precedence rules defined in \`HARNESS.md\`.
${HARNESS_REF_END}
EOF
}

harness_count_marker() {
  local file="$1"
  local marker="$2"
  if [[ ! -f "$file" ]]; then
    echo 0
    return 0
  fi
  grep -cF "$marker" "$file" 2>/dev/null || echo 0
}

harness_is_managed_file() {
  local file="$1"
  [[ -f "$file" ]] && grep -qF "$HARNESS_FILE_MARKER" "$file" 2>/dev/null
}

harness_atomic_write() {
  local dest="$1"
  local content="$2"
  local dir tmp
  dir="$(dirname "$dest")"
  mkdir -p "$dir"
  tmp="$(mktemp "${dir}/.blueprint-write.XXXXXX")"
  # Preserve trailing newline if content already has one; printf '%s' avoids extra.
  printf '%s' "$content" > "$tmp"
  if [[ "$content" == *$'\n' ]]; then
    :
  elif [[ -n "$content" ]]; then
    # Content without trailing newline — keep as-is (already written).
    :
  fi
  if ! mv "$tmp" "$dest"; then
    rm -f "$tmp"
    return 1
  fi
  return 0
}

harness_atomic_copy() {
  local src="$1"
  local dest="$2"
  local dir tmp
  dir="$(dirname "$dest")"
  mkdir -p "$dir"
  tmp="$(mktemp "${dir}/.blueprint-write.XXXXXX")"
  if ! cp "$src" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if ! mv "$tmp" "$dest"; then
    rm -f "$tmp"
    return 1
  fi
  return 0
}

# detect_agent_entrypoint <projectRoot>
# Root-only, case-sensitive detection. Never searches subdirectories.
# Precedence: AGENTS.md > agents.md > CLAUDE.md > claude.md > create AGENTS.md
detect_agent_entrypoint() {
  local root="$1"
  HARNESS_SELECTED_PATH=""
  HARNESS_SELECTED_SOURCE=""
  HARNESS_CLAUDE_DETECTED=0
  HARNESS_WARNINGS=()

  local agents_path="" agents_lower="" claude_path="" claude_lower=""
  if harness_exact_exists "$root" "AGENTS.md"; then
    agents_path="$(harness_exact_path "$root" "AGENTS.md")"
  fi
  if harness_exact_exists "$root" "agents.md"; then
    agents_lower="$(harness_exact_path "$root" "agents.md")"
  fi
  if harness_exact_exists "$root" "CLAUDE.md"; then
    claude_path="$(harness_exact_path "$root" "CLAUDE.md")"
    HARNESS_CLAUDE_DETECTED=1
  fi
  if harness_exact_exists "$root" "claude.md"; then
    claude_lower="$(harness_exact_path "$root" "claude.md")"
    HARNESS_CLAUDE_DETECTED=1
  fi

  if [[ -n "$agents_path" && -n "$agents_lower" && "$agents_path" != "$agents_lower" ]]; then
    HARNESS_WARNINGS+=("Both AGENTS.md and agents.md exist; selecting AGENTS.md by precedence. Left agents.md unchanged.")
  fi
  if [[ -n "$claude_path" && -n "$claude_lower" && "$claude_path" != "$claude_lower" ]]; then
    HARNESS_WARNINGS+=("Both CLAUDE.md and claude.md exist; selecting CLAUDE.md by precedence when no agents file is present. Left the non-selected Claude file unchanged.")
  fi

  if [[ -n "$agents_path" ]]; then
    HARNESS_SELECTED_PATH="$agents_path"
    HARNESS_SELECTED_SOURCE="AGENTS.md"
    return 0
  fi

  if [[ -n "$agents_lower" ]]; then
    HARNESS_SELECTED_PATH="$agents_lower"
    HARNESS_SELECTED_SOURCE="agents.md"
    return 0
  fi

  if [[ -n "$claude_path" ]]; then
    HARNESS_SELECTED_PATH="$claude_path"
    HARNESS_SELECTED_SOURCE="CLAUDE.md"
    return 0
  fi

  if [[ -n "$claude_lower" ]]; then
    HARNESS_SELECTED_PATH="$claude_lower"
    HARNESS_SELECTED_SOURCE="claude.md"
    return 0
  fi

  HARNESS_SELECTED_PATH="${root}/AGENTS.md"
  HARNESS_SELECTED_SOURCE="created"
  return 0
}

# ensure_harness_file <projectRoot> [blueprintVersion]
# Creates or safely updates root HARNESS.md from the package template.
ensure_harness_file() {
  local root="$1"
  local _ver="${2:-}"
  local dest="${root}/${HARNESS_FILE_NAME}"
  local src
  src="$(harness_template_path)"
  need_file "$src"

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    if [[ -f "$dest" ]]; then
      emit_info "dry-run: would refresh ${HARNESS_FILE_NAME}"
      HARNESS_SUMMARY_HARNESS="Would update HARNESS.md"
    else
      emit_info "dry-run: would create ${HARNESS_FILE_NAME}"
      HARNESS_SUMMARY_HARNESS="Would create HARNESS.md"
    fi
    return 0
  fi

  if [[ ! -f "$dest" ]]; then
    if ! harness_atomic_copy "$src" "$dest"; then
      emit_error "failed to create ${HARNESS_FILE_NAME}"
      return 1
    fi
    emit_file_added "$dest"
    HARNESS_SUMMARY_HARNESS="Created HARNESS.md"
    return 0
  fi

  if harness_is_managed_file "$dest"; then
    if cmp -s "$src" "$dest" 2>/dev/null; then
      emit_file_skipped "$dest" "unchanged"
      HARNESS_SUMMARY_HARNESS="HARNESS.md already up to date"
      return 0
    fi
    if ! harness_atomic_copy "$src" "$dest"; then
      emit_error "failed to update ${HARNESS_FILE_NAME}"
      return 1
    fi
    emit_file_updated "$dest"
    HARNESS_SUMMARY_HARNESS="Updated HARNESS.md"
    return 0
  fi

  # Unmanaged existing file: never silently destroy.
  local backup="${dest}.blueprint-backup"
  local ts
  ts="$(date -u +"%Y%m%dT%H%M%SZ" 2>/dev/null || date +%s)"
  backup="${dest}.blueprint-backup.${ts}"
  if [[ "${FORCE:-0}" -eq 1 ]]; then
    if ! cp "$dest" "$backup"; then
      emit_error "failed to backup unmanaged ${HARNESS_FILE_NAME}; refusing to replace"
      return 1
    fi
    if ! harness_atomic_copy "$src" "$dest"; then
      # Attempt rollback
      cp "$backup" "$dest" 2>/dev/null || true
      emit_error "failed to replace ${HARNESS_FILE_NAME}; restored from backup when possible"
      return 1
    fi
    emit_warning "Replaced unmanaged HARNESS.md; backup at $(basename "$backup")"
    emit_file_updated "$dest"
    HARNESS_SUMMARY_HARNESS="Replaced unmanaged HARNESS.md (backup created)"
    return 0
  fi

  emit_warning "Existing HARNESS.md is not Blueprint-managed; left unchanged. Re-run with --force to backup and replace, or migrate manually."
  emit_file_skipped "$dest" "unmanaged; use --force to replace"
  HARNESS_SUMMARY_HARNESS="Preserved unmanaged HARNESS.md"
  return 0
}

harness_read_file() {
  # Preserve trailing newlines (command substitution would strip them).
  local file="$1"
  local data
  data="$(cat "$file"; printf x)"
  printf '%s' "${data%x}"
}

# ensure_harness_reference <agentFilePath>
# For an existing instruction file: append or reconcile the compact managed block.
# User content outside markers is never overwritten. Creating a missing AGENTS.md uses
# templates/entrypoints/AGENTS.md as-is, then adds the managed block once.
ensure_harness_reference() {
  local agent_file="$1"
  local start_count end_count
  local block
  block="$(harness_managed_block)"

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    if [[ -f "$agent_file" ]]; then
      emit_info "dry-run: would reconcile harness reference in $(basename "$agent_file")"
    else
      emit_info "dry-run: would create $(basename "$agent_file") from template with harness reference"
    fi
    HARNESS_SUMMARY_REF="Would add/update managed Harness Reference"
    return 0
  fi

  if [[ ! -f "$agent_file" ]]; then
    local agents_tmpl
    agents_tmpl="$(agents_template_path)"
    if [[ ! -f "$agents_tmpl" ]]; then
      emit_error "missing AGENTS.md template at ${agents_tmpl}"
      return 1
    fi
    if ! harness_atomic_copy "$agents_tmpl" "$agent_file"; then
      emit_error "failed to create $(basename "$agent_file") from template"
      return 1
    fi
    emit_file_added "$agent_file"
    HARNESS_SUMMARY_AGENT="Created AGENTS.md"
    # Fall through to append the managed block onto the template body.
  fi

  start_count="$(harness_count_marker "$agent_file" "$HARNESS_REF_START")"
  end_count="$(harness_count_marker "$agent_file" "$HARNESS_REF_END")"
  # Normalize possible "0\n" from grep -c quirks
  start_count="${start_count//$'\n'/}"
  end_count="${end_count//$'\n'/}"

  if [[ "$start_count" -gt 1 || "$end_count" -gt 1 ]]; then
    emit_warning "Multiple harness reference markers in $(basename "$agent_file"); leaving file unchanged. Repair manually so exactly one START/END pair remains."
    HARNESS_SUMMARY_REF="Skipped (malformed: multiple markers)"
    return 1
  fi

  if [[ "$start_count" -eq 1 && "$end_count" -eq 0 ]] || [[ "$start_count" -eq 0 && "$end_count" -eq 1 ]]; then
    emit_warning "Malformed harness reference markers in $(basename "$agent_file") (only one of START/END present). Left unchanged; repair markers then re-run install."
    HARNESS_SUMMARY_REF="Skipped (malformed markers)"
    return 1
  fi

  local backup=""
  backup="$(mktemp)"
  if ! cp "$agent_file" "$backup"; then
    rm -f "$backup"
    emit_error "failed to backup $(basename "$agent_file") before patch"
    return 1
  fi

  local original patched
  original="$(harness_read_file "$agent_file")"

  if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
    # Append managed block; preserve existing content and trailing newline style.
    if [[ -z "$original" ]]; then
      patched="${block}"$'\n'
    elif [[ "$original" == *$'\n' ]]; then
      patched="${original}${block}"$'\n'
    else
      patched="${original}"$'\n'"${block}"$'\n'
    fi
    if ! harness_atomic_write "$agent_file" "$patched"; then
      cp "$backup" "$agent_file" 2>/dev/null || true
      rm -f "$backup"
      emit_error "failed to write harness reference; rolled back $(basename "$agent_file")"
      return 1
    fi
    rm -f "$backup"
    emit_file_updated "$agent_file"
    HARNESS_SUMMARY_REF="Added managed Harness Reference"
    return 0
  fi

  # Exactly one pair: replace only the region between markers (inclusive of markers).
  local block_file patched_file
  block_file="$(mktemp)"
  patched_file="$(mktemp)"
  printf '%s\n' "$block" > "$block_file"
  if ! awk -v start="$HARNESS_REF_START" -v end="$HARNESS_REF_END" -v blockfile="$block_file" '
    BEGIN {
      replacing=0
      printed_block=0
      while ((getline line < blockfile) > 0) {
        block = block line "\n"
      }
      close(blockfile)
    }
    $0 == start {
      if (!printed_block) {
        printf "%s", block
        printed_block=1
      }
      replacing=1
      next
    }
    replacing && $0 == end { replacing=0; next }
    replacing { next }
    { print }
  ' "$agent_file" > "$patched_file"; then
    rm -f "$backup" "$block_file" "$patched_file"
    emit_error "failed to reconcile harness reference in $(basename "$agent_file")"
    return 1
  fi
  rm -f "$block_file"
  patched="$(harness_read_file "$patched_file")"
  rm -f "$patched_file"

  if [[ "$patched" == "$original" ]]; then
    rm -f "$backup"
    emit_file_skipped "$agent_file" "harness reference unchanged"
    HARNESS_SUMMARY_REF="Harness Reference already up to date"
    return 0
  fi

  if ! harness_atomic_write "$agent_file" "$patched"; then
    cp "$backup" "$agent_file" 2>/dev/null || true
    rm -f "$backup"
    emit_error "failed to reconcile harness reference; rolled back $(basename "$agent_file")"
    return 1
  fi
  rm -f "$backup"
  emit_file_updated "$agent_file"
  HARNESS_SUMMARY_REF="Updated managed Harness Reference"
  return 0
}

# remove_harness_reference <agentFilePath>
# Strip the managed Harness Reference block; leave all other agent content intact.
remove_harness_reference() {
  local agent_file="$1"
  if [[ ! -f "$agent_file" ]]; then
    return 0
  fi

  local start_count end_count
  start_count="$(harness_count_marker "$agent_file" "$HARNESS_REF_START")"
  end_count="$(harness_count_marker "$agent_file" "$HARNESS_REF_END")"
  start_count="${start_count//$'\n'/}"
  end_count="${end_count//$'\n'/}"

  if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
    emit_file_skipped "$agent_file" "no harness reference"
    return 0
  fi

  if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
    emit_warning "Malformed harness reference markers in $(basename "$agent_file"); left unchanged"
    emit_file_skipped "$agent_file" "malformed harness markers"
    return 1
  fi

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    emit_info "dry-run: would remove harness reference from $(basename "$agent_file")"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  if ! awk -v start="$HARNESS_REF_START" -v end="$HARNESS_REF_END" '
    $0 == start { skip=1; next }
    skip && $0 == end { skip=0; next }
    skip { next }
    { print }
  ' "$agent_file" > "$tmp"; then
    rm -f "$tmp"
    emit_error "failed to strip harness reference from $(basename "$agent_file")"
    return 1
  fi

  if ! harness_atomic_copy "$tmp" "$agent_file"; then
    rm -f "$tmp"
    emit_error "failed to write stripped agent file $(basename "$agent_file")"
    return 1
  fi
  rm -f "$tmp"
  emit_file_updated "$agent_file"
  return 0
}

# update_harness_only <projectRoot> [blueprintVersion]
# Update flow: touch only HARNESS.md.
update_harness_only() {
  local root="$1"
  local ver="${2:-}"
  ensure_harness_file "$root" "$ver"
}

print_init_harness_summary() {
  printf '\n'
  printf 'Blueprint initialized\n'
  printf 'Harness:\n'
  printf '  %s\n' "${HARNESS_SUMMARY_HARNESS:-HARNESS.md}"
  printf 'Agent entrypoint:\n'
  case "${HARNESS_SELECTED_SOURCE}" in
    AGENTS.md) printf '  Found existing AGENTS.md\n' ;;
    agents.md) printf '  Found existing agents.md\n' ;;
    CLAUDE.md) printf '  Found existing CLAUDE.md\n' ;;
    claude.md) printf '  Found existing claude.md\n' ;;
    created) printf '  Created AGENTS.md\n' ;;
    *) printf '  %s\n' "${HARNESS_SELECTED_SOURCE:-unknown}" ;;
  esac
  if [[ -n "${HARNESS_SUMMARY_REF:-}" ]]; then
    printf '  %s\n' "$HARNESS_SUMMARY_REF"
  fi
  printf 'Claude:\n'
  case "${HARNESS_SELECTED_SOURCE}" in
    CLAUDE.md|claude.md)
      printf '  Used as agent entrypoint\n'
      printf '  Compact Blueprint block reconciled (user content preserved)\n'
      ;;
    *)
      if [[ "${HARNESS_CLAUDE_DETECTED}" -eq 1 ]]; then
        printf '  Found CLAUDE.md / claude.md\n'
        printf '  Left unchanged (higher-priority agents file selected)\n'
      else
        printf '  Not present\n'
      fi
      ;;
  esac
  local w
  if ((${#HARNESS_WARNINGS[@]} > 0)); then
    for w in "${HARNESS_WARNINGS[@]}"; do
      printf 'Warning:\n  %s\n' "$w"
    done
  fi
}

print_update_harness_summary() {
  local root="$1"
  local from_ver="${2:-unknown}"
  local to_ver="${3:-}"
  local updated_runtimes="${4:-0}"
  printf '\n'
  printf 'Blueprint updated\n'
  printf 'Version:\n'
  if [[ -n "$to_ver" ]]; then
    if [[ "$from_ver" != "unknown" && "$from_ver" != "$to_ver" ]]; then
      printf '  v%s → v%s\n' "$from_ver" "$to_ver"
    else
      printf '  v%s\n' "$to_ver"
    fi
  fi
  printf 'Updated:\n'
  printf '  HARNESS.md\n'
  if [[ "$updated_runtimes" -eq 1 ]]; then
    printf '  managed runtime projections (.cursor / .claude / .agents)\n'
    printf '  rename cleanup + full skill/rule refresh (harness/migrations/renames.log)\n'
    printf '  managed .gitignore section\n'
    printf '  .agent-blueprint.yaml version\n'
  else
    printf '  .agent-blueprint.yaml version (when present)\n'
  fi
  printf 'Preserved:\n'
  if harness_exact_exists "$root" "AGENTS.md"; then
    printf '  AGENTS.md\n'
  fi
  if harness_exact_exists "$root" "agents.md"; then
    local agents_p lower_p
    agents_p="$(harness_exact_path "$root" "AGENTS.md" 2>/dev/null || true)"
    lower_p="$(harness_exact_path "$root" "agents.md" 2>/dev/null || true)"
    if [[ -n "$lower_p" && "$lower_p" != "$agents_p" ]]; then
      printf '  agents.md\n'
    elif [[ -z "$agents_p" && -n "$lower_p" ]]; then
      printf '  agents.md\n'
    fi
  fi
  if harness_exact_exists "$root" "CLAUDE.md"; then
    printf '  CLAUDE.md\n'
  fi
  if harness_exact_exists "$root" "claude.md"; then
    local claude_p claude_lower_p
    claude_p="$(harness_exact_path "$root" "CLAUDE.md" 2>/dev/null || true)"
    claude_lower_p="$(harness_exact_path "$root" "claude.md" 2>/dev/null || true)"
    if [[ -n "$claude_lower_p" && "$claude_lower_p" != "$claude_p" ]]; then
      printf '  claude.md\n'
    elif [[ -z "$claude_p" && -n "$claude_lower_p" ]]; then
      printf '  claude.md\n'
    fi
  fi
}
