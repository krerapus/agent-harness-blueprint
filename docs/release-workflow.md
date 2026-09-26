# Release workflow (human-triggered)

Releases are **not** started by pushing a git tag. Use two manual Actions per repo:

1. **Pre-release** — non-production build for testing (GitHub *Pre-release*, not latest, **no** Formula bump)
2. **Release** — production / latest (CLI also bumps Homebrew Formula)

```text
Human
  │
  ├─ 1) Pre-release (test)
  │     Assets Pre-release  →  core-v1.5.2-rc.1  (prerelease)
  │     CLI Pre-release     →  v1.5.0-rc.1       (prerelease)
  │     download + test manually
  │
  └─ 2) Release (production) when ready
        Assets Release      →  core-v1.5.2       (latest pack)
        CLI Release         →  v1.5.0            (latest CLI)
                            →  Formula PR auto-merge
```

## What updates what

| Manual workflow | Tag example | Latest? | Homebrew Formula? |
|-----------------|-------------|---------|-------------------|
| **Assets Pre-release** | `core-v1.5.2-rc.1` | No | No |
| **Assets Release** | `core-v1.5.2` | Yes (that release) | No |
| **CLI Pre-release** | `v1.5.0-rc.1` | No | No |
| **CLI Release** | `v1.5.0` | Yes | **Yes** (PR + auto-merge) |

`./VERSION` / `pack.yaml` stay on the **production** semver (`1.5.0` / `1.5.2`). Pre-release labels are only on the **git tag** and artifact names (`…-rc.1`).

## Prerequisites

1. Version bumps merged to `master`.
2. Write access to run workflows.
3. For **CLI Release** + Formula: secret `HOMEBREW_TAP_TOKEN` on `agent-harness-blueprint` (see [homebrew.md](homebrew.md)).

## Recommended order

1. **Assets Pre-release** → test pack install from that GitHub Release  
2. **Assets Release** → production pack  
3. **CLI Pre-release** → download archives / smoke outside Homebrew  
4. **CLI Release** → latest + Formula  

You can skip pre-release in an emergency, but prefer the two-step path for real versions.

---

## Assets Pre-release

[Actions → Assets Pre-release](https://github.com/krerapus/assets-blueprint/actions/workflows/assets-prerelease.yml)

| Input | Example |
|-------|---------|
| pack | `core` |
| confirm_version | `1.5.2` (must match `pack.yaml` + catalog) |
| pre_label | `rc.1` → tag `core-v1.5.2-rc.1` |
| dry_run | `true` to package only |

```bash
gh workflow run "Assets Pre-release" --repo krerapus/assets-blueprint \
  -f pack=core -f confirm_version=1.5.2 -f pre_label=rc.1 -f dry_run=false
```

## Assets Release (production)

[Actions → Assets Release](https://github.com/krerapus/assets-blueprint/actions/workflows/assets-release.yml)

| Input | Example |
|-------|---------|
| pack | `core` |
| confirm_version | `1.5.2` |
| tested_pre_label | `rc.1` (optional, notes only) |
| dry_run | `false` |

```bash
gh workflow run "Assets Release" --repo krerapus/assets-blueprint \
  -f pack=core -f confirm_version=1.5.2 -f tested_pre_label=rc.1 -f dry_run=false
```

---

## CLI Pre-release

[Actions → CLI Pre-release](https://github.com/krerapus/agent-harness-blueprint/actions/workflows/cli-prerelease.yml)

| Input | Example |
|-------|---------|
| confirm | `1.5.0` (= `./VERSION`) |
| pre_label | `rc.1` → tag `v1.5.0-rc.1` |
| dry_run | `false` |

Produces archives named `blueprint_1.5.0-rc.1_*.tar.gz`. Marked **Pre-release** on GitHub. **Does not** touch Homebrew.

```bash
gh workflow run "CLI Pre-release" --repo krerapus/agent-harness-blueprint \
  -f confirm=1.5.0 -f pre_label=rc.1 -f dry_run=false
```

### How to test a CLI pre-release

```bash
# download from the GitHub Pre-release page, then:
tar -xzf blueprint_1.5.0-rc.1_darwin_arm64.tar.gz
./blueprint/blueprint --version
# point at sibling or released packs as needed
```

## CLI Release (production / latest)

[Actions → CLI Release](https://github.com/krerapus/agent-harness-blueprint/actions/workflows/cli-release.yml)

| Input | Example |
|-------|---------|
| confirm | `1.5.0` |
| tested_pre_label | `rc.1` (optional) |
| bump_formula | `true` |
| dry_run | `false` |

Creates tag `v1.5.0`, marks the release **latest**, bumps Formula and auto-merges.

```bash
gh workflow run "CLI Release" --repo krerapus/agent-harness-blueprint \
  -f confirm=1.5.0 -f tested_pre_label=rc.1 -f bump_formula=true -f dry_run=false
```

### After production CLI + Formula

```bash
brew update
brew upgrade krerapus/blueprint/blueprint
blueprint --version
blueprint assets install core
blueprint assets doctor
```

## Dry run

Any workflow: `dry_run=true` → validate + package only (no tag / Release / Formula).

## Failure modes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| confirm mismatch | Typo vs `VERSION` / `pack.yaml` on `master` | Re-check files |
| Smoke fails (CLI) | assets checkout / pack broken | Inspect log; fix assets `master` |
| Formula job fails | Missing `HOMEBREW_TAP_TOKEN` | Add secret ([homebrew.md](homebrew.md)) |
| Auto-merge stuck | Tap branch protection | Merge Formula PR manually |
| Wanted “latest” but see Pre-release | Ran Pre-release only | Run **CLI Release** / **Assets Release** |

## Related docs

- [release.md](release.md) — versioning, artifact layout, local packaging
- [homebrew.md](homebrew.md) — tap install, secrets, manual Formula bump
- [distribution.md](distribution.md) — channels overview
- Assets: [release-workflow.md](https://github.com/krerapus/assets-blueprint/blob/master/docs/release-workflow.md)
