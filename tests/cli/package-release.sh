#!/usr/bin/env bash
# Packaging / release-archive tests (catches formula↔artifact mismatches).
# Run: ./tests/cli/package-release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

assert() {
  local label="$1"
  shift
  if "$@"; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label"
    FAIL=$((FAIL + 1))
  fi
}

echo "== package-release =="
chmod +x scripts/package-release.sh scripts/verify-release-archive.sh scripts/bump-homebrew-formula.sh

# Isolate dist under a temp dir by running package then moving — package-release writes ROOT/dist.
rm -rf dist
./scripts/package-release.sh

VER="$(tr -d '[:space:]' < VERSION)"
assert "darwin_arm64 artifact exists" test -f "dist/blueprint_${VER}_darwin_arm64.tar.gz"
assert "darwin_amd64 artifact exists" test -f "dist/blueprint_${VER}_darwin_amd64.tar.gz"
assert "linux_arm64 artifact exists" test -f "dist/blueprint_${VER}_linux_arm64.tar.gz"
assert "linux_amd64 artifact exists" test -f "dist/blueprint_${VER}_linux_amd64.tar.gz"
assert "checksums.txt exists" test -f dist/checksums.txt
assert "no placeholder checksums" bash -c "! grep -q '0000000000000000000000000000000000000000000000000000000000000000' dist/checksums.txt"

./scripts/verify-release-archive.sh --all dist
assert "verify-release-archive --all" true

# Simulate Homebrew libexec layout: extract and ensure --version + lib siblings.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/bp-pkg-test.XXXXXX")"
tar -xzf "dist/blueprint_${VER}_darwin_arm64.tar.gz" -C "$TMP"
TOP="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -1)"
OUT="$("${TOP}/blueprint" --version)"
assert "version output contains ${VER}" bash -c "[[ \"$OUT\" == *\"$VER\"* ]]"
assert "libexec-style lib present" test -f "${TOP}/lib/blueprint/assets.sh"
assert "builtin present" test -d "${TOP}/builtin/templates/entrypoints"

# Formula bump against a temp copy must reject placeholders and write real shas.
FORMULA_TMP="$(mktemp "${TMPDIR:-/tmp}/blueprint.rb.XXXXXX")"
cat > "$FORMULA_TMP" <<EOF
class Blueprint < Formula
  version "0.0.0"
  on_macos do
    on_arm do
      url "https://example.invalid/blueprint_0.0.0_darwin_arm64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://example.invalid/blueprint_0.0.0_darwin_amd64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end
  on_linux do
    on_arm do
      url "https://example.invalid/blueprint_0.0.0_linux_arm64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://example.invalid/blueprint_0.0.0_linux_amd64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end
end
EOF

./scripts/bump-homebrew-formula.sh "$VER" dist "$FORMULA_TMP"
assert "bump wrote version" bash -c "grep -q 'version \"${VER}\"' \"$FORMULA_TMP\""
assert "bump wrote v-tag urls" bash -c "grep -q 'releases/download/v${VER}/' \"$FORMULA_TMP\""
assert "bump removed placeholders" bash -c "! grep -q '0000000000000000000000000000000000000000000000000000000000000000' \"$FORMULA_TMP\""

rm -rf "$TMP" "$FORMULA_TMP"

echo
echo "Results: pass=$PASS fail=$FAIL"
[[ "$FAIL" -eq 0 ]]
