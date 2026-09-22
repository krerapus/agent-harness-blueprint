# Distribution

How Blueprint reaches end-user machines.

## Channels

| Channel | Mechanism | Source of truth |
|---------|-----------|-----------------|
| Git checkout | `./blueprint` from clone | this repo |
| GitHub Release | download platform tarball | this repo’s Releases |
| Homebrew | `brew install blueprint` | Formula in `homebrew-blueprint`, **artifacts from this repo** |

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

Packs come from [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) Releases / local checkout.

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

## End-user install (Homebrew)

```bash
brew tap krerapus/blueprint https://github.com/krerapus/homebrew-blueprint
brew install blueprint
blueprint --version
blueprint assets install core
blueprint assets list
blueprint assets doctor --offline
```

## Pre-announce verification

Before announcing a release:

1. Open `https://github.com/krerapus/agent-harness-blueprint/releases/tag/vX.Y.Z`
2. Confirm all four tarballs + `checksums.txt` are attached
3. Download the archive for your machine; run `./scripts/verify-release-archive.sh <file>`
4. Confirm Formula PR merged / sha256 match `checksums.txt`
5. On a clean machine (or `brew uninstall blueprint`):

```bash
brew update
brew uninstall blueprint || true
brew install krerapus/blueprint/blueprint
blueprint --version          # must equal X.Y.Z
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

See [release.md](release.md) and [homebrew.md](homebrew.md).
