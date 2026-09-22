#!/usr/bin/env bash
# Update homebrew-blueprint Formula/blueprint.rb from a release dist/ directory.
#
# Usage:
#   ./scripts/bump-homebrew-formula.sh <VERSION> <path-to-dist> <path-to-formula.rb>
#
# Rewrites version, release download URLs, and sha256 for all four platform archives.
# Fails if any checksum is missing or is the all-zero placeholder.
set -euo pipefail

VER="${1:-}"
DIST="${2:-}"
FORMULA="${3:-}"

if [[ -z "$VER" || -z "$DIST" || -z "$FORMULA" ]]; then
  echo "usage: $0 <VERSION> <dist-dir> <Formula/blueprint.rb>" >&2
  exit 2
fi
VER="${VER#v}"
[[ -d "$DIST" ]] || { echo "error: dist not found: $DIST" >&2; exit 1; }
[[ -f "$FORMULA" ]] || { echo "error: formula not found: $FORMULA" >&2; exit 1; }

python3 - "$VER" "$DIST" "$FORMULA" <<'PY'
import pathlib, re, sys

ver, dist_s, formula_s = sys.argv[1:4]
dist = pathlib.Path(dist_s)
formula_path = pathlib.Path(formula_s)
text = formula_path.read_text()

targets = [
    ("darwin", "arm64"),
    ("darwin", "amd64"),
    ("linux", "arm64"),
    ("linux", "amd64"),
]

def sha_for(asset: str) -> str:
    side = dist / f"{asset}.sha256"
    if side.is_file():
        s = side.read_text().strip().split()[0]
    else:
        sums = dist / "checksums.txt"
        if not sums.is_file():
            raise SystemExit(f"missing checksums for {asset}")
        s = None
        for line in sums.read_text().splitlines():
            parts = line.split()
            if len(parts) >= 2 and parts[-1] == asset:
                s = parts[0]
                break
        if not s:
            raise SystemExit(f"checksum not found for {asset}")
    if not re.fullmatch(r"[0-9a-fA-F]{64}", s):
        raise SystemExit(f"invalid sha256 for {asset}: {s!r}")
    if s == "0" * 64:
        raise SystemExit(f"placeholder sha256 for {asset}")
    return s.lower()

# version "…"
text2, n = re.subn(
    r'version\s+"[^"]+"',
    f'version "{ver}"',
    text,
    count=1,
)
if n != 1:
    raise SystemExit(f"failed to patch version (matches={n})")

for os_name, arch in targets:
    asset = f"blueprint_{ver}_{os_name}_{arch}.tar.gz"
    url = f"https://github.com/krerapus/agent-harness-blueprint/releases/download/v{ver}/{asset}"
    sha = sha_for(asset)
    # Replace the url+sha256 block for this os/arch by matching the prior asset or platform comment region.
    # Strategy: find url line containing this os_arch pattern (darwin_arm64 etc) OR any blueprint_*_{os}_{arch}
    pat = re.compile(
        rf'(url\s+")[^"]*blueprint_[^"]*_{re.escape(os_name)}_{re.escape(arch)}\.tar\.gz("\s*\n\s*sha256\s+")[^"]+(")',
        re.MULTILINE,
    )
    text2, n = pat.subn(rf'\g<1>{url}\g<2>{sha}\g<3>', text2, count=1)
    if n != 1:
        raise SystemExit(f"failed to patch url/sha for {os_name}/{arch} (matches={n})")

if "0000000000000000000000000000000000000000000000000000000000000000" in text2:
    raise SystemExit("formula still contains placeholder sha256 after bump")

formula_path.write_text(text2)
print(f"updated {formula_path} → version {ver}")
for os_name, arch in targets:
    asset = f"blueprint_{ver}_{os_name}_{arch}.tar.gz"
    print(f"  {asset}  {sha_for(asset)}")
PY
