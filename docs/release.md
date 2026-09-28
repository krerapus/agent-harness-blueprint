# Release architecture

Blueprint CLI releases are owned by **`krerapus/agent-harness-blueprint`**.

**How to publish:** human-triggered Actions — **Pre-release** (test) then **Release** (production). See **[release-workflow.md](release-workflow.md)**.

Pushing a git tag does **not** start CI. Workflows create tags when you run them.

The Homebrew tap only consumes GitHub Release artifacts. It is **not** the source of truth.

```text
Human → Actions → CLI Release (confirm VERSION)
   │
   ▼
GitHub Actions  (.github/workflows/cli-release.yml)
   │
   ├─ confirm input ↔ ./VERSION
   ├─ checkout assets-blueprint (smoke)
   ├─ tests/cli/smoke.sh
   ├─ scripts/package-release.sh
   ├─ scripts/verify-release-archive.sh
   ├─ create tag vVERSION (if missing)
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
   │  Formula/blueprint.rb  ← urls + sha256 (PR auto-merged)
   ▼
brew install / upgrade blueprint
```

Recommended production order (details in [release-workflow.md](release-workflow.md)):

```text
Assets Release  →  CLI Release  →  Homebrew Formula update
```

## Ownership

| Owner | Owns |
|-------|------|
| `agent-harness-blueprint` | source, `VERSION`, build/package, GitHub Release assets |
| `assets-blueprint` | pack versions, pack Releases (`core-v*`, …) — no Formula rewrite |
| `homebrew-blueprint` | Formula metadata only (urls, sha256, caveats, test) |
| GitHub Actions | human-triggered release + formula bump |

## Distribution channels

| Channel | Mechanism | Source of truth |
|---------|-----------|-----------------|
| Git checkout | `./blueprint` from clone | this repo |
| GitHub Release | download platform tarball | this repo’s Releases |
| Homebrew | `brew install blueprint` | Formula in `homebrew-blueprint`, **artifacts from this repo** |

## Versioning

- Single source of truth: `./VERSION` in this repo
- Release tags: `vMAJOR.MINOR.PATCH` (example: `v1.5.0`)
- Workflow **confirm** input **must** equal `VERSION` or CI fails
- `blueprint --version` reads `VERSION` next to the installed script

```bash
# bump VERSION in a PR, merge to master, then:
# Actions → CLI Release → confirm=<VERSION> → Run workflow
# or:
gh workflow run "CLI Release" -f confirm=1.5.0 -f bump_formula=true -f dry_run=false
```

Do **not** invent a tag whose version does not match `./VERSION`.

## What gets distributed

### CLI release (this repo)

Minimum runtime layout (also what Homebrew installs under `libexec`):

- `blueprint` — entrypoint
- `lib/blueprint/*.sh` — runtime modules (assets, xdg, harness, …)
- `builtin/` — offline bootstrap templates
- `VERSION` — CLI semver for `--version`
- `contributor/` — optional package-contributor tooling

Independently versioned **asset packs** (`core`, `prompts`, …) are **not** bottled into the CLI release. Users run:

```bash
blueprint assets install core
```

Packs come from [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) Releases / local checkout. Pack publish steps: [assets release-workflow](https://github.com/krerapus/assets-blueprint/blob/master/docs/release-workflow.md).

### Build matrix / artifacts

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

### Homebrew install layout

```text
$(brew --prefix)/Cellar/blueprint/<ver>/
  libexec/
    blueprint
    VERSION
    lib/
    builtin/
    ...
  bin/
    blueprint   # write_exec_script → libexec/blueprint
```

`ROOT` is `libexec`, so `source "${ROOT}/lib/..."` and `builtin/` resolve correctly.

Formula bump, secrets, and tap maintenance: **[homebrew.md](homebrew.md)**.

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

- confirm input ≠ `VERSION`
- smoke tests fail (needs assets checkout)
- any required archive is missing
- checksum missing / placeholder
- archive fails `verify-release-archive.sh`
- release upload succeeds but remote assets are incomplete
- Formula bump enabled but `HOMEBREW_TAP_TOKEN` missing

## End-user install (Homebrew)

```bash
brew tap krerapus/blueprint
brew trust --formula krerapus/blueprint/blueprint   # Homebrew 6+/7, once
brew install krerapus/blueprint/blueprint
blueprint --version
blueprint assets install core
blueprint assets list
blueprint assets doctor --offline
```

## Troubleshooting

| Symptom | Likely cause | Verify | Fix |
|---------|--------------|--------|-----|
| `curl: (22) 404` / brew download fail | Release missing or wrong tag (`1.4.0` vs `v1.4.0`) | Open release URL in browser | Publish `vX.Y.Z` with assets; align Formula urls |
| SHA256 mismatch | Formula stale vs re-packaged assets | Compare Formula sha to `checksums.txt` | Re-run bump script / merge formula PR |
| `blueprint: lib/blueprint/term.sh: No such file` | Formula installed only the script into `bin/` | `ls $(brew --prefix)/opt/blueprint/libexec` | Use Formula that `libexec.install`s full tree |
| `--version` → `0.0.0` | Missing `VERSION` beside script | Check libexec | Repackage with `VERSION` |
| `assets doctor` fails offline | No core pack + no sibling assets repo | `blueprint assets list` | `blueprint assets install core` or set `BLUEPRINT_ASSETS_ROOT` |
| Formula still has `0000…` sha | Bump job skipped / token missing | Inspect Actions logs | Set `HOMEBREW_TAP_TOKEN`; run bump manually |
| Tap trust / formula not found | Tap not added or Formula not on default branch | `brew tap-info krerapus/blueprint` | Merge Formula to tap `master`/`main` |
| Wrong arch binary errors | Unlikely for Bash CLI; name mismatch | Check Formula `on_arm` / `on_intel` blocks | Fix url arch suffix |

See also: [release-workflow.md](release-workflow.md), [homebrew.md](homebrew.md).
