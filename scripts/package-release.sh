#!/usr/bin/env bash
# Package Blueprint CLI release archives for all Homebrew platforms.
#
# Usage:
#   ./scripts/package-release.sh [VERSION]
#
# VERSION defaults to contents of ./VERSION (must match git tag vVERSION when releasing).
# Writes under dist/:
#   blueprint_<VER>_darwin_arm64.tar.gz
#   blueprint_<VER>_darwin_amd64.tar.gz
#   blueprint_<VER>_linux_arm64.tar.gz
#   blueprint_<VER>_linux_amd64.tar.gz
#   checksums.txt
#   *.sha256 (per-archive)
#
# The CLI is Bash-portable; platform suffixes exist so Homebrew can select by OS/arch.
# Archive layout (single top-level directory):
#   blueprint_<VER>_<os>_<arch>/
#     blueprint
#     VERSION
#     LICENSE
#     README.md
#     lib/
#     builtin/
#     contributor/   (optional)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VER="${1:-}"
if [[ -z "$VER" ]]; then
  [[ -f VERSION ]] || { echo "error: missing VERSION" >&2; exit 1; }
  VER="$(tr -d '[:space:]' < VERSION)"
fi
VER="${VER#v}"

if [[ ! "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.]+)?$ ]]; then
  echo "error: invalid version '$VER' (expected semver)" >&2
  exit 1
fi

FILE_VER="$(tr -d '[:space:]' < VERSION)"
if [[ "$FILE_VER" != "$VER" ]]; then
  echo "error: VERSION file ($FILE_VER) != package version ($VER)" >&2
  echo "       Update ./VERSION before packaging." >&2
  exit 1
fi

need() {
  local p="$1"
  [[ -e "$p" ]] || { echo "error: required path missing: $p" >&2; exit 1; }
}

need blueprint
need lib/blueprint
need builtin/templates/entrypoints/HARNESS.md
need VERSION
need LICENSE

chmod +x blueprint

DIST="${ROOT}/dist"
rm -rf "$DIST"
mkdir -p "$DIST"

stage_one() {
  local os="$1" arch="$2"
  local asset_stub="blueprint_${VER}_${os}_${arch}"
  local stage_root="${DIST}/staging_${os}_${arch}"
  local dir="${stage_root}/blueprint"
  rm -rf "$stage_root"
  mkdir -p "$dir"
  cp blueprint "${dir}/blueprint"
  chmod +x "${dir}/blueprint"
  cp VERSION LICENSE README.md "$dir/"
  cp -R lib "${dir}/lib"
  cp -R builtin "${dir}/builtin"
  if [[ -d contributor ]]; then
    cp -R contributor "${dir}/contributor"
  fi
  need "${dir}/blueprint"
  need "${dir}/lib/blueprint/assets.sh"
  need "${dir}/builtin/VERSION"
  need "${dir}/VERSION"

  # Deterministic tar+gzip (stable SHA256). Top-level dir is always "blueprint/".
  python3 - "$stage_root" "${DIST}/${asset_stub}.tar.gz" <<'PY'
import gzip, io, os, sys, tarfile

stage_root, out_path = sys.argv[1:3]  # contains blueprint/
mtime = 1704067200  # 2024-01-01 UTC
payload = os.path.join(stage_root, "blueprint")

buf = io.BytesIO()
with tarfile.open(fileobj=buf, mode="w") as tf:
    entries = ["blueprint"]
    for root, dirs, files in os.walk(payload):
        dirs.sort()
        files.sort()
        rel = os.path.relpath(root, payload)
        for f in files:
            if rel == ".":
                entries.append(os.path.join("blueprint", f))
            else:
                entries.append(os.path.join("blueprint", rel, f))
        if rel != ".":
            entries.append(os.path.join("blueprint", rel))
    for arcname in sorted(set(entries)):
        full = os.path.join(stage_root, arcname)
        if not os.path.lexists(full):
            raise SystemExit(f"missing {full}")
        ti = tf.gettarinfo(full, arcname=arcname)
        ti.uid = 0
        ti.gid = 0
        ti.uname = ""
        ti.gname = ""
        ti.mtime = mtime
        if ti.isfile():
            ti.mode = 0o755 if os.access(full, os.X_OK) else 0o644
            with open(full, "rb") as fh:
                tf.addfile(ti, fh)
        else:
            ti.mode = 0o755
            tf.addfile(ti)

raw = buf.getvalue()
with open(out_path, "wb") as fout, gzip.GzipFile(
    filename="", mode="wb", fileobj=fout, mtime=0, compresslevel=9
) as gz:
    gz.write(raw)
print(out_path)
PY
  rm -rf "$stage_root"
}

sha256_file() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  else
    echo "error: need shasum or sha256sum" >&2
    exit 1
  fi
}

# Platform matrix expected by Homebrew Formula / docs.
TARGETS=(
  "darwin arm64"
  "darwin amd64"
  "linux arm64"
  "linux amd64"
)

for pair in "${TARGETS[@]}"; do
  # shellcheck disable=SC2086
  set -- $pair
  stage_one "$1" "$2"
done

CHECKSUMS="${DIST}/checksums.txt"
: > "$CHECKSUMS"
for pair in "${TARGETS[@]}"; do
  # shellcheck disable=SC2086
  set -- $pair
  asset="blueprint_${VER}_${1}_${2}.tar.gz"
  path="${DIST}/${asset}"
  [[ -f "$path" ]] || { echo "error: missing artifact $asset" >&2; exit 1; }
  sum="$(sha256_file "$path")"
  if [[ -z "$sum" || "$sum" == "0000000000000000000000000000000000000000000000000000000000000000" ]]; then
    echo "error: invalid checksum for $asset" >&2
    exit 1
  fi
  printf '%s  %s\n' "$sum" "$asset" >> "$CHECKSUMS"
  printf '%s\n' "$sum" > "${DIST}/${asset}.sha256"
done

echo "Packaged version ${VER}:"
ls -la "$DIST"
echo
echo "checksums.txt:"
cat "$CHECKSUMS"
