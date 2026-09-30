# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Landing menu update check: yellow `UPDATE AVAILABLE` panel when a newer CLI release and/or `core` (skills) pack is available (cached, fail-open offline)
- `scripts/render-release-notes.sh` — compact GitHub Release notes from CHANGELOG `### Highlights` (wired into CLI Release / Pre-release)

## [1.5.0] - 2026-09-29

### Highlights

- `install` now bootstraps harness + runtimes (former `init` removed)
- `blueprint auth` for one-time GitHub/GitLab + git identity
- `blueprint assets` for independently versioned packs
- `switch` profile + `product` profile (replaces `startup`)
- Pre-release → production workflow; Formula auto-bump on CLI Release

### Added

- `blueprint auth` — one-time GitHub/GitLab login (wraps `gh`/`glab`) plus `auth git` identity under `~/.config/blueprint/credentials/git`; `install` applies local `git config`; `doctor` reports auth status
- `blueprint switch <profile>` (+ TUI menu **6) switch**) to change install profile while keeping runtimes/skill-mode from state
- Contributor skill `update-changelog` (via `install-contributor`) — Keep a Changelog workflow for package repos
- Docs: `docs/profiles.md`, [docs/release-workflow.md](docs/release-workflow.md), [docs/release.md](docs/release.md), [docs/homebrew.md](docs/homebrew.md)
- Human-triggered **CLI Pre-release** then **CLI Release** (production / latest + Formula auto-merge)
- Production packaging: `scripts/package-release.sh`, `scripts/verify-release-archive.sh`, `scripts/bump-homebrew-formula.sh`, `tests/cli/package-release.sh`
- Three-repo architecture: CLI, assets (`assets-blueprint`), Homebrew tap — see `docs/architecture-split.md`
- `blueprint assets {list,install,update,doctor}` with XDG cache and sibling `assets-blueprint` discovery
- `builtin/` offline bootstrap templates; XDG config under `~/.config/blueprint/`
- Consumer state pins `assets.core` alongside CLI `version`
- `--skill-mode rebase|merge` on `install` / `sync` / `update`
- Skills: `generate-test-cases`, `update-api-docs`; skill naming standard + `doctor` name checks
- Conflict overwrite UX, `blueprint clean`, Known-projects status icons
- Package-only contributor harness (`contributor/`) and `blueprint install-contributor`
- Community health files (license, contributing, code of conduct, security, GitHub templates)
- `rm` alias for `del`

### Changed

- Merged former `init` into `install` (one-step harness + runtime bootstrap); `blueprint init` errors with a pointer to `install`
- `install-contributor` only for blueprint package checkouts; requires prior `install`
- Profile rename: `startup` → **`product`** (`startup` kept as legacy alias)
- Removed in-tree pack mirrors; packs resolve via assets checkout / cache only
- Docs SoT cleanup: merged `distribution.md` into `release.md`; `SECURITY.md` → `krerapus` + 1.5.x
- Dropped redundant `builtin/VERSION`; packaging allows `VERSION-rc.N` artifact names while `./VERSION` stays on the base semver
- `del` keeps non-blueprint runtime files; `--runtime codex` → `.agents/`; `--runtime all` includes Codex
- `generate-test-cases` writes under `.testiny/`; Testiny header uses `Section`
- Releases are `workflow_dispatch` only; CLI Release auto-merges Homebrew Formula when `bump_formula=true`

## [1.2.0] - 2026-08-03

### Added

- `blueprint` CLI with interactive menu and commands: `init`, `install`, `update`, `sync`, `del`, `doctor`
- Blueprint profiles: `default`, `engineering`, `startup`
- Optional GitLab overlay (`--overlay gitlab`)
- Multi-runtime projection (`--runtime cursor|claude|all`)
- Managed consumer contract via `HARNESS.md` and harness reference injection into `AGENTS.md` / `agents.md`
- Memory skeletons and preserve-local sync behavior
- Remote `source` URL cache under `$XDG_CACHE_HOME/blueprint/repos/`
- Package docs under `docs/` and example consumer under `examples/consumer/`
- CLI smoke and harness ownership tests under `tests/cli/`

### Changed

- Harness skills, workflow, and TUI refinements for install/sync flows

[Unreleased]: https://github.com/krerapus/agent-harness-blueprint/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/krerapus/agent-harness-blueprint/releases/tag/v1.5.0
[1.2.0]: https://github.com/krerapus/agent-harness-blueprint/releases/tag/v1.2.0
