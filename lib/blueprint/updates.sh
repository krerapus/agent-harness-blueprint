# Landing-menu update check (CLI release + core/skills pack).
# shellcheck shell=bash

# Default GitHub repo for CLI latest release (override via env).
UPDATES_CLI_REPO="${BLUEPRINT_CLI_REPO:-krerapus/agent-harness-blueprint}"
UPDATES_CLI_LATEST_URL="${BLUEPRINT_CLI_LATEST_URL:-https://github.com/${UPDATES_CLI_REPO}/releases/latest}"
# TTL seconds between network refreshes (display still uses cache every menu draw).
UPDATES_TTL_SECONDS="${BLUEPRINT_UPDATE_TTL:-21600}"

# In-memory result of last ensure/check (empty = no announcement).
BP_UPDATE_CLI_CURRENT=""
BP_UPDATE_CLI_LATEST=""
BP_UPDATE_CLI_OUTDATED=0
BP_UPDATE_CORE_CURRENT=""
BP_UPDATE_CORE_LATEST=""
BP_UPDATE_CORE_OUTDATED=0
BP_UPDATE_HAS_UPDATE=0

updates_cache_path() {
  printf '%s/updates.env' "$(bp_cache_dir)"
}

updates_is_offline() {
  if [[ "${BLUEPRINT_OFFLINE:-0}" == "1" || "${ASSETS_OFFLINE:-0}" == "1" ]]; then
    return 0
  fi
  if command -v assets_is_offline >/dev/null 2>&1 && assets_is_offline; then
    return 0
  fi
  return 1
}

# Return 0 if $1 < $2 (semver-ish via sort -V).
updates_version_lt() {
  local a b first
  a="$(normalize_version "${1:-}")"
  b="$(normalize_version "${2:-}")"
  [[ -n "$a" && -n "$b" ]] || return 1
  [[ "$a" == "$b" ]] && return 1
  first="$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -n1)"
  [[ "$first" == "$a" ]]
}

# Return 0 if $1 > $2.
updates_version_gt() {
  updates_version_lt "${2:-}" "${1:-}"
}

updates_now_epoch() {
  date +%s 2>/dev/null || printf '0'
}

updates_cache_is_fresh() {
  local path age checked_at now ttl
  path="$(updates_cache_path)"
  [[ -f "$path" ]] || return 1
  checked_at="$(grep -E '^checked_at=' "$path" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  [[ -n "$checked_at" && "$checked_at" =~ ^[0-9]+$ ]] || return 1
  now="$(updates_now_epoch)"
  ttl="${BLUEPRINT_UPDATE_TTL:-${UPDATES_TTL_SECONDS:-21600}}"
  [[ "$ttl" =~ ^[0-9]+$ ]] || ttl=21600
  [[ "$ttl" -eq 0 ]] && return 1
  age=$((now - checked_at))
  [[ "$age" -ge 0 && "$age" -lt "$ttl" ]]
}

updates_load_cache() {
  local path
  path="$(updates_cache_path)"
  [[ -f "$path" ]] || return 1
  BP_UPDATE_CLI_CURRENT=""
  BP_UPDATE_CLI_LATEST=""
  BP_UPDATE_CLI_OUTDATED=0
  BP_UPDATE_CORE_CURRENT=""
  BP_UPDATE_CORE_LATEST=""
  BP_UPDATE_CORE_OUTDATED=0
  BP_UPDATE_HAS_UPDATE=0
  # Simple KEY=VALUE file written by us (not user-controlled YAML).
  while IFS='=' read -r key val; do
    case "$key" in
      cli_current) BP_UPDATE_CLI_CURRENT="$val" ;;
      cli_latest) BP_UPDATE_CLI_LATEST="$val" ;;
      cli_outdated) BP_UPDATE_CLI_OUTDATED="$val" ;;
      core_current) BP_UPDATE_CORE_CURRENT="$val" ;;
      core_latest) BP_UPDATE_CORE_LATEST="$val" ;;
      core_outdated) BP_UPDATE_CORE_OUTDATED="$val" ;;
      has_update) BP_UPDATE_HAS_UPDATE="$val" ;;
    esac
  done < "$path"
  return 0
}

updates_write_cache() {
  local path dest_dir
  bp_ensure_xdg_dirs 2>/dev/null || true
  dest_dir="$(bp_cache_dir)"
  mkdir -p "$dest_dir" 2>/dev/null || true
  path="$(updates_cache_path)"
  cat >"$path" <<EOF
checked_at=$(updates_now_epoch)
cli_current=${BP_UPDATE_CLI_CURRENT}
cli_latest=${BP_UPDATE_CLI_LATEST}
cli_outdated=${BP_UPDATE_CLI_OUTDATED}
core_current=${BP_UPDATE_CORE_CURRENT}
core_latest=${BP_UPDATE_CORE_LATEST}
core_outdated=${BP_UPDATE_CORE_OUTDATED}
has_update=${BP_UPDATE_HAS_UPDATE}
EOF
}

