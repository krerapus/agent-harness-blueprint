# Homebrew

## Relationship

```text
krerapus/agent-harness-blueprint   ← source of truth (build + GitHub Release)
                 │
                 ▼  release assets
krerapus/homebrew-blueprint        ← Formula only (distribution metadata)
                 │
                 ▼
            brew install blueprint
```

**Homebrew Tap ≠ source of truth.**

Tap install:

```bash
brew tap krerapus/blueprint https://github.com/krerapus/homebrew-blueprint
brew install blueprint
```

(`krerapus/blueprint` is the tap name; the GitHub repo is `homebrew-blueprint`.)

## Formula responsibilities

`Formula/blueprint.rb` must:

- Select macOS/Linux and arm64/amd64
- Point `url` at `.../releases/download/v<VER>/blueprint_<VER>_<os>_<arch>.tar.gz`
- Use **real** SHA256 (never leave `0000…0000` in a published formula)
- `libexec.install` the full archive (`blueprint`, `VERSION`, `lib`, `builtin`, …)
- Expose `bin/blueprint` via `write_exec_script`
- Keep asset commands working (`assets install/list/doctor`)

## Automatic formula updates

After a successful CLI release, `.github/workflows/cli-release.yml` job `bump-formula`:

1. Downloads release artifacts / checksums
2. Runs `scripts/bump-homebrew-formula.sh`
3. Opens a PR on `krerapus/homebrew-blueprint`

### Required secret

| Secret | Repo | Permissions |
|--------|------|-------------|
| `HOMEBREW_TAP_TOKEN` | `agent-harness-blueprint` | Fine-grained or classic PAT that can push to `krerapus/homebrew-blueprint` and open PRs |

Least privilege: contents read/write on the tap repo only. Do **not** commit tokens.

If the secret is missing, the release still publishes; formula bump is skipped with a warning. Update manually:

```bash
./scripts/package-release.sh
./scripts/bump-homebrew-formula.sh 1.4.0 dist ../homebrew-blueprint/Formula/blueprint.rb
# commit + PR in homebrew-blueprint
```

## Manual formula bump

```bash
# In agent-harness-blueprint (after assets exist in dist/ or download checksums.txt)
./scripts/bump-homebrew-formula.sh <VER> dist /path/to/homebrew-blueprint/Formula/blueprint.rb
ruby -c /path/to/homebrew-blueprint/Formula/blueprint.rb
grep sha256 /path/to/homebrew-blueprint/Formula/blueprint.rb
```

## Verification after formula merge

```bash
brew update
brew uninstall blueprint || true
brew install krerapus/blueprint/blueprint
blueprint --version
blueprint assets list
blueprint assets doctor --offline
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| 404 on brew fetch | Release/tag/asset missing | Publish CLI release assets; ensure Formula uses `v` tag |
| Checksum mismatch | Formula not bumped after re-upload | Re-run bump script |
| Missing `lib/` at runtime | Old Formula used `bin.install` only | Use libexec layout Formula |
| Bump job skipped | No `HOMEBREW_TAP_TOKEN` | Add secret or bump manually |
