# Contributing

Thanks for helping improve **agent-harness-blueprint**. This package is the **CLI + runtime**. Pack content and the Homebrew Formula live in sibling repos — see [docs/architecture-split.md](docs/architecture-split.md).

Please read the [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

Sibling repos: [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) (packs) · [`homebrew-blueprint`](https://github.com/krerapus/homebrew-blueprint) (Formula).

## Development setup

Requirements: Bash, Git, and a Unix-like shell (macOS / Linux).

```bash
git clone https://github.com/krerapus/agent-harness-blueprint.git
cd agent-harness-blueprint

# Optional: put the CLI on PATH
ln -s "$(pwd)/blueprint" /usr/local/bin/blueprint

# Packs (required for realistic install/doctor against a clean tree)
git clone https://github.com/krerapus/assets-blueprint.git ../assets-blueprint
# or: export BLUEPRINT_ASSETS_ROOT=/path/to/assets-blueprint
./blueprint assets install core

./blueprint doctor
```

Package orientation:

1. [docs/architecture-split.md](docs/architecture-split.md) — **which repo to edit**
2. [AGENTS.md](AGENTS.md) / [CLAUDE.md](CLAUDE.md)
3. `blueprint`, `lib/blueprint/`, `builtin/`, `contributor/`
4. [docs/](docs/) for adoption and release notes
5. [README.md](README.md#where-content-lives)

Bump the CLI semver only in [`VERSION`](VERSION).

## How this repo works

This repository ships the `blueprint` CLI, builtin bootstrap, contributor tooling, and release packaging. It loads harness content from asset packs (or a legacy in-tree fallback), then projects into consumer `.cursor/` / `.claude/` / `.agents/` trees.

| Change type | Repo |
|-------------|------|
| CLI / assets manager / projection | **this repo** |
| Skills, rules, commands, blueprints, templates, prompts, examples | **assets-blueprint** |
| Homebrew Formula | **homebrew-blueprint** |

See [README.md](README.md#how-it-works) and [docs/architecture-split.md](docs/architecture-split.md).

## Branch naming

| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/<short-slug>` | `feature/sync-resume` |
| Bug fix | `fix/<short-slug>` or `hotfix/<short-slug>` | `fix/add-command` |
| Docs | `docs/<short-slug>` | `docs/contributing` |
| Chore | `chore/<short-slug>` | `chore/gitignore` |

Use lowercase kebab-case slugs. Prefer short, descriptive names over ticket-only names when no tracker ID exists.

## Commit convention

Prefer concise, imperative conventional subjects (what / why), for example:

- `fix(cli): add command resume path`
- `docs: clarify install --runtime selector`
- `feat(doctor): add check for remote cache`

Format: `type(scope): description` with types `feat|fix|refactor|test|docs|chore`. **No JIRA number** in commit messages for this package.

Agent playbook: [contributor/commands/commit.md](contributor/commands/commit.md).

Keep commits focused. Do not commit consumer artifacts (`.cursor/`, `.claude/`, `PLANNING.md`, `targets.json`, etc.).

## Pull request process

1. Fork (or branch from the default branch) and make a focused change.
2. Run the smoke and harness tests (see [Testing](#testing--review-expectations)).
3. Open a PR using the template. Describe **why** the change exists and how you verified it.
4. Include short **Release notes** (1–3 Keep a Changelog bullets) suitable for `CHANGELOG.md` `[Unreleased]`.
5. Link related issues when applicable.
6. Keep the PR scoped — pack content PRs belong in `assets-blueprint`; Formula-only PRs belong in `homebrew-blueprint`.
7. Address review feedback with follow-up commits (prefer not to force-push unless asked).

Agent playbook: [contributor/commands/pr.md](contributor/commands/pr.md).

Maintainers may ask for docs updates when CLI or projection behavior changes.

## How to update source

1. **CLI / modules:** edit `blueprint` and `lib/blueprint/`; keep helpers small and composable.
2. **Consumer harness content:** edit packs in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint). Do not treat in-tree `harness/`, `templates/`, `blueprints/`, or `prompts/` as the source of truth (legacy fallback only).
3. **Offline bootstrap:** change entrypoints/memory under `builtin/` when the change must ship inside the CLI archive without packs.
4. **Contributor-only playbooks:** edit `contributor/` (not projected by consumer `install`).
5. **Semver:** bump only [`VERSION`](VERSION) for CLI releases; update [CHANGELOG.md](CHANGELOG.md). Pack versions bump in `assets-blueprint`.
6. **Verify:** `./tests/cli/smoke.sh`, `./tests/cli/harness.sh`, `./blueprint doctor`, `./blueprint assets doctor --offline`. For install/sync/init/del changes, use `--dry-run` then a throwaway `--target`.
7. **Release:** follow [docs/release.md](docs/release.md). Formula bumps land on [`homebrew-blueprint`](https://github.com/krerapus/homebrew-blueprint) via [docs/homebrew.md](docs/homebrew.md).

## Contributor harness (local slash commands)

Package-contributor standards live under [`contributor/`](contributor/) and are **not** projected by consumer `blueprint install`.

To enable local `/commit`, `/pr`, and `skill-creator` in Cursor/Claude while working on this package:

```bash
./blueprint install-contributor --runtime all
```

This writes gitignored `.cursor/` / `.claude/` / `.agents/` plus `.agent-blueprint.local.yaml` (`profile: package-contributor`). Do not commit those artifacts. `./blueprint doctor` allows them when the local marker is present.

`install-contributor` projects **only** this set (not the consumer skill pack):

| Kind | Name | Source |
|---|---|---|
| Command | `/commit` | [`contributor/commands/commit.md`](contributor/commands/commit.md) |
| Command | `/pr` | [`contributor/commands/pr.md`](contributor/commands/pr.md) |
| Rule | contributor-standards | [`contributor/rules/contributor-standards.mdc`](contributor/rules/contributor-standards.mdc) |
| Skill | `skill-creator` | Prefer assets `packs/core/harness/skills/skill-creator/` (legacy: [`harness/skills/skill-creator/SKILL.md`](harness/skills/skill-creator/SKILL.md)) |

Before adding or substantially rewriting a consumer skill, use `/skill-creator` in the **assets** repo and follow the [Skill naming standard](docs/standards/skill-naming.md). Inventory: [docs/skills.md](docs/skills.md).

## Coding style

- **CLI / Bash:** Match existing patterns in `blueprint` and `lib/blueprint/`. Prefer small, composable helpers over large one-off scripts.
- **Harness content:** Edit [`assets-blueprint`](https://github.com/krerapus/assets-blueprint); prefer composition and blueprint overlays over forking entire profiles.
- **Docs:** Keep root docs concise; put deep detail under `docs/`. State which repo owns the content. Update docs when user-facing CLI behavior changes.
- **Consumer contract:** Entrypoint templates live in the `core` pack (plus `builtin/` for offline). Do not treat package-root `AGENTS.md` as a product-app contract.
- **Do not** commit live `.cursor/` / `.claude/` / `.agents/` trees or task-memory files into this package.

## Testing / review expectations

Before requesting review:

```bash
./tests/cli/smoke.sh
./tests/cli/harness.sh
./blueprint doctor
./blueprint assets doctor --offline
```

If you change install/sync/init/del behavior, exercise a temporary consumer target with `--dry-run` first, then a real throwaway directory.

Review bar:

- Clarity and safety over cleverness
- No silent overwrites of consumer memory or agent instruction files
- Backward-compatible defaults unless the PR explicitly documents a breaking change
- Tests and docs updated when behavior changes
- Kind, specific feedback — suggest alternatives when requesting changes

Questions are welcome via GitHub Issues (label `question`).

## Security

Do not open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).
