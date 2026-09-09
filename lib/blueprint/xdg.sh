# XDG paths for Blueprint config / cache / data.
# shellcheck shell=bash

xdg_config_home() {
  printf '%s' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

xdg_cache_home() {
  printf '%s' "${XDG_CACHE_HOME:-$HOME/.cache}"
}

xdg_data_home() {
  printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}"
}

bp_config_dir() {
  printf '%s/blueprint' "$(xdg_config_home)"
}

bp_cache_dir() {
  printf '%s/blueprint' "$(xdg_cache_home)"
}

bp_data_dir() {
  printf '%s/blueprint' "$(xdg_data_home)"
}

bp_ensure_xdg_dirs() {
  mkdir -p "$(bp_config_dir)/credentials" \
    "$(bp_config_dir)/plugins" \
    "$(bp_cache_dir)/assets" \
    "$(bp_cache_dir)/downloads" \
    "$(bp_cache_dir)/catalog" \
    "$(bp_data_dir)"
}

bp_config_file() {
  printf '%s/config.yaml' "$(bp_config_dir)"
}

bp_assets_config_file() {
  printf '%s/assets.yaml' "$(bp_config_dir)"
}

# Seed default config files if missing (never overwrite user edits).
bp_ensure_default_config() {
  bp_ensure_xdg_dirs
  local cfg
  cfg="$(bp_config_file)"
  if [[ ! -f "$cfg" ]]; then
    cat > "$cfg" <<'EOF'
# Blueprint CLI configuration
schema_version: 1
channel: stable
offline: false
assets:
  # Override with BLUEPRINT_ASSETS_BASE_URL or assets.base_url
  base_url: https://github.com/krerapus/assets-blueprint/releases/download
  default_packs:
    - core
  auto_update: false
update:
  check_cli: true
EOF
  fi
  local acfg
  acfg="$(bp_assets_config_file)"
  if [[ ! -f "$acfg" ]]; then
    cat > "$acfg" <<'EOF'
# Default pack pins (user-level). Project pins live in .agent-blueprint.yaml.
schema_version: 1
packs: {}
EOF
  fi
}
