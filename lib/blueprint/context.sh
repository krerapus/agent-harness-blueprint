# Project context detection for header and validation.
# shellcheck shell=bash

BP_CTX_CWD=""
BP_CTX_ROOT=""
BP_CTX_NAME=""
BP_CTX_GIT_ROOT=""
BP_CTX_BRANCH=""
BP_CTX_DIRTY=0
BP_CTX_STATE=""
BP_CTX_SOURCE=""
BP_CTX_VERSION=""

context_find_root() {
  local start="$1"
  local dir
  dir="$(cd "$start" 2>/dev/null && pwd || echo "$start")"
  while true; do
    if [[ -f "${dir}/.agent-blueprint.yaml" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    if [[ -d "${dir}/.git" || -f "${dir}/.git" ]]; then
      # Prefer blueprint state when walking up; .git is a soft stop only if
      # we never find state — return git root as candidate.
      local git_candidate="$dir"
      local parent
      parent="$(dirname "$dir")"
      # Continue looking for state above? Prefer state over bare git.
      # Walk until filesystem root collecting; if state found higher, use it.
      local walk="$parent"
      while [[ "$walk" != "/" && "$walk" != "$dir" ]]; do
        if [[ -f "${walk}/.agent-blueprint.yaml" ]]; then
          printf '%s\n' "$walk"
          return 0
        fi
        if [[ "$walk" == "$(dirname "$walk")" ]]; then
          break
        fi
        walk="$(dirname "$walk")"
      done
      printf '%s\n' "$git_candidate"
      return 0
    fi
    local parent
    parent="$(dirname "$dir")"
    if [[ "$parent" == "$dir" ]]; then
      break
    fi
    dir="$parent"
  done
  return 1
}

context_load() {
  local target="$1"
  BP_CTX_CWD="$(pwd)"
  local abs
  if [[ -d "$target" ]]; then
    abs="$(cd "$target" && pwd)"
  else
    abs="$target"
  fi
  BP_CTX_ROOT="$abs"
  BP_CTX_NAME="$(basename "$abs")"
  BP_CTX_GIT_ROOT=""
  BP_CTX_BRANCH="unknown"
  BP_CTX_DIRTY=0
  BP_CTX_STATE=""
  BP_CTX_SOURCE=""
  BP_CTX_VERSION=""

  if [[ -f "${abs}/.agent-blueprint.yaml" ]]; then
    BP_CTX_STATE="${abs}/.agent-blueprint.yaml"
  fi

  if command -v git >/dev/null 2>&1; then
    if git -C "$abs" rev-parse --show-toplevel >/dev/null 2>&1; then
      BP_CTX_GIT_ROOT="$(git -C "$abs" rev-parse --show-toplevel 2>/dev/null || true)"
      BP_CTX_BRANCH="$(git -C "$abs" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
      if [[ -n "$(git -C "$abs" status --porcelain 2>/dev/null || true)" ]]; then
        BP_CTX_DIRTY=1
      fi
    fi
  fi

  if [[ -n "$BP_CTX_STATE" ]]; then
    BP_CTX_SOURCE="$(grep -E '^source:' "$BP_CTX_STATE" 2>/dev/null | head -1 | awk '{print $2}')"
    BP_CTX_VERSION="$(grep -E '^version:' "$BP_CTX_STATE" 2>/dev/null | head -1 | awk '{print $2}')"
  fi
}

context_apply_header() {
  local mode="$1"
  BP_HEADER_PROJECT="${BP_CTX_NAME:-unknown}"
  BP_HEADER_ROOT="${BP_CTX_ROOT:-.}"
  BP_HEADER_BRANCH="${BP_CTX_BRANCH:-unknown}"
  if [[ "${BP_CTX_DIRTY:-0}" -eq 1 && "$BP_HEADER_BRANCH" != "unknown" ]]; then
    BP_HEADER_BRANCH="${BP_HEADER_BRANCH}*"
  fi
  BP_HEADER_SOURCE="${BP_CTX_SOURCE:-local}"
  BP_HEADER_MODE="$mode"
}

context_require_markers() {
  local dest="$1"
  local allow_create="${2:-0}"
  if [[ -f "${dest}/.agent-blueprint.yaml" ]]; then
    return 0
  fi
  if [[ "$allow_create" -eq 1 ]]; then
    return 0
  fi
  # install may create into empty dirs; sync needs markers or existing target
  if [[ -d "${dest}/.git" || -f "${dest}/.git" ]]; then
    return 0
  fi
  cat >&2 <<EOF
Blueprint project root not found.
Run this command from a directory containing one of:
- .agent-blueprint.yaml
- .git/
Or pass --target to a valid consumer project.
EOF
  return 1
}
