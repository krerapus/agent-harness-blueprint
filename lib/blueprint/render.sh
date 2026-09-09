# Header, live status, progress, menu, and summary rendering.
# shellcheck shell=bash

BP_HEADER_PROJECT=""
BP_HEADER_ROOT=""
BP_HEADER_BRANCH=""
BP_HEADER_SOURCE=""
BP_HEADER_MODE=""
BP_SPINNER_FRAME=0
BP_SPINNER_CHARS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

render_status() {
  local kind="$1"
  shift
  local msg="$*"
  local sym color
  case "$kind" in
    running) sym="→"; color="cyan" ;;
    success) sym="✓"; color="green" ;;
    warning) sym="!"; color="yellow" ;;
    error) sym="✗"; color="red" ;;
    skipped) sym="⊘"; color="dim" ;;
    updated) sym="~"; color="cyan" ;;
    added) sym="+"; color="green" ;;
    removed) sym="−"; color="yellow" ;;
    info) sym="·"; color="dim" ;;
    *) sym="·"; color="dim" ;;
  esac
  if [[ "$kind" == "error" ]]; then
    printf '  %s%s%s  %s\n' "$(term_color "$color")" "$sym" "$(term_color reset)" "$msg" >&2
  else
    printf '  %s%s%s  %s\n' "$(term_color "$color")" "$sym" "$(term_color reset)" "$msg"
  fi
}

# Code-style welcome banner: pixel icon | title · meta · path
# Args: version, meta_line, path_line
render_banner() {
  local version="$1"
  local meta="$2"
  local path_line="$3"
  local width
  width="$(term_panel_width)"

  local ver_disp="v${version#v}"
  local meta_disp path_disp
  meta_disp="$(term_truncate "$meta" $((width - 10)))"
  path_disp="$(term_truncate "$path_line" $((width - 10)))"

  # Compact / CI: no icon, plain three lines.
  if [[ "$BP_IS_TTY" -ne 1 || "$BP_IS_CI" -eq 1 || "$width" -lt 48 || "$BP_USE_COLOR" -ne 1 ]]; then
    printf '%sBlueprint%s  %s%s%s\n' \
      "$(term_color bold)" "$(term_color reset)" \
      "$(term_color dim)" "$ver_disp" "$(term_color reset)"
    printf '%s%s%s\n' "$(term_color dim)" "$meta_disp" "$(term_color reset)"
    printf '%s%s%s\n' "$(term_color dim)" "$path_disp" "$(term_color reset)"
    printf '\n'
    return 0
  fi

  # Cyan face (true-color): border + 4-tone fill + dark eyes.
  #   ▛▀▀▀▀▀▀▀▀▀▜
  #   ▌ ●   ●   ▐  bg1
  #   ▌         ▐  bg2
  #   ▌         ▐  bg3
  #   ▌         ▐  bg4
  #   ▙▄▄▄▄▄▄▄▄▄▟
  local c bg1 bg2 bg3 bg4 k r
  c="$(printf '\033[38;2;6;182;212m')"
  bg1="$(printf '\033[48;2;236;254;255m')"
  bg2="$(printf '\033[48;2;207;250;254m')"
  bg3="$(printf '\033[48;2;165;243;252m')"
  bg4="$(printf '\033[48;2;103;232;249m')"
  k="$(printf '\033[38;2;12;74;110m')"
  r="$(printf '\033[0m')"

  printf '%s▄▄▄▄▄▄▄▄▄▄▄%s  %sBlueprint%s  %s%s%s\n' \
    "$c" "$r" "$(term_color bold)" "$r" "$(term_color dim)" "$ver_disp" "$r"
  printf '%s%s▌ %s●%s   %s●%s   ▐%s %s%s%s\n' \
    "$c" "$bg1" "$k" "$c$bg1" "$k" "$c$bg1" "$r" \
    "$(term_color dim)" "$meta_disp" "$r"
  printf '%s%s▌         ▐%s %s%s%s\n' \
    "$c" "$bg2" "$r" \
    "$(term_color dim)" "$path_disp" "$r"
  printf '%s%s▌         ▐%s\n' \
    "$c" "$bg3" "$r"
  printf '%s%s▌         ▐%s\n' \
    "$c" "$bg4" "$r"
  printf '%s▄▄▄▄▄▄▄▄▄▄▄%s\n' "$c" "$r"
  printf '\n'
}