# Resolve latest CLI tag from GitHub releases/latest redirect (fail-open → empty).
updates_fetch_cli_latest() {
  local forced url tag
  forced="${BLUEPRINT_UPDATE_FORCE_CLI_LATEST:-}"
  if [[ -n "$forced" ]]; then
    printf '%s' "$(normalize_version "$forced")"
    return 0
  fi
  updates_is_offline && return 1
  command -v curl >/dev/null 2>&1 || return 1
  url="$(curl -fsSL --max-time 3 -o /dev/null -w '%{url_effective}' \
    "$UPDATES_CLI_LATEST_URL" 2>/dev/null || true)"
  [[ -n "$url" ]] || return 1
  tag="${url##*/}"
  tag="$(normalize_version "$tag")"
  [[ -n "$tag" ]] || return 1
  printf '%s' "$tag"
}

updates_fetch_core_latest() {
  local forced ver
  forced="${BLUEPRINT_UPDATE_FORCE_CORE_LATEST:-}"
  if [[ -n "$forced" ]]; then
    printf '%s' "$(normalize_version "$forced")"
    return 0
  fi
  updates_is_offline && return 1
  assets_fetch_catalog 2>/dev/null || return 1
  ver="$(assets_read_catalog_field core version 2>/dev/null || true)"
  ver="$(normalize_version "$ver")"
  [[ -n "$ver" ]] || return 1
  printf '%s' "$ver"
}

updates_local_cli() {
  if command -v package_version >/dev/null 2>&1; then
    normalize_version "$(package_version)"
  else
    printf '0.0.0'
  fi
}

updates_local_core() {
  local core v
  if command -v assets_resolve_pack >/dev/null 2>&1; then
    if core="$(assets_resolve_pack core 2>/dev/null)"; then
      v="$(assets_pack_version_file "$core" 2>/dev/null || true)"
      v="$(normalize_version "$v")"
      if [[ -n "$v" ]]; then
        printf '%s' "$v"
        return 0
      fi
    fi
  fi
  # No installed core → treat as unknown (skip skills row).
  printf ''
}

updates_recompute_flags() {
  BP_UPDATE_CLI_OUTDATED=0
  BP_UPDATE_CORE_OUTDATED=0
  BP_UPDATE_HAS_UPDATE=0
  if [[ -n "$BP_UPDATE_CLI_CURRENT" && -n "$BP_UPDATE_CLI_LATEST" ]] \
    && updates_version_gt "$BP_UPDATE_CLI_LATEST" "$BP_UPDATE_CLI_CURRENT"; then
    BP_UPDATE_CLI_OUTDATED=1
  fi
  if [[ -n "$BP_UPDATE_CORE_CURRENT" && -n "$BP_UPDATE_CORE_LATEST" ]] \
    && updates_version_gt "$BP_UPDATE_CORE_LATEST" "$BP_UPDATE_CORE_CURRENT"; then
    BP_UPDATE_CORE_OUTDATED=1
  fi
  if [[ "$BP_UPDATE_CLI_OUTDATED" -eq 1 || "$BP_UPDATE_CORE_OUTDATED" -eq 1 ]]; then
    BP_UPDATE_HAS_UPDATE=1
  fi
}

# Refresh remote versions when cache stale / forced; always load into BP_UPDATE_*.
# Fail-open: network errors leave HAS_UPDATE=0 (no panel).
updates_ensure_checked() {
  BP_UPDATE_CLI_CURRENT=""
  BP_UPDATE_CLI_LATEST=""
  BP_UPDATE_CLI_OUTDATED=0
  BP_UPDATE_CORE_CURRENT=""
  BP_UPDATE_CORE_LATEST=""
  BP_UPDATE_CORE_OUTDATED=0
  BP_UPDATE_HAS_UPDATE=0

  if updates_is_offline && [[ -z "${BLUEPRINT_UPDATE_FORCE_CLI_LATEST:-}" && -z "${BLUEPRINT_UPDATE_FORCE_CORE_LATEST:-}" ]]; then
    return 0
  fi

  # Force env always refreshes (tests / debug).
  local force_refresh=0
  if [[ -n "${BLUEPRINT_UPDATE_FORCE_CLI_LATEST:-}" || -n "${BLUEPRINT_UPDATE_FORCE_CORE_LATEST:-}" ]]; then
    force_refresh=1
  fi
  if [[ "${BLUEPRINT_UPDATE_TTL:-}" == "0" ]]; then
    force_refresh=1
  fi

  if [[ "$force_refresh" -eq 0 ]] && updates_cache_is_fresh; then
    updates_load_cache || true
    return 0
  fi

  local cli_cur cli_lat core_cur core_lat
  cli_cur="$(updates_local_cli)"
  core_cur="$(updates_local_core)"
  cli_lat=""
  core_lat=""
  cli_lat="$(updates_fetch_cli_latest 2>/dev/null || true)"
  core_lat="$(updates_fetch_core_latest 2>/dev/null || true)"

  # If both remotes failed and no force vars, keep prior cache display if any.
  if [[ -z "$cli_lat" && -z "$core_lat" ]]; then
    if updates_load_cache 2>/dev/null; then
      return 0
    fi
    return 0
  fi

  BP_UPDATE_CLI_CURRENT="$cli_cur"
  BP_UPDATE_CLI_LATEST="$cli_lat"
  BP_UPDATE_CORE_CURRENT="$core_cur"
  BP_UPDATE_CORE_LATEST="$core_lat"
  updates_recompute_flags
  updates_write_cache 2>/dev/null || true
}

# True when the yellow panel should render.
updates_should_announce() {
  [[ "${BP_UPDATE_HAS_UPDATE:-0}" -eq 1 ]]
}
