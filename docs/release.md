# Release architecture

Blueprint CLI releases are owned by **`krerapus/agent-harness-blueprint`**.

The Homebrew tap only consumes GitHub Release artifacts. It is **not** the source of truth.

```text
Developer
   │
   ▼
git tag vX.Y.Z  (must match ./VERSION)
   │
   ▼
GitHub Actions  (.github/workflows/cli-release.yml)
   │
   ├─ validate tag ↔ VERSION
   ├─ run tests/cli/smoke.sh
   ├─ scripts/package-release.sh
   ├─ scripts/verify-release-archive.sh
   ├─ checksums.txt (real SHA256)
   ▼
GitHub Release vX.Y.Z
   │  blueprint_<VER>_darwin_arm64.tar.gz
   │  blueprint_<VER>_darwin_amd64.tar.gz
   │  blueprint_<VER>_linux_arm64.tar.gz
   │  blueprint_<VER>_linux_amd64.tar.gz
   │  checksums.txt
   ▼
Homebrew tap (krerapus/homebrew-blueprint)
   │  Formula/blueprint.rb  ← urls + sha256
   ▼
brew install blueprint
```

## Ownership

| Owner | Owns |
|-------|------|
| `agent-harness-blueprint` | source, `VERSION`, build/package, GitHub Release assets |
| `homebrew-blueprint` | Formula metadata only (urls, sha256, caveats, test) |
| GitHub Actions | test, package, checksums, release upload, optional formula PR |

## Versioning

- Single source of truth: `./VERSION` in this repo
- Release tags: `vMAJOR.MINOR.PATCH` (example: `v1.4.0`)
- Tag version **must** equal `VERSION` or CI fails
- `blueprint --version` reads `VERSION` next to the installed script

```bash
# bump VERSION in a PR, merge, then:
git tag v1.4.0
git push origin v1.4.0
```

Do **not** create a tag whose version does not match `./VERSION`.

## Build matrix / artifacts

The CLI is Bash-portable. CI still emits **four** identically structured archives so Homebrew can select by OS/arch:

| OS | Arch | Artifact |
|----|------|----------|
| macOS | arm64 | `blueprint_<VERSION>_darwin_arm64.tar.gz` |
| macOS | amd64 | `blueprint_<VERSION>_darwin_amd64.tar.gz` |
| Linux | arm64 | `blueprint_<VERSION>_linux_arm64.tar.gz` |
| Linux | amd64 | `blueprint_<VERSION>_linux_amd64.tar.gz` |

Each archive contains a single top-level directory `blueprint/` with:

```text
blueprint/
  blueprint          # executable entrypoint
  VERSION
  LICENSE
  README.md
  lib/
  builtin/
  contributor/       # optional
```

Platform archives are content-identical (Bash CLI); filenames differ so Homebrew can select by OS/arch. Checksums are deterministic.
## Local packaging

```bash
./scripts/package-release.sh          # uses ./VERSION
./scripts/verify-release-archive.sh --all dist
```

## Checksums

`dist/checksums.txt` format:

```text
<sha256>  blueprint_<VER>_darwin_arm64.tar.gz
...
```

Placeholder `0000…0000` checksums are rejected by packaging and formula bump scripts.

## Failure behavior

CI fails if:

- tag does not match `v*.*.*`
- `VERSION` ≠ tag version
- smoke tests fail
- any required archive is missing
- checksum missing / placeholder
- archive fails `verify-release-archive.sh`
- release upload succeeds but remote assets are incomplete

See also: [distribution.md](distribution.md), [homebrew.md](homebrew.md).