render_header() {
  local project="${BP_HEADER_PROJECT:-unknown}"
  local root="${BP_HEADER_ROOT:-.}"
  local branch="${BP_HEADER_BRANCH:-unknown}"
  local source="${BP_HEADER_SOURCE:-local}"
  local mode="${BP_HEADER_MODE:-Run}"
  local run="${BP_RUN_ID:-}"
  local display_root display_source
  display_root="$(term_home_path "$root")"
  display_source="$(term_redact_url "$source")"

  local ver
  ver="$(package_version 2>/dev/null || echo "0.0.0")"
  local meta
  meta="${mode} · ${branch} · ${display_source}"
  render_banner "$ver" "$meta" "$display_root"

  # Compact run context under the banner (no heavy box).
  if [[ -n "$run" ]]; then
    printf '  %srun%s  %s  %s·%s  %s%s%s\n\n' \
      "$(term_color dim)" "$(term_color reset)" "$run" \
      "$(term_color dim)" "$(term_color reset)" \
      "$(term_color dim)" "$project" "$(term_color reset)"
  fi
}

# Full-screen menu chrome (clears first when called via cmd_menu).
# Claude-style framed list: soft outer border, columnar rows, no grid guts.
render_menu() {
  local version="$1"
  local target="$2"
  local display_target
  display_target="$(term_home_path "$target")"

  render_banner "$version" "shared agent blueprints · install · sync" "$display_target"

  local width="${BP_TERM_WIDTH:-80}"
  if [[ "$width" -gt 88 ]]; then width=88; fi
  if [[ "$width" -lt 56 ]]; then width=56; fi

  render_panel_open "Commands" "$width"
  render_panel_cmd_row "1" "init" "HARNESS.md + agent reference + memory" "$width"
  render_panel_cmd_row "2" "install" "Blueprint + runtime + skill-mode (rebase / merge)" "$width"
  render_panel_cmd_row "3" "sync" "Re-apply installed blueprint" "$width"
  render_panel_cmd_row "4" "update" "Version check + refresh managed context" "$width"
  render_panel_cmd_row "5" "doctor" "Validate package / target health" "$width"
  render_panel_cmd_row "6" "target" "Change consumer project path" "$width"
  render_panel_sep "$width"
  render_panel_cmd_row "h" "help" "Show CLI usage" "$width" "cyan" "left"
  render_panel_cmd_row "q" "quit" "Exit" "$width" "cyan" "left"
  render_panel_cmd_row "del" "" "Remove blueprint from this target" "$width" "yellow" "left"
  render_panel_cmd_row "clean" "" "Delete *.blueprint-backup.* on this target" "$width" "yellow" "left"
  render_panel_cmd_row "Esc" "" "Back to previous screen" "$width" "dim" "left"
  render_panel_close "$width"

  printf '\n'
  printf '  %s›%s ' "$(term_color magenta)$(term_color bold)" "$(term_color reset)"
}

# Soft framed panel helpers (reference-style rounded box).
render_panel_chars() {
  if [[ "${BP_IS_TTY:-0}" -eq 1 && "${BP_IS_CI:-0}" -eq 0 && "${BP_USE_COLOR:-0}" -eq 1 ]]; then
    BP_PANEL_TL="╭"; BP_PANEL_TR="╮"; BP_PANEL_BL="╰"; BP_PANEL_BR="╯"
    BP_PANEL_H="─"; BP_PANEL_V="│"; BP_PANEL_ML="├"; BP_PANEL_MR="┤"
  else
    BP_PANEL_TL="+"; BP_PANEL_TR="+"; BP_PANEL_BL="+"; BP_PANEL_BR="+"
    BP_PANEL_H="-"; BP_PANEL_V="|"; BP_PANEL_ML="+"; BP_PANEL_MR="+"
  fi
}

