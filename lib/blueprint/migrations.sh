# Harness rename migrations for consumer runtime projections.
# shellcheck shell=bash

renames_log_path() {
  echo "${PACKAGE_ROOT}/harness/migrations/renames.log"
}

# Default package skills projected into consumer runtimes.
# Prefer live pack inventory under PACKAGE_ROOT; fall back to a known baseline.
package_skill_names() {
  local d="${PACKAGE_ROOT}/harness/skills"
  if [[ -d "$d" ]]; then
    local s
    for s in "$d"/*/; do
      [[ -d "$s" ]] || continue
      basename "${s%/}"
    done | LC_ALL=C sort -u
    return 0
  fi
  # Offline/builtin fallback only — prefer live pack inventory above.
  printf '%s\n' \
    build-prototype \
    context-recall \
    design-modules \
    diagnose-bugs \
    docs-style \
    generate-test-cases \
    i-have-adhd \
    ponytail \
    ponytail-audit \
    ponytail-debt \
    ponytail-gain \
    ponytail-help \
    ponytail-review \
    practice-tdd \
    refactor-code \
    research-topic \
    resolve-merge-conflicts \
    review-diff \
    skill-creator \
    task-execution \
    teach-topic \
    update-api-docs
}

package_rule_names() {
  printf '%s\n' \
    safety-rules.mdc \
    task-execution.mdc
}

# apply_harness_renames <projectRoot> <runtimesCsvOrSpaces>
# Removes old skill dirs / rule files listed in harness/migrations/renames.log.
apply_harness_renames() {
  local dest_root="$1"
  local runtimes="$2"
  local log
  log="$(renames_log_path)"
  if [[ ! -f "$log" ]]; then
    emit_info "no renames log at harness/migrations/renames.log — skip rename cleanup"
    return 0
  fi

  local rt rt_root kind old new line
  local removed_any=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip comments / blanks
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    # shellcheck disable=SC2086
    set -- $line
    kind="${1:-}"
    old="${2:-}"
    new="${3:-}"
    if [[ -z "$kind" || -z "$old" || -z "$new" ]]; then
      emit_warning "skip malformed renames.log line: $line"
      continue
    fi
    if [[ "$old" == "$new" ]]; then
      continue
    fi

    for rt in $runtimes; do
      rt_root="$(runtime_root_name "$rt")"
      case "$kind" in
        skill)
          if [[ -d "${dest_root}/${rt_root}/skills/${old}" ]]; then
            emit_info "rename cleanup: remove obsolete skill ${rt_root}/skills/${old} → ${new}"
            del_remove_path "${dest_root}/${rt_root}/skills/${old}"
            removed_any=1
          fi
          ;;
        rule)
          local base="${old%.mdc}"
          if [[ -e "${dest_root}/${rt_root}/rules/${old}" ]]; then
            emit_info "rename cleanup: remove obsolete rule ${rt_root}/rules/${old} → ${new}"
            del_remove_path "${dest_root}/${rt_root}/rules/${old}"
            removed_any=1
          fi
          # Claude projects rules as .md
          if [[ -e "${dest_root}/${rt_root}/rules/${base}.md" ]]; then
            emit_info "rename cleanup: remove obsolete rule ${rt_root}/rules/${base}.md → ${new%.mdc}.md"
            del_remove_path "${dest_root}/${rt_root}/rules/${base}.md"
            removed_any=1
          fi
          ;;
        *)
          emit_warning "unknown renames.log kind '$kind' (expected skill|rule)"
          ;;
      esac
    done
  done < "$log"

  if [[ "$removed_any" -eq 0 ]]; then
    emit_info "rename cleanup: no obsolete skill/rule paths found"
  fi
  return 0
}

# refresh_package_skills_into <destSkillsDir>
# Full refresh: remove each package skill dir in the target, then copy from package.
refresh_package_skills_into() {
  local dest_skills="$1"
  local skill src_dir
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    src_dir="${PACKAGE_ROOT}/harness/skills/${skill}"
    [[ -d "$src_dir" ]] || continue
    if [[ -d "${dest_skills}/${skill}" ]]; then
      del_remove_path "${dest_skills}/${skill}"
    fi
    mkdir -p "${dest_skills}/${skill}"
    # shellcheck disable=SC2044
    local f rel
    for f in $(find "$src_dir" -type f); do
      rel="${f#"${src_dir}/"}"
      copy_file "$f" "${dest_skills}/${skill}/${rel}" force
    done
  done < <(package_skill_names)
}

# refresh_package_rules_into <destRulesDir> <runtime>
# Full refresh of package-managed rules (Cursor .mdc / Claude+Codex .md).
refresh_package_rules_into() {
  local dest_rules="$1"
  local runtime="$2"
  local src_rule dest_name base
  while IFS= read -r src_rule; do
    [[ -z "$src_rule" ]] && continue
    if [[ "$runtime" == "claude" || "$runtime" == "codex" ]]; then
      dest_name="${src_rule%.mdc}.md"
    else
      dest_name="$src_rule"
    fi
    # Remove both extensions so renames / runtime switches do not leave twins.
    base="${src_rule%.mdc}"
    if [[ -e "${dest_rules}/${base}.mdc" && "$dest_name" != "${base}.mdc" ]]; then
      del_remove_path "${dest_rules}/${base}.mdc"
    fi
    if [[ -e "${dest_rules}/${base}.md" && "$dest_name" != "${base}.md" ]]; then
      del_remove_path "${dest_rules}/${base}.md"
    fi
    copy_file "${PACKAGE_ROOT}/harness/rules/${src_rule}" "${dest_rules}/${dest_name}" force
  done < <(package_rule_names)
}

# Grandfathered identities that may violate action-first naming (vendored / protocol).
package_skill_naming_grandfathered() {
  case "$1" in
    skill-creator|context-recall|task-execution|docs-style|i-have-adhd|ponytail|ponytail-review|ponytail-audit|ponytail-debt|ponytail-gain|ponytail-help)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# validate_package_skill_naming
# Prints problems to stdout (one per line). Exit 0 if clean, 1 if any issues.
# Checks: lowercase hyphen form, dir exists, frontmatter name matches dir,
# forbidden suffixes / role-model-version tokens (new skills only).
validate_package_skill_naming() {
  local skill skill_dir fm_name problems=0 line
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    skill_dir="${PACKAGE_ROOT}/harness/skills/${skill}"
    if [[ ! -d "$skill_dir" ]]; then
      printf 'missing skill directory: %s\n' "$skill"
      problems=$((problems + 1))
      continue
    fi
    if [[ ! -f "${skill_dir}/SKILL.md" ]]; then
      printf 'missing SKILL.md: %s\n' "$skill"
      problems=$((problems + 1))
      continue
    fi
    if [[ ! "$skill" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      printf 'invalid skill name (use lowercase hyphen segments): %s\n' "$skill"
      problems=$((problems + 1))
    fi
    fm_name="$(sed -n 's/^name:[[:space:]]*//p' "${skill_dir}/SKILL.md" | head -1 | tr -d '\r' | sed -e 's/^["'\'']//' -e 's/["'\'']$//')"
    if [[ -z "$fm_name" ]]; then
      printf 'missing frontmatter name: %s\n' "$skill"
      problems=$((problems + 1))
    elif [[ "$fm_name" != "$skill" ]]; then
      printf 'frontmatter name mismatch: dir=%s name=%s\n' "$skill" "$fm_name"
      problems=$((problems + 1))
    fi
    case "$skill" in
      *-skill|*-agent|*-assistant|*-tool|*-service)
        printf 'forbidden suffix in skill name: %s\n' "$skill"
        problems=$((problems + 1))
        ;;
    esac
    if package_skill_naming_grandfathered "$skill"; then
      continue
    fi
    # Non-grandfathered: reject role/model/version tokens and non-action-first object-verb forms.
    if [[ "$skill" =~ (^|-)(gpt|claude|gemini|cursor|copilot|llm|v[0-9]+|beta|legacy)(-|$) ]]; then
      printf 'forbidden role/model/version token in skill name: %s\n' "$skill"
      problems=$((problems + 1))
    fi
    if [[ "$skill" =~ (engineer|senior-qa|^qa-) ]]; then
      printf 'forbidden role token in skill name: %s\n' "$skill"
      problems=$((problems + 1))
    fi
  done < <(package_skill_names)

  if [[ "$problems" -gt 0 ]]; then
    return 1
  fi
  return 0
}
