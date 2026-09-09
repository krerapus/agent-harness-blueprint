# Asset Manager — download, cache, list, doctor for independently versioned packs.
# shellcheck shell=bash

# Default GitHub org/repo for asset releases (override via config / env).
ASSETS_DEFAULT_BASE_URL="${BLUEPRINT_ASSETS_BASE_URL:-https://github.com/krerapus/assets-blueprint/releases/download}"
ASSETS_OFFLINE="${BLUEPRINT_ASSETS_OFFLINE:-0}"
ASSETS_CATALOG_URL="${BLUEPRINT_ASSETS_CATALOG_URL:-https://raw.githubusercontent.com/krerapus/assets-blueprint/master/catalog.yaml}"

assets_cache_root() {
  printf '%s/assets' "$(bp_cache_dir)"
}

assets_downloads_dir() {
  printf '%s/downloads' "$(bp_cache_dir)"
}

assets_catalog_cache() {
  printf '%s/catalog/catalog.yaml' "$(bp_cache_dir)"
}

# Dev / contributor checkout of assets-blueprint (sibling of CLI repo).
assets_sibling_root() {
  local sibling
  sibling="$(cd "${ROOT}/.." 2>/dev/null && pwd)/assets-blueprint"
  if [[ -d "${sibling}/packs/core" ]]; then
    printf '%s' "$sibling"
    return 0
  fi
  return 1
}

assets_repo_root() {
  if [[ -n "${BLUEPRINT_ASSETS_ROOT:-}" && -d "${BLUEPRINT_ASSETS_ROOT}/packs" ]]; then
    printf '%s' "$BLUEPRINT_ASSETS_ROOT"
    return 0
  fi
  assets_sibling_root
}

# Read version from pack.yaml
assets_pack_version_file() {
  local pack_dir="$1"
  if [[ -f "${pack_dir}/pack.yaml" ]]; then
    grep -E '^version:' "${pack_dir}/pack.yaml" | head -1 | awk '{print $2}' | tr -d '"'
  elif [[ -f "${pack_dir}/VERSION" ]]; then
    tr -d '[:space:]' < "${pack_dir}/VERSION"
  else
    printf ''
  fi
}

