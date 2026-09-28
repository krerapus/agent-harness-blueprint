# Blueprint forge auth + git identity (user-level, once).
# shellcheck shell=bash

# --- config helpers (naive YAML; keys under git:) ---

bp_git_identity_file() {
  printf '%s/credentials/git' "$(bp_config_dir)"
}

bp_git_identity_get() {
  # Usage: bp_git_identity_get name|email
  local key="$1"
  local file
  file="$(bp_git_identity_file)"
  [[ -f "$file" ]] || return 0
  case "$key" in
    name) grep -E '^name=' "$file" 2>/dev/null | head -1 | cut -d= -f2- || true ;;
    email) grep -E '^email=' "$file" 2>/dev/null | head -1 | cut -d= -f2- || true ;;
    *) return 1 ;;
  esac
}

bp_git_identity_set() {
  # Usage: bp_git_identity_set <name> <email>
  local name="$1"
  local email="$2"
  bp_ensure_xdg_dirs
  local file
  file="$(bp_git_identity_file)"
  umask 077
  cat > "$file" <<EOF
# Blueprint git identity (applied as git config --local on install). Do not commit.
name=${name}
email=${email}
EOF
  chmod 600 "$file" 2>/dev/null || true
}

bp_apply_git_identity_to_target() {
  # Apply stored identity as local git config when target is a git work tree.
  local dest_root="$1"
  local name email
  name="$(bp_git_identity_get name)"
  email="$(bp_git_identity_get email)"
  if [[ -z "$name" && -z "$email" ]]; then
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit_info "dry-run: would apply git identity to ${dest_root}"
    return 0
  fi
  if ! git -C "$dest_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    emit_info "skip git identity: ${dest_root} is not a git repository"
    return 0
  fi
  if [[ -n "$name" ]]; then
    git -C "$dest_root" config --local user.name "$name"
    emit_info "git user.name ← ${name}"
  fi
  if [[ -n "$email" ]]; then
    git -C "$dest_root" config --local user.email "$email"
    emit_info "git user.email ← ${email}"
  fi
}

bp_ensure_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    emit_info "installing gh via Homebrew"
    brew install gh
    return $?
  fi
  emit_error "Install GitHub CLI: https://cli.github.com/"
  return 1
}

bp_ensure_glab() {
  if command -v glab >/dev/null 2>&1; then
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    emit_info "installing glab via Homebrew"
    brew install glab
    return $?
  fi
  emit_error "Install GitLab CLI: https://gitlab.com/gitlab-org/cli"
  return 1
}

cmd_auth_login_github() {
  bp_ensure_gh || return 1
  emit_info "Delegating to: gh auth login (tokens stay in gh's credential store)"
  gh auth login "$@"
}

cmd_auth_login_gitlab() {
  local host="${AUTH_HOSTNAME:-}"
  bp_ensure_glab || return 1
  if [[ -n "$host" ]]; then
    emit_info "Delegating to: glab auth login --hostname ${host}"
    glab auth login --hostname "$host" "$@"
  else
    emit_info "Delegating to: glab auth login (tokens stay in glab's credential store)"
    glab auth login "$@"
  fi
}

cmd_auth_status() {
  bp_ensure_xdg_dirs
  ui_header "Auth status"
  ui_section "Git identity (blueprint)"
  local name email
  name="$(bp_git_identity_get name)"
  email="$(bp_git_identity_get email)"
  if [[ -n "$name" || -n "$email" ]]; then
    ui_ok "name=${name:--}  email=${email:--}"
    ui_kv "file" "$(bp_git_identity_file)"
  else
    ui_skip "not set — run: blueprint auth git --name \"You\" --email you@example.com"
  fi

  ui_section "GitHub (gh)"
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      ui_ok "authenticated"
      gh auth status 2>&1 | sed 's/^/    /' || true
    else
      ui_fail "not authenticated — run: blueprint auth login github"
    fi
  else
    ui_skip "gh not installed"
  fi

  ui_section "GitLab (glab)"
  if command -v glab >/dev/null 2>&1; then
    if glab auth status >/dev/null 2>&1; then
      ui_ok "authenticated"
      glab auth status 2>&1 | sed 's/^/    /' || true
    else
      ui_fail "not authenticated — run: blueprint auth login gitlab [--hostname HOST]"
    fi
  else
    ui_skip "glab not installed"
  fi
}

