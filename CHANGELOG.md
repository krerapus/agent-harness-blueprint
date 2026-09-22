# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Production CLI release pipeline: `scripts/package-release.sh`, `scripts/verify-release-archive.sh`, `scripts/bump-homebrew-formula.sh`, and rewritten `.github/workflows/cli-release.yml` (tag `v*.*.*` → test → package → GitHub Release → optional Homebrew PR)
- Docs: `docs/release.md`, `docs/distribution.md`, `docs/homebrew.md`
- Test: `tests/cli/package-release.sh` (artifact presence, checksum integrity, formula bump)
- Three-repo architecture: CLI (`agent-harness-blueprint`), assets (`assets-blueprint`), Homebrew tap (`homebrew-blueprint`) — see `docs/architecture-split.md`
- `blueprint assets {list,install,update,doctor}` Asset Manager with XDG cache (`~/.cache/blueprint/assets/`) and sibling `assets-blueprint` discovery
- `builtin/` offline bootstrap templates for Homebrew / airplane-mode `init`
- XDG config defaults under `~/.config/blueprint/`; `targets.json` prefers `~/.local/share/blueprint/`
- Consumer state pins `assets.core` alongside CLI `version`
- GitHub Actions: `cli-release.yml` (multi-arch archives + formula bump PR)
- `rm` is an alias for `del` (`./blueprint rm --force --target …`); interactive confirm accepts `rm` or `del`
- `--skill-mode rebase|merge` on `install` / `sync` / `update` — `rebase` gitignores entire `.cursor/` / `.claude/` / `.agents/`; `merge` gitignores only blueprint-projected skills, commands, rules, and templates so local runtime files stay commitable. Interactive install prompts after runtime; state stores `skill_mode`.
- `generate-test-cases` skill — Senior QA playbook that writes Testiny-importable CSV test suites for a software change (manual / opt-in); renamed from `testcase-generator` for action-first naming
- Skill naming standard (`docs/standards/skill-naming.md`) enforced via skill-creator + contributor gate; `doctor` validates package skill names
- `update-api-docs` skill — sync FastAPI `docs/api/openapi.yaml` and response examples with `app/routers/`
- Conflict overwrite UX: project-level conflict warnings, interactive TTY prompt to apply `*.blueprint-conflict` siblings, target-picker status, and `doctor` warnings for unresolved siblings
- Successful package writes remove stale `*.blueprint-conflict` siblings for that path (so `--force` / managed refresh clears doctor conflict noise)
- `blueprint clean` deletes reviewed `*.blueprint-backup.*` leftovers; Known projects prefixes Name with status icons (`✓` / `↓` / `!` / `*`)
- Package-only contributor harness under `contributor/` (commit without JIRA, GitHub PR + release notes, skill-creator gate)
- `blueprint install-contributor` for optional local IDE projection of contributor playbooks
- Community health files for open-source adoption (license, contributing guide, code of conduct, security policy, GitHub templates)

### Changed

- `del` removes only blueprint-projected skills/commands/rules/templates under `.cursor/` / `.claude/` / `.agents/`; custom user skills and other local runtime files are kept, and empty runtime dirs are pruned
- `--runtime codex` projects into `.agents/` (Codex reads skills from `.agents/skills/`); `--runtime all` includes Cursor, Claude, and Codex
- `generate-test-cases` always writes CSV under `.testiny/` (gitignored); no Downloads prompt
- `generate-test-cases` canonical Testiny header now matches the live import (`Section` instead of `Component`; fill-rule examples for `Active?`, `Priority`, `Sprint`)
- `--force` help text clarifies it overwrites unmanaged conflicting runtime files (not only `del`)
- Success summary prints an explicit Conflict count when conflicts occurred

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

[Unreleased]: https://github.com/Supparerk23/agent-harness-blueprint/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/Supparerk23/agent-harness-blueprint/releases/tag/v1.2.0
