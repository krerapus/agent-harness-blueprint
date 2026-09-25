# Release workflow (human-triggered)

Releases are **not** started by pushing a git tag. A human runs the GitHub Action; the workflow creates the tag (if missing), publishes the GitHub Release, and (for CLI) updates the Homebrew Formula.

```text
Human (Actions → Run workflow)
        │
        ├─► assets-blueprint  "Assets Release"
        │      confirm pack + version
        │      → tag <pack>-vX.Y.Z
        │      → GitHub Release (pack tarball)
        │      → Formula unchanged
        │
        └─► agent-harness-blueprint  "CLI Release"
               confirm VERSION
               → smoke (checks out assets-blueprint)
               → package 4 CLI archives + checksums
               → tag vX.Y.Z
               → GitHub Release
               → Formula PR on homebrew-blueprint → auto-merge
```

## What updates what

| Manual workflow | Repo | Creates | Updates Homebrew Formula? |
|-----------------|------|---------|----------------------------|
| **Assets Release** | `assets-blueprint` | Pack tag + Release (`core-v1.5.2`, …) | **No** |
| **CLI Release** | `agent-harness-blueprint` | CLI tag + Release (`v1.5.0`) | **Yes** (PR + auto-merge) |

The Formula only bottles CLI archives. Packs are installed later with `blueprint assets install`.

## Prerequisites

### Before any release

1. Version bumps merged to `master` (`VERSION` / `packs/*/pack.yaml` + `catalog.yaml`).
2. You can run workflows on the repo (write access).

### CLI → Formula

| Secret | Where | Purpose |
|--------|-------|---------|
| `HOMEBREW_TAP_TOKEN` | `agent-harness-blueprint` repo secrets | Push branch + open/merge PRs on `krerapus/homebrew-blueprint` |

Token needs **contents: write** (and PR create/merge) on the tap. If Formula bump is enabled and the secret is missing, the CLI Release **fails** (release assets may already be published).

On the tap repo, allow the bot to merge (branch protection: either no required checks, or allow auto-merge for the token user).

## Recommended order

1. **Assets first** (so Homebrew users can `blueprint assets install core` after upgrading the CLI).
2. **CLI second** (publishes CLI + bumps Formula).

## How to run — Assets Release

1. Open [assets-blueprint → Actions → Assets Release](https://github.com/krerapus/assets-blueprint/actions/workflows/assets-release.yml).
2. **Run workflow** on `master`.
3. Inputs:
   - **pack** — `core` / `prompts` / `memories` / `examples`
   - **confirm_version** — must equal `packs/<pack>/pack.yaml` `version` (and `catalog.yaml`)
   - **dry_run** — `true` to package only (no tag/release)
4. Wait for green. Confirm Release under **Releases** (`core-v…`, etc.).

CLI equivalent:

```bash
gh workflow run "Assets Release" --repo krerapus/assets-blueprint \
  -f pack=core -f confirm_version=1.5.2 -f dry_run=false
```

## How to run — CLI Release

1. Open [agent-harness-blueprint → Actions → CLI Release](https://github.com/krerapus/agent-harness-blueprint/actions/workflows/cli-release.yml).
2. **Run workflow** on `master`.
3. Inputs:
   - **confirm** — must equal `./VERSION` (e.g. `1.5.0`)
   - **bump_formula** — `true` to open + auto-merge Formula PR (default)
   - **dry_run** — `true` to smoke + package only
4. Wait for green. Confirm:
   - GitHub Release `v…` with four archives + `checksums.txt`
   - Tap `master` Formula version matches (auto-merged PR)

```bash
gh workflow run "CLI Release" --repo krerapus/agent-harness-blueprint \
  -f confirm=1.5.0 -f bump_formula=true -f dry_run=false
```

### Dry run

Use `dry_run=true` to validate smoke + packaging without tagging or publishing.

## After CLI + Formula

```bash
brew update
brew upgrade krerapus/blueprint/blueprint   # or reinstall
blueprint --version
blueprint assets install core
blueprint assets doctor
```

## Failure modes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Workflow won't start | No Actions permission / wrong branch | Run on `master` with write access |
| confirm / confirm_version mismatch | Typo vs file on `master` | Re-read `VERSION` or `pack.yaml` |
| Smoke fails (CLI) | assets checkout failed / pack broken | Check assets `master`; inspect smoke log |
| Formula job fails: no token | Missing `HOMEBREW_TAP_TOKEN` | Add secret; re-run with bump, or bump manually ([homebrew.md](homebrew.md)) |
| Auto-merge stuck | Required checks on tap | Merge Formula PR manually or relax tap protection |
| Tag already exists | Re-run after partial success | Workflow reuses tag; uploads/clobbers release assets |

## Related docs

- [release.md](release.md) — versioning, artifact layout, local packaging
- [homebrew.md](homebrew.md) — tap install, secrets, manual Formula bump
- [distribution.md](distribution.md) — channels overview
- Assets pack inventory: [assets-blueprint docs](https://github.com/krerapus/assets-blueprint/tree/master/docs)