cmd_auth_git() {
  local name="${AUTH_GIT_NAME:-}"
  local email="${AUTH_GIT_EMAIL:-}"
  local def_name def_email
  def_name="$(bp_git_identity_get name)"
  [[ -n "$def_name" ]] || def_name="$(git config --global user.name 2>/dev/null || true)"
  def_email="$(bp_git_identity_get email)"
  [[ -n "$def_email" ]] || def_email="$(git config --global user.email 2>/dev/null || true)"

  if [[ (-z "$name" || -z "$email") && -t 0 && -t 1 ]]; then
    if [[ -z "$name" ]]; then
      prompt_line "Git user.name" "$def_name" || return 1
      name="${BP_PROMPT_VALUE:-$def_name}"
    fi
    if [[ -z "$email" ]]; then
      prompt_line "Git user.email" "$def_email" || return 1
      email="${BP_PROMPT_VALUE:-$def_email}"
    fi
  fi
  if [[ -z "$name" || -z "$email" ]]; then
    emit_error "Usage: blueprint auth git --name \"Your Name\" --email you@example.com"
    return 2
  fi
  bp_git_identity_set "$name" "$email"
  ui_ok "saved git identity → $(bp_git_identity_file)"
  ui_info "Applied automatically on: blueprint install --target <repo>"
}

cmd_auth_usage() {
  cat <<'EOF'
Usage: blueprint auth <command> [flags]

Commands:
  login github              One-time GitHub auth (wraps: gh auth login)
  login gitlab              One-time GitLab auth (wraps: glab auth login)
  status                    Show gh / glab / blueprint git identity
  git                       Set git user.name + user.email once for all install targets

Flags:
  --hostname HOST           GitLab host for login gitlab (e.g. gitlab.com or self-hosted)
  --name NAME               With auth git
  --email EMAIL             With auth git
  --target PATH             Unused for auth (identity is user-level under ~/.config/blueprint/)

Notes:
  - Forge tokens stay in gh/glab credential stores (shared by every agent/project).
  - Git identity is stored in ~/.config/blueprint/credentials/git (mode 600).
  - blueprint install applies that identity as git config --local on the target repo.
EOF
}

cmd_auth() {
  local sub="${1:-}"
  shift || true
  case "$sub" in
    ""|-h|--help|help)
      cmd_auth_usage
      ;;
    status)
      cmd_auth_status
      ;;
    git)
      cmd_auth_git
      ;;
    login)
      local forge="${1:-}"
      shift || true
      case "$forge" in
        github|gh)
          cmd_auth_login_github "$@"
          ;;
        gitlab|glab)
          cmd_auth_login_gitlab "$@"
          ;;
        *)
          emit_error "Usage: blueprint auth login {github|gitlab}"
          return 2
          ;;
      esac
      ;;
    *)
      emit_error "unknown auth command: ${sub:-} (see: blueprint auth --help)"
      return 2
      ;;
  esac
}

bp_doctor_auth_section() {
  ui_section "Auth"
  local name email
  name="$(bp_git_identity_get name)"
  email="$(bp_git_identity_get email)"
  if [[ -n "$name" && -n "$email" ]]; then
    ui_ok "git identity (${name} <${email}>)"
  else
    ui_skip "git identity not set (blueprint auth git)"
  fi
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      ui_ok "gh authenticated"
    else
      ui_skip "gh present but not authenticated (blueprint auth login github)"
    fi
  fi
  if command -v glab >/dev/null 2>&1; then
    if glab auth status >/dev/null 2>&1; then
      ui_ok "glab authenticated"
    else
      ui_skip "glab present but not authenticated (blueprint auth login gitlab)"
    fi
  fi
}
