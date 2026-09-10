#!/usr/bin/env bash
# Verify a Blueprint CLI release archive matches Homebrew install assumptions.
#
# Usage:
#   ./scripts/verify-release-archive.sh dist/blueprint_1.4.0_darwin_arm64.tar.gz
#   ./scripts/verify-release-archive.sh --all dist/
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() { echo "error: $*" >&2; exit 1; }

verify_one() {
  local archive="$1"
  [[ -f "$archive" ]] || die "not a file: $archive"
  local name
  name="$(basename "$archive")"
  [[ "$name" =~ ^blueprint_[0-9]+\.[0-9]+\.[0-9]+.*_(darwin|linux)_(arm64|amd64)\.tar\.gz$ ]] \
    || die "unexpected archive name: $name"

  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/blueprint-verify.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN

  tar -xzf "$archive" -C "$tmp"
  local top
  top="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [[ -n "$top" ]] || die "$name: missing top-level directory"
  [[ -x "${top}/blueprint" ]] || die "$name: blueprint not executable"
  [[ -f "${top}/VERSION" ]] || die "$name: missing VERSION"
  [[ -d "${top}/lib/blueprint" ]] || die "$name: missing lib/blueprint"
  [[ -f "${top}/lib/blueprint/assets.sh" ]] || die "$name: missing assets.sh"
  [[ -d "${top}/builtin/templates/entrypoints" ]] || die "$name: missing builtin templates"

  local ver want
  ver="$(tr -d '[:space:]' < "${top}/VERSION")"
  want="$(echo "$name" | sed -n 's/^blueprint_\([0-9][^_]*\)_.*/\1/p')"
  [[ "$ver" == "$want" ]] || die "$name: VERSION ($ver) != archive version ($want)"

  # Smoke: --version must work with ROOT = archive root (Homebrew libexec model).
  local out
  out="$("${top}/blueprint" --version 2>&1)" || die "$name: blueprint --version failed"
  echo "$out" | grep -q "$ver" || die "$name: --version output '$out' missing $ver"

  # Offline doctor should not crash (assets may be missing; exit 0 or 1 both OK if binary runs).
  set +e
  "${top}/blueprint" assets doctor --offline >/dev/null 2>&1
  local rc=$?
  set -e
  [[ "$rc" -eq 0 || "$rc" -eq 1 ]] || die "$name: assets doctor crashed (exit $rc)"

  echo "OK  $name (version=$ver)"
}

if [[ "${1:-}" == "--all" ]]; then
  dir="${2:-${ROOT}/dist}"
  [[ -d "$dir" ]] || die "dist dir missing: $dir"
  shopt -s nullglob
  local_files=("$dir"/blueprint_*.tar.gz)
  [[ ${#local_files[@]} -gt 0 ]] || die "no blueprint_*.tar.gz in $dir"
  for f in "${local_files[@]}"; do
    verify_one "$f"
  done
  if [[ -f "${dir}/checksums.txt" ]]; then
    while read -r sum file; do
      [[ -n "${sum:-}" && -n "${file:-}" ]] || continue
      [[ "$sum" =~ ^[0-9a-fA-F]{64}$ ]] || die "bad checksum line: $sum $file"
      [[ "$sum" != "0000000000000000000000000000000000000000000000000000000000000000" ]] \
        || die "placeholder checksum for $file"
      path="${dir}/${file}"
      [[ -f "$path" ]] || die "checksums.txt references missing $file"
      if command -v shasum >/dev/null 2>&1; then
        got="$(shasum -a 256 "$path" | awk '{print $1}')"
      else
        got="$(sha256sum "$path" | awk '{print $1}')"
      fi
      [[ "$got" == "$sum" ]] || die "checksum mismatch for $file"
    done < "${dir}/checksums.txt"
    echo "OK  checksums.txt"
  fi
  exit 0
fi

[[ $# -ge 1 ]] || die "usage: $0 <archive.tar.gz> | --all [dist/]"
verify_one "$1"
