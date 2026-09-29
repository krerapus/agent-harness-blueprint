#!/usr/bin/env bash
# Render compact GitHub Release notes from CHANGELOG.md (+ optional Highlights).
#
# Usage:
#   ./scripts/render-release-notes.sh --kind cli --version 1.5.0
#   ./scripts/render-release-notes.sh --kind cli --version 1.5.0 --pre-label rc.1
#   ./scripts/render-release-notes.sh --kind assets --pack core --version 1.5.2
#   ./scripts/render-release-notes.sh --kind assets --pack core --version 1.5.2 --pre-label rc.1
#
# Options:
#   --changelog PATH   default: ./CHANGELOG.md
#   --summary TEXT     one-line blurb (optional)
#   --out PATH         write file instead of stdout
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIND=""
VERSION=""
PACK=""
PRE_LABEL=""
CHANGELOG="${ROOT}/CHANGELOG.md"
SUMMARY=""
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind) KIND="${2:?}"; shift 2 ;;
    --version) VERSION="${2:?}"; shift 2 ;;
    --pack) PACK="${2:?}"; shift 2 ;;
    --pre-label) PRE_LABEL="${2:?}"; shift 2 ;;
    --changelog) CHANGELOG="${2:?}"; shift 2 ;;
    --summary) SUMMARY="${2:?}"; shift 2 ;;
    --out) OUT="${2:?}"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) echo "error: unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$KIND" && -n "$VERSION" ]] || { echo "error: --kind and --version required" >&2; exit 2; }
[[ -f "$CHANGELOG" ]] || { echo "error: missing changelog: $CHANGELOG" >&2; exit 1; }

# Extract bullets for ## [VERSION] — prefer ### Highlights, else first bullets under Added/Changed/Fixed.
extract_highlights() {
  local ver="$1"
  python3 - "$CHANGELOG" "$ver" <<'PY'
import re, sys
path, ver = sys.argv[1:3]
text = open(path, encoding="utf-8").read()
# Section until next ## [
m = re.search(rf"(?ms)^## \[{re.escape(ver)}\][^\n]*\n(.*?)(?=^## \[|\Z)", text)
if not m:
    sys.exit(0)
body = m.group(1)
hm = re.search(r"(?ms)^### Highlights\s*\n(.*?)(?=^### |\Z)", body)
if hm:
    bullets = re.findall(r"(?m)^- .+$", hm.group(1))
else:
    bullets = []
    for sec in ("Added", "Changed", "Fixed"):
        sm = re.search(rf"(?ms)^### {sec}\s*\n(.*?)(?=^### |\Z)", body)
        if sm:
            bullets.extend(re.findall(r"(?m)^- .+$", sm.group(1)))
bullets = bullets[:5]
print("\n".join(bullets))
PY
}

HIGHLIGHTS="$(extract_highlights "$VERSION")"
if [[ -z "$HIGHLIGHTS" ]]; then
  HIGHLIGHTS="- See CHANGELOG.md for details in this release."
fi

REPO_CLI="https://github.com/krerapus/agent-harness-blueprint"
REPO_ASSETS="https://github.com/krerapus/assets-blueprint"

render() {
  if [[ -n "$PRE_LABEL" ]]; then
    local pre="${VERSION}-${PRE_LABEL}"
    if [[ "$KIND" == "cli" ]]; then
      cat <<EOF
## Blueprint CLI ${pre} (pre-release)

**Not** Homebrew / not latest. For testing only.

### Try it
1. Download \`blueprint_${pre}_<os>_<arch>.tar.gz\` below
2. \`tar -xzf … && ./blueprint/blueprint --version\`

### When ready
Run **CLI Release** with confirm=\`${VERSION}\` (Formula bumps only on production).

### Notes
- Base \`./VERSION\` stays \`${VERSION}\`
- Full changelog: ${REPO_CLI}/blob/v${VERSION}/CHANGELOG.md
EOF
    else
      [[ -n "$PACK" ]] || { echo "error: --pack required for assets" >&2; exit 2; }
      cat <<EOF
## Pack \`${PACK}\` ${pre} (pre-release)

**Not** catalog latest. Pin explicitly to test:

\`\`\`bash
blueprint assets install ${PACK}@${pre}
\`\`\`

When ready, run **Assets Release** with confirm_version=\`${VERSION}\`.

### Notes
- Full changelog: ${REPO_ASSETS}/blob/${PACK}-v${VERSION}/CHANGELOG.md
EOF
    fi
    return 0
  fi

  if [[ "$KIND" == "cli" ]]; then
    local blurb="${SUMMARY:-Asset-backed CLI release.}"
    cat <<EOF
## Blueprint CLI ${VERSION}

${blurb}

### Highlights
${HIGHLIGHTS}

### Upgrade
\`\`\`bash
brew update && brew upgrade krerapus/blueprint/blueprint
blueprint --version   # expect ${VERSION}
blueprint assets install core
\`\`\`

### Notes
- Full changelog: ${REPO_CLI}/blob/v${VERSION}/CHANGELOG.md
- Packs are separate — install/update via \`blueprint assets …\`
EOF
  else
    [[ -n "$PACK" ]] || { echo "error: --pack required for assets" >&2; exit 2; }
    local blurb="${SUMMARY:-Harness content pack release.}"
    cat <<EOF
## Pack \`${PACK}\` ${VERSION}

${blurb}

### Highlights
${HIGHLIGHTS}

### Upgrade
\`\`\`bash
blueprint assets install ${PACK}@${VERSION}
# or: blueprint assets update ${PACK}
\`\`\`

### Notes
- Full changelog: ${REPO_ASSETS}/blob/${PACK}-v${VERSION}/CHANGELOG.md
- Requires a CLI that satisfies this pack's \`cli_compat\`
EOF
  fi
}

NOTES="$(render)"
if [[ -n "$OUT" ]]; then
  printf '%s\n' "$NOTES" > "$OUT"
else
  printf '%s\n' "$NOTES"
fi