# Path to an installed (cached) pack version, or empty.
assets_cached_pack_dir() {
  local name="$1"
  local ver="${2:-}"
  local base
  base="$(assets_cache_root)/${name}"
  if [[ -n "$ver" ]]; then
    if [[ -d "${base}/${ver}" ]]; then
      printf '%s' "${base}/${ver}"
      return 0
    fi
    return 1
  fi
  # Latest cached semver-ish directory (lexicographic; good enough for dotted semver).
  if [[ ! -d "$base" ]]; then
    return 1
  fi
  local latest=""
  local d
  for d in "$base"/*/; do
    [[ -d "$d" ]] || continue
    d="${d%/}"
    latest="$(basename "$d")"
  done
  if [[ -n "$latest" && -d "${base}/${latest}" ]]; then
    printf '%s' "${base}/${latest}"
    return 0
  fi
  return 1
}

# Resolve pack directory: env repo → cache → legacy CLI tree.
# Sets ASSETS_PACK_DIR_<NAME> style via stdout path.
assets_resolve_pack() {
  local name="$1"
  local ver="${2:-}"
  local repo
  if repo="$(assets_repo_root)"; then
    if [[ -d "${repo}/packs/${name}" ]]; then
      printf '%s' "${repo}/packs/${name}"
      return 0
    fi
  fi
  local cached
  if cached="$(assets_cached_pack_dir "$name" "$ver")"; then
    printf '%s' "$cached"
    return 0
  fi
  # Legacy: monorepo layout still present next to CLI.
  if [[ "$name" == "core" && -d "${ROOT}/harness" ]]; then
    printf '%s' "$ROOT"
    return 0
  fi
  return 1
}

# PACKAGE_ROOT for projectors: must contain harness/, templates/, blueprints/.
assets_resolve_package_root() {
  local core
  if core="$(assets_resolve_pack core)"; then
    # Cached/repo packs/core already has harness/; legacy ROOT also does.
    if [[ -d "${core}/harness" ]]; then
      printf '%s' "$core"
      return 0
    fi
  fi
  return 1
}

assets_base_url() {
  local url="${BLUEPRINT_ASSETS_BASE_URL:-}"
  if [[ -z "$url" && -f "$(bp_config_file)" ]]; then
    url="$(grep -E 'base_url:' "$(bp_config_file)" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || true)"
  fi
  if [[ -z "$url" ]]; then
    url="$ASSETS_DEFAULT_BASE_URL"
  fi
  printf '%s' "$url"
}

assets_is_offline() {
  if [[ "${ASSETS_OFFLINE}" == "1" || "${BLUEPRINT_OFFLINE:-0}" == "1" ]]; then
    return 0
  fi
  if [[ -f "$(bp_config_file)" ]] && grep -Eq '^offline:[[:space:]]*true' "$(bp_config_file)" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Parse name[@version] → sets _PACK_NAME _PACK_VER
assets_parse_spec() {
  local spec="$1"
  _PACK_NAME="${spec%%@*}"
  if [[ "$spec" == *"@"* ]]; then
    _PACK_VER="${spec#*@}"
  else
    _PACK_VER=""
  fi
}

assets_read_catalog_field() {
  # Very small YAML grabber for catalog pack entries: assets_read_catalog_field core version
  local pack="$1"
  local field="$2"
  local catalog="${3:-}"
  if [[ -z "$catalog" ]]; then
    catalog="$(assets_catalog_cache)"
  fi
  if [[ ! -f "$catalog" ]]; then
    local repo
    if repo="$(assets_repo_root)"; then
      catalog="${repo}/catalog.yaml"
    fi
  fi
  [[ -f "$catalog" ]] || return 1
  awk -v pack="$pack" -v field="$field" '
    $0 ~ /^[[:space:]]*- name:[[:space:]]*/ {
      name=$0; sub(/^[[:space:]]*- name:[[:space:]]*/, "", name); gsub(/[" ]/, "", name);
      inpack=(name==pack); next
    }
    inpack && $0 ~ "^[[:space:]]*"field":" {
      val=$0; sub(/^[^:]+:[[:space:]]*/, "", val); gsub(/[" ]/, "", val); print val; exit
    }
  ' "$catalog"
}

assets_fetch_catalog() {
  bp_ensure_xdg_dirs
  local dest
  dest="$(assets_catalog_cache)"
  if assets_is_offline; then
    if [[ -f "$dest" ]]; then
      return 0
    fi
    local repo
    if repo="$(assets_repo_root)" && [[ -f "${repo}/catalog.yaml" ]]; then
      cp "${repo}/catalog.yaml" "$dest"
      return 0
    fi
    return 1
  fi
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "$ASSETS_CATALOG_URL" -o "$dest.tmp" 2>/dev/null; then
      mv "$dest.tmp" "$dest"
      return 0
    fi
    rm -f "$dest.tmp"
  fi
  # Fallback: sibling catalog
  local repo
  if repo="$(assets_repo_root)" && [[ -f "${repo}/catalog.yaml" ]]; then
    cp "${repo}/catalog.yaml" "$dest"
    return 0
  fi
  [[ -f "$dest" ]]
}

# Install pack from local repo (copy) or GitHub release tarball.
assets_install_pack() {
  local spec="$1"
  assets_parse_spec "$spec"
  local name="$_PACK_NAME"
  local ver="$_PACK_VER"
  bp_ensure_xdg_dirs

  # Prefer local assets-blueprint checkout (dev / contributor).
  local repo
  if repo="$(assets_repo_root)"; then
    local src="${repo}/packs/${name}"
    if [[ -d "$src" ]]; then
      ver="${ver:-$(assets_pack_version_file "$src")}"
      if [[ -z "$ver" ]]; then
        emit_error "cannot determine version for pack $name"
        return 1
      fi
      local dest
      dest="$(assets_cache_root)/${name}/${ver}"
      if [[ "$DRY_RUN" -eq 1 ]]; then
        emit_info "dry-run: copy $src → $dest"
        return 0
      fi
      mkdir -p "$(dirname "$dest")"
      rm -rf "$dest"
      mkdir -p "$dest"
      # Copy pack contents into versioned cache (immutable snapshot).
      cp -R "${src}/." "$dest/"
      emit_info "installed ${name}@${ver} → $dest (from local assets repo)"
      return 0
    fi
  fi

  if assets_is_offline; then
    emit_error "offline mode: pack ${name} not in local assets repo or cache"
    return 1
  fi

  if [[ -z "$ver" ]]; then
    assets_fetch_catalog || true
    ver="$(assets_read_catalog_field "$name" version || true)"
  fi
  if [[ -z "$ver" ]]; then
    emit_error "could not resolve version for pack ${name} (pass ${name}@x.y.z)"
    return 1
  fi

  local asset="${name}-v${ver}.tar.gz"
  local tag="${name}-v${ver}"
  local url
  url="$(assets_base_url)/${tag}/${asset}"
  local dl
  dl="$(assets_downloads_dir)/${asset}"
  mkdir -p "$(assets_downloads_dir)"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit_info "dry-run: download $url → $dl"
    return 0
  fi

  emit_info "downloading $url"
  if ! command -v curl >/dev/null 2>&1; then
    emit_error "curl required to download assets"
    return 1
  fi
  if ! curl -fsSL "$url" -o "$dl"; then
    emit_error "download failed: $url"
    return 1
  fi

  # Optional checksum
  local sum_url="${url}.sha256"
  if curl -fsSL "$sum_url" -o "${dl}.sha256" 2>/dev/null; then
    local expect actual
    expect="$(tr -d '[:space:]' < "${dl}.sha256" | awk '{print $1}')"
    if command -v shasum >/dev/null 2>&1; then
      actual="$(shasum -a 256 "$dl" | awk '{print $1}')"
    else
      actual="$(sha256sum "$dl" | awk '{print $1}')"
    fi
    if [[ -n "$expect" && "$expect" != "$actual" ]]; then
      emit_error "checksum mismatch for $asset"
      return 1
    fi
    emit_info "checksum ok"
  fi

  local dest
  dest="$(assets_cache_root)/${name}/${ver}"
  rm -rf "$dest"
  mkdir -p "$dest"
  # Tarball contains top-level <name>/...
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/blueprint-assets.XXXXXX")"
  tar -xzf "$dl" -C "$tmp"
  if [[ -d "${tmp}/${name}" ]]; then
    cp -R "${tmp}/${name}/." "$dest/"
  else
    cp -R "${tmp}/." "$dest/"
  fi
  rm -rf "$tmp"
  emit_info "installed ${name}@${ver} → $dest"
  return 0
}

assets_list_local() {
  local base
  base="$(assets_cache_root)"
  if [[ ! -d "$base" ]]; then
    return 0
  fi
  local pack ver
  for pack in "$base"/*; do
    [[ -d "$pack" ]] || continue
    for ver in "$pack"/*; do
      [[ -d "$ver" ]] || continue
      printf 'cache\t%s\t%s\t%s\n' "$(basename "$pack")" "$(basename "$ver")" "$ver"
    done
  done
}

assets_list_repo() {
  local repo
  if ! repo="$(assets_repo_root)"; then
    return 0
  fi
  local pack
  for pack in "${repo}/packs"/*; do
    [[ -d "$pack" ]] || continue
    local name ver
    name="$(basename "$pack")"
    ver="$(assets_pack_version_file "$pack")"
    printf 'repo\t%s\t%s\t%s\n' "$name" "${ver:-?}" "$pack"
  done
}

cmd_assets_list() {
  bp_ensure_default_config
  printf '%-8s %-12s %-10s %s\n' "SOURCE" "PACK" "VERSION" "PATH"
  assets_list_repo | while IFS=$'\t' read -r src name ver path; do
    printf '%-8s %-12s %-10s %s\n' "$src" "$name" "$ver" "$path"
  done
  assets_list_local | while IFS=$'\t' read -r src name ver path; do
    printf '%-8s %-12s %-10s %s\n' "$src" "$name" "$ver" "$path"
  done
  if ! assets_is_offline; then
    if assets_fetch_catalog 2>/dev/null; then
      echo
      echo "Catalog ($(assets_catalog_cache)):"
      local p
      for p in core prompts memories examples; do
        local cv
        cv="$(assets_read_catalog_field "$p" version 2>/dev/null || true)"
        [[ -n "$cv" ]] && printf '  remote  %-12s %s\n' "$p" "$cv"
      done
    fi
  fi
}

cmd_assets_install() {
  local spec="${1:-core}"
  bp_ensure_default_config
  assets_install_pack "$spec"
}

cmd_assets_update() {
  local name="${1:-core}"
  bp_ensure_default_config
  if assets_is_offline; then
    # Offline update: re-copy from local repo if present.
    assets_install_pack "$name"
    return $?
  fi
  assets_fetch_catalog || true
  local ver
  ver="$(assets_read_catalog_field "$name" version || true)"
  if [[ -n "$ver" ]]; then
    assets_install_pack "${name}@${ver}"
  else
    assets_install_pack "$name"
  fi
}

cmd_assets_doctor() {
  bp_ensure_default_config
  local issues=0
  emit_info "Asset doctor"
  ui_kv "config" "$(bp_config_dir)"
  ui_kv "cache" "$(assets_cache_root)"
  ui_kv "offline" "$(assets_is_offline && echo yes || echo no)"

  local repo="(none)"
  if assets_repo_root >/dev/null 2>&1; then
    repo="$(assets_repo_root)"
  fi
  ui_kv "assets_repo" "$repo"

  local core
  if core="$(assets_resolve_pack core)"; then
    ui_ok "core pack → $core"
    if [[ ! -d "${core}/harness" && ! -d "${core}/harness/skills" ]]; then
      # When core is ROOT legacy, harness exists; when pack, harness exists under pack.
      if [[ ! -d "${core}/harness" ]]; then
        ui_fail "core pack missing harness/"
        issues=$((issues + 1))
      fi
    fi
    if [[ -d "${core}/harness" ]]; then
      ui_ok "harness/"
    else
      ui_fail "harness/ missing under core"
      issues=$((issues + 1))
    fi
    if [[ -d "${core}/templates" ]]; then
      ui_ok "templates/"
    else
      ui_fail "templates/ missing under core"
      issues=$((issues + 1))
    fi
  else
    ui_fail "core pack not found — run: blueprint assets install core"
    issues=$((issues + 1))
  fi

  local pkg
  if pkg="$(assets_resolve_package_root)"; then
    ui_ok "PACKAGE_ROOT → $pkg"
  else
    ui_fail "cannot resolve PACKAGE_ROOT"
    issues=$((issues + 1))
  fi

  if [[ "$issues" -eq 0 ]]; then
    ui_ok "assets healthy"
    return 0
  fi
  printf '  %s✗  %s issue(s)%s — fix, then re-run assets doctor\n' "$(term_color red)$(term_color bold)" "$issues" "$(term_color reset)"
  return 1
}

cmd_assets() {
  local sub="${1:-list}"
  shift || true
  # Global --offline for asset subcommands
  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --offline) ASSETS_OFFLINE=1; shift ;;
      *) args+=("$1"); shift ;;
    esac
  done
  set -- "${args[@]+"${args[@]}"}"
  case "$sub" in
    list) cmd_assets_list "$@" ;;
    install) cmd_assets_install "${1:-core}" ;;
    update) cmd_assets_update "${1:-core}" ;;
    doctor) cmd_assets_doctor "$@" ;;
    -h|--help|help)
      cat <<'EOF'
Usage: blueprint assets <command>

  list                 Show local repo, cache, and catalog packs
  install [pack[@ver]] Install a pack into ~/.cache/blueprint/assets
  update [pack]        Update pack to catalog/latest (or local repo)
  doctor [--offline]   Validate pack resolution and layout

Environment:
  BLUEPRINT_ASSETS_ROOT       Path to assets-blueprint checkout
  BLUEPRINT_ASSETS_BASE_URL   Release download base URL
  BLUEPRINT_OFFLINE=1         Force offline mode
EOF
      ;;
    *) die "unknown assets command: $sub (list|install|update|doctor)" ;;
  esac
}
