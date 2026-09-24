# AGENTS.md

Package-source instructions for **agent-harness-blueprint** (CLI + runtime).

This repository is **not** the source of truth for harness content packs. Edit CLI/runtime here; edit skills/commands/rules/blueprints/templates/prompts in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint). Do not keep consumer task-memory files or live `.cursor/` / `.claude/` / `.agents/` trees here.

Ownership map: [docs/architecture-split.md](docs/architecture-split.md).

## For adopting projects

```bash
blueprint assets install core
blueprint init --target /path/to/repo
blueprint install default --runtime all --target /path/to/repo
blueprint sync --target /path/to/repo
blueprint doctor --target /path/to/repo
```

`init` writes consumer `HARNESS.md`, appends a managed harness reference to the highest-priority root instruction file, and seeds memory skeletons. `install` projects the resolved `core` pack into `.cursor/`, `.claude/`, and/or `.agents/` per `--runtime`.

See [README.md](README.md), [CONTRIBUTING.md](CONTRIBUTING.md), and [docs/](docs/).

## Contributor harness (package source only)

Standards for contributors working **on this CLI package**. Unrelated to consumer `install`.

| Playbook | Path |
|---|---|
| `/commit` (no JIRA) | [contributor/commands/commit.md](contributor/commands/commit.md) |
| `/pr` + release notes | [contributor/commands/pr.md](contributor/commands/pr.md) |
| Always-on standards | [contributor/rules/contributor-standards.mdc](contributor/rules/contributor-standards.mdc) |
| `skill-creator` | [`assets-blueprint` skill-creator](https://github.com/krerapus/assets-blueprint/tree/master/packs/core/harness/skills/skill-creator) |

`./blueprint install-contributor --runtime all` projects those into gitignored local runtimes (see [CONTRIBUTING.md](CONTRIBUTING.md)).

- Before adding or substantially rewriting a **consumer** skill, edit [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) and follow [skill-naming](https://github.com/krerapus/assets-blueprint/blob/master/docs/standards/skill-naming.md).

## Package edit order

1. This file / [CLAUDE.md](CLAUDE.md) for package orientation
2. [docs/architecture-split.md](docs/architecture-split.md) — confirm which repo owns the change
3. `VERSION` for CLI semver (**only** place to bump the CLI release number)
4. `blueprint` / `lib/blueprint/` / `builtin/` / `contributor/` for CLI work
5. For harness content: open `assets-blueprint` packs
6. `docs/` for CLI/adoption notes

## Don't

- Commit consumer artifacts (`.cursor/`, `.claude/`, `.agents/`, `PLANNING.md`, etc.) into this package
- Point product repos at this package-root `AGENTS.md` as their runtime contract
- Treat optional overlays (e.g. GitLab) as universal defaults
- Project `contributor/` into consumer/target installs
- Edit pack content in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint), not by recreating pack mirrors here