render_panel_open() {
  local title="$1"
  local width="$2"
  render_panel_chars
  local inner=$((width - 2))
  local title_disp=" ${title} "
  local title_len=${#title_disp}
  local left=1
  local right=$((inner - left - title_len))
  if [[ "$right" -lt 1 ]]; then
    title_disp=" ${title:0:$((inner - 3))} "
    title_len=${#title_disp}
    right=$((inner - left - title_len))
  fi
  if [[ "$right" -lt 0 ]]; then right=0; fi
  printf '  %s%s%s%s%s%s%s%s\n' \
    "$(term_color cyan)" \
    "$BP_PANEL_TL" \
    "$(term_repeat "$BP_PANEL_H" "$left")" \
    "$(term_color bold)${title_disp}$(term_color reset)$(term_color cyan)" \
    "$(term_repeat "$BP_PANEL_H" "$right")" \
    "$BP_PANEL_TR" \
    "$(term_color reset)"
}

render_panel_close() {
  local width="$1"
  render_panel_chars
  local inner=$((width - 2))
  printf '  %s%s%s%s%s\n' \
    "$(term_color cyan)" \
    "$BP_PANEL_BL" \
    "$(term_repeat "$BP_PANEL_H" "$inner")" \
    "$BP_PANEL_BR" \
    "$(term_color reset)"
}

render_panel_sep() {
  local width="$1"
  render_panel_chars
  local inner=$((width - 2))
  printf '  %s%s%s%s%s\n' \
    "$(term_color cyan)" \
    "$BP_PANEL_ML" \
    "$(term_repeat "$BP_PANEL_H" "$inner")" \
    "$BP_PANEL_MR" \
    "$(term_color reset)"
}

# One command row:  key  label  - description
# Optional 5th arg: accent color (default cyan).
# Optional 6th arg: key align left|right (default right).
render_panel_cmd_row() {
  local key="$1"
  local label="$2"
  local desc="$3"
  local width="$4"
  local accent="${5:-cyan}"
  local key_align="${6:-right}"
  render_panel_chars

  local inner=$((width - 2))
  local key_w=3
  if [[ ${#key} -gt "$key_w" ]]; then
    key_w=${#key}
  fi
  if [[ "$key_w" -gt 6 ]]; then
    key_w=6
  fi
  local label_w=8
  local key_s label_s desc_s
  key_s="$(term_pad "$key" "$key_w" "$key_align")"
  label_s="$(term_pad "$label" "$label_w")"

  local prefix_len=$((1 + key_w + 2 + label_w + 3))  # " KK  label    - "
  local desc_max=$((inner - prefix_len - 1))
  if [[ "$desc_max" -lt 8 ]]; then desc_max=8; fi
  desc_s="$(term_truncate "$desc" "$desc_max")"
  local pad=$((inner - prefix_len - ${#desc_s}))
  if [[ "$pad" -lt 0 ]]; then pad=0; fi

  printf '  %s%s%s %s%s%s  %s%s%s %s- %s%s%s%s%s%s\n' \
    "$(term_color cyan)" "$BP_PANEL_V" "$(term_color reset)" \
    "$(term_color "$accent")" "$key_s" "$(term_color reset)" \
    "$(term_color "$accent")" "$label_s" "$(term_color reset)" \
    "$(term_color dim)" \
    "$(term_color reset)" \
    "$desc_s" \
    "$(term_repeat ' ' "$pad")" \
    "$(term_color cyan)${BP_PANEL_V}$(term_color reset)"
}

render_finalize_progress() {
  if [[ "${BP_PROGRESS_ACTIVE:-0}" -eq 1 ]]; then
    term_clear_line
    BP_PROGRESS_ACTIVE=0
    term_show_cursor
  fi
}

render_progress() {
  local current="$1"
  local total="${2:-}"
  local item="${3:-}"

  if [[ "${BP_USE_ANIM:-0}" -ne 1 ]]; then
    return 0
  fi

  if [[ "${BP_PROGRESS_ACTIVE:-0}" -eq 0 ]]; then
    term_hide_cursor
  fi
  BP_PROGRESS_ACTIVE=1

  # Keep term width fresh for long runs / resized panes.
  if [[ -n "${COLUMNS:-}" && "${COLUMNS}" =~ ^[0-9]+$ ]]; then
    BP_TERM_WIDTH="$COLUMNS"
  fi

  local line=""
  if [[ -n "$total" && "$total" =~ ^[0-9]+$ && "$total" -gt 0 ]]; then
    local width=24
    local pct=0
    if [[ "$total" -gt 0 ]]; then
      pct=$((current * 100 / total))
      if [[ "$pct" -gt 100 ]]; then pct=100; fi
    fi
    local filled=$((current * width / total))
    if [[ "$filled" -gt "$width" ]]; then filled=$width; fi
    if [[ "$current" -gt 0 && "$filled" -eq 0 ]]; then filled=1; fi
    local bar="" empty="" i
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = filled; i < width; i++)); do empty+="░"; done
    line="$(printf '  %s[%s%s%s]%s %3d%%  %s/%s' \
      "$(term_color cyan)" "$bar" "$(term_color dim)" "$empty" "$(term_color reset)" \
      "$pct" "$current" "$total")"
    if [[ -n "$item" ]]; then
      local plain_len=$(( 4 + width + 2 + 5 + 2 + ${#current} + 1 + ${#total} + 2 ))
      local remain=$((BP_TERM_WIDTH - plain_len))
      if [[ "$remain" -lt 10 ]]; then remain=10; fi
      line="${line}  $(term_truncate "$item" "$remain")"
    fi
  else
    local n=${#BP_SPINNER_CHARS}
    local ch="${BP_SPINNER_CHARS:BP_SPINNER_FRAME:1}"
    BP_SPINNER_FRAME=$(( (BP_SPINNER_FRAME + 1) % n ))
    line="  ${ch} ${BP_PHASE:-Working}  (${current:-0})"
    if [[ -n "$item" ]]; then
      local remain=$((BP_TERM_WIDTH - ${#line} - 4))
      if [[ "$remain" -lt 8 ]]; then remain=8; fi
      line="${line}: $(term_truncate "$item" "$remain")"
    fi
  fi
  term_clear_line
  # Avoid counting ANSI when truncating visual width roughly via printf only.
  printf '%s' "$line"
}

render_divider() {
  local width
  width="$(term_panel_width)"
  printf '\n'
  printf '%s%s%s\n' "$(term_color dim)" "$(term_repeat '─' "$width")" "$(term_color reset)"
}

# Render known consumer targets as a column table.
# Args: package_version path1 ver1 [path2 ver2 ...]
# Writes to stderr (picker UI).
# Columns: # | Name (status icon prefixed, colored) | Path | Version
render_targets_table() {
  local pkg_ver="${1:-}"
  shift || true
  local pkg_n="${pkg_ver#v}"

  local -a paths=()
  local -a vers=()
  while [[ $# -ge 2 ]]; do
    paths+=("$1")
    vers+=("$2")
    shift 2
  done

  local n=${#paths[@]}
  local width="${BP_TERM_WIDTH:-80}"
  if [[ "$width" -lt 64 ]]; then width=64; fi
  if [[ "$width" -gt 100 ]]; then width=100; fi

  # Ratios of remaining width after # + Version: Name ~45%, Path ~55%
  local col_num=3
  local col_ver=8
  local overhead=14
  local rest=$((width - overhead - col_num - col_ver))
  if [[ "$rest" -lt 28 ]]; then rest=28; fi
  local col_name=$((rest * 45 / 100))
  if [[ "$col_name" -lt 18 ]]; then col_name=18; fi
  if [[ "$col_name" -gt 28 ]]; then col_name=28; fi
  local col_path=$((rest - col_name))
  if [[ "$col_path" -lt 16 ]]; then
    col_path=16
    col_name=$((rest - col_path))
    if [[ "$col_name" -lt 14 ]]; then col_name=14; fi
  fi

  local fancy=0
  if [[ "${BP_IS_TTY:-0}" -eq 1 && "${BP_IS_CI:-0}" -eq 0 && "${BP_USE_COLOR:-0}" -eq 1 ]]; then
    fancy=1
  fi

  # Match Actions panel: rounded outer corners.
  local tl tr bl br h v tj tj_l tj_r tj_t cross
  if [[ "$fancy" -eq 1 ]]; then
    tl="╭"; tr="╮"; bl="╰"; br="╯"
    h="─"; v="│"
    tj="┬"; tj_l="├"; tj_r="┤"; tj_t="┴"; cross="┼"
  else
    tl="+"; tr="+"; bl="+"; br="+"
    h="-"; v="|"
    tj="+"; tj_l="+"; tj_r="+"; tj_t="+"; cross="+"
  fi

  local seg_num seg_name seg_path seg_ver
  seg_num="$(term_repeat "$h" $((col_num + 2)))"
  seg_name="$(term_repeat "$h" $((col_name + 2)))"
  seg_path="$(term_repeat "$h" $((col_path + 2)))"
  seg_ver="$(term_repeat "$h" $((col_ver + 2)))"

  local rule_top rule_mid rule_bot
  rule_top="${tl}${seg_num}${tj}${seg_name}${tj}${seg_path}${tj}${seg_ver}${tr}"
  rule_mid="${tj_l}${seg_num}${cross}${seg_name}${cross}${seg_path}${cross}${seg_ver}${tj_r}"
  rule_bot="${bl}${seg_num}${tj_t}${seg_name}${tj_t}${seg_path}${tj_t}${seg_ver}${br}"

  printf '  %sKnown projects%s' "$(term_color bold)" "$(term_color reset)" >&2
  if [[ -n "$pkg_n" ]]; then
    printf '  %s(package v%s)%s' "$(term_color dim)" "$pkg_n" "$(term_color reset)" >&2
  fi
  printf '\n\n' >&2

  printf '  %s%s%s\n' "$(term_color cyan)" "$rule_top" "$(term_color reset)" >&2

  local c0 c1 c2 c3
  c0="$(term_pad "#" "$col_num" right)"
  c1="$(term_pad "Name" "$col_name")"
  c2="$(term_pad "Path" "$col_path")"
  c3="$(term_pad "Version" "$col_ver")"
  printf '  %s%s%s %s %s%s%s %s %s%s%s %s %s%s%s %s %s%s%s\n' \
    "$(term_color cyan)" "$v" "$(term_color reset)" "$c0" \
    "$(term_color cyan)" "$v" "$(term_color reset)" "$c1" \
    "$(term_color cyan)" "$v" "$(term_color reset)" "$c2" \
    "$(term_color cyan)" "$v" "$(term_color reset)" "$c3" \
    "$(term_color cyan)" "$v" "$(term_color reset)" >&2

  printf '  %s%s%s\n' "$(term_color cyan)" "$rule_mid" "$(term_color reset)" >&2

  local i path disp name tv tv_n icon icon_slot icon_color conflict_n backup_n labeled outdated
  for ((i = 0; i < n; i++)); do
    path="${paths[$i]}"
    disp="$(term_home_path "$path")"
    name="$(basename "$path")"
    tv="${vers[$i]:-?}"
    tv_n="${tv#v}"
    conflict_n=0
    backup_n=0
    outdated=0
    if command -v target_conflict_count >/dev/null 2>&1; then
      conflict_n="$(target_conflict_count "$path" 2>/dev/null || echo 0)"
    fi
    if command -v target_backup_count >/dev/null 2>&1; then
      backup_n="$(target_backup_count "$path" 2>/dev/null || echo 0)"
    fi
    if [[ ! "$conflict_n" =~ ^[0-9]+$ ]]; then
      conflict_n=0
    fi
    if [[ ! "$backup_n" =~ ^[0-9]+$ ]]; then
      backup_n=0
    fi
    if [[ "$conflict_n" -gt 0 ]]; then
      if [[ "$backup_n" -gt 0 ]]; then
        icon="!*"
      else
        icon="!"
      fi
      icon_color="yellow"
      if [[ -z "$tv_n" || "$tv_n" == "?" || "$tv_n" == "null" ]]; then
        tv_n="?"
      fi
    elif [[ -z "$tv_n" || "$tv_n" == "?" || "$tv_n" == "null" ]]; then
      tv_n="?"
      if [[ "$backup_n" -gt 0 ]]; then
        icon="?*"
        icon_color="yellow"
      else
        icon="?"
        icon_color="dim"
      fi
    elif [[ -n "$pkg_n" && "$tv_n" != "$pkg_n" ]]; then
      outdated=1
      if [[ "$backup_n" -gt 0 ]]; then
        icon="↓*"
        icon_color="yellow"
      else
        icon="↓"
        icon_color="red"
      fi
    else
      if [[ "$backup_n" -gt 0 ]]; then
        icon="✓*"
        icon_color="yellow"
      else
        icon="✓"
        icon_color="green"
      fi
    fi

    # Fixed 2-char icon slot keeps Name/Path/Version columns aligned.
    if [[ ${#icon} -eq 1 ]]; then
      icon_slot="${icon} "
    else
      icon_slot="$icon"
    fi
    labeled="${icon_slot}${name}"
    c0="$(term_pad "$((i + 1))" "$col_num" right)"
    c1="$(term_pad "$labeled" "$col_name")"
    c2="$(term_pad "$disp" "$col_path")"
    c3="$(term_pad "v${tv_n}" "$col_ver")"

    printf '  %s%s%s %s%s%s %s%s%s %s%s%s %s%s%s %s %s%s%s ' \
      "$(term_color cyan)" "$v" "$(term_color reset)" \
      "$(term_color cyan)" "$c0" "$(term_color reset)" \
      "$(term_color cyan)" "$v" "$(term_color reset)" \
      "$(term_color "$icon_color")" "$c1" "$(term_color reset)" \
      "$(term_color cyan)" "$v" "$(term_color reset)" \
      "$c2" \
      "$(term_color cyan)" "$v" "$(term_color reset)" >&2
    if [[ "$outdated" -eq 1 ]]; then
      printf '%s%s%s' "$(term_color red)" "$c3" "$(term_color reset)" >&2
    else
      printf '%s' "$c3" >&2
    fi
    printf ' %s%s%s\n' "$(term_color cyan)" "$v" "$(term_color reset)" >&2
  done

  printf '  %s%s%s\n' "$(term_color cyan)" "$rule_bot" "$(term_color reset)" >&2
  printf '  %s%s✓%s current  %s↓%s outdated  %s!%s conflicts  %s*%s needs clean\n' \
    "$(term_color dim)" \
    "$(term_color green)" "$(term_color reset)" \
    "$(term_color red)" "$(term_color reset)" \
    "$(term_color yellow)" "$(term_color reset)" \
    "$(term_color yellow)" "$(term_color reset)" >&2
  printf '\n' >&2
}

# Framed actions panel for target picker (add / rm / clean / q).
# Writes to stderr.
render_targets_actions() {
  local width="${1:-56}"
  if [[ "$width" -gt 64 ]]; then width=64; fi
  if [[ "$width" -lt 48 ]]; then width=48; fi

  render_panel_open "Actions" "$width" >&2
  render_panel_cmd_row "add" "" "Add new target project" "$width" "cyan" "left" >&2
  render_panel_cmd_row "rm" "" "Remove a target" "$width" "yellow" "left" >&2
  render_panel_cmd_row "clean" "" "Delete *.blueprint-backup.* on a target" "$width" "yellow" "left" >&2
  render_panel_cmd_row "q" "" "Quit" "$width" "cyan" "left" >&2
  render_panel_close "$width" >&2
  printf '\n' >&2
}

render_summary_success() {
  local source="${1:-}"
  local duration="${2:-}"
  render_divider
  if [[ "$BP_COUNT_ADDED" -eq 0 && "$BP_COUNT_UPDATED" -eq 0 && "${BP_COUNT_REMOVED:-0}" -eq 0 && "$BP_COUNT_FAILED" -eq 0 && "$BP_COUNT_CONFLICT" -eq 0 ]]; then
    printf '\n  %s✓%s  Blueprint is already up to date.\n' "$(term_color green)" "$(term_color reset)"
    printf '      Checked %s managed files' "$BP_COUNT_CHECKED"
    if [[ -n "$duration" ]]; then
      printf ' in %s' "$duration"
    fi
    printf '.\n'
  else
    if [[ "${BP_OP_NAME:-}" == "del" ]]; then
      printf '\n  %s✓%s  Blueprint removal completed\n' "$(term_color green)" "$(term_color reset)"
    else
      printf '\n  %s✓%s  Blueprint synchronization completed\n' "$(term_color green)" "$(term_color reset)"
    fi
    if [[ -n "$source" ]]; then
      printf '      Source    %s\n' "$(term_redact_url "$source")"
    fi
    if [[ -n "$duration" ]]; then
      printf '      Duration  %s\n' "$duration"
    fi
    printf '\n'
    printf '      %s+%s Added     %s\n' "$(term_color green)" "$(term_color reset)" "$BP_COUNT_ADDED"
    printf '      %s~%s Updated   %s\n' "$(term_color cyan)" "$(term_color reset)" "$BP_COUNT_UPDATED"
    if [[ "${BP_COUNT_REMOVED:-0}" -gt 0 || "${BP_OP_NAME:-}" == "del" ]]; then
      printf '      %s−%s Removed   %s\n' "$(term_color yellow)" "$(term_color reset)" "${BP_COUNT_REMOVED:-0}"
    fi
    printf '      %s⊘%s Skipped   %s\n' "$(term_color dim)" "$(term_color reset)" "$BP_COUNT_SKIPPED"
    if [[ "${BP_COUNT_CONFLICT:-0}" -gt 0 ]]; then
      printf '      %s!%s Conflict  %s\n' "$(term_color yellow)" "$(term_color reset)" "$BP_COUNT_CONFLICT"
    fi
    printf '      %s✗%s Failed    %s\n' "$(term_color red)" "$(term_color reset)" "$BP_COUNT_FAILED"
  fi
  printf '\n      %sRun%s  %s\n\n' "$(term_color dim)" "$(term_color reset)" "$BP_RUN_ID"
}

render_summary_failure() {
  local phase="${BP_PHASE_FAILED:-$BP_PHASE}"
  local reason="${BP_ERROR_REASON:-unknown error}"
  render_divider
  printf '\n  %s✗%s  Blueprint synchronization failed\n' "$(term_color red)" "$(term_color reset)"
  printf '      Phase   %s\n' "${phase:-unknown}"
  printf '      Reason  %s\n' "$reason"
  if [[ "$BP_COUNT_ADDED" -eq 0 && "$BP_COUNT_UPDATED" -eq 0 ]]; then
    printf '      No destination files were modified.\n'
  fi
  printf '\n      %sRun%s  %s\n\n' "$(term_color dim)" "$(term_color reset)" "$BP_RUN_ID"
}
