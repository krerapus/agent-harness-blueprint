# AGENTS.md

Package-source instructions for **shared-agent-blueprints**.

This repository is the **blueprint package**, not a product app. Edit shared sources under `harness/`, `prompts/`, `templates/`, and `blueprints/`. Do not keep consumer task-memory files or live `.cursor/` / `.claude/` / `.agents/` trees here.

## For adopting projects

Consumers use the CLI (never copy package-root docs as the product contract):

```bash
./blueprint init --target /path/to/repo
./blueprint install default --runtime all --target /path/to/repo
./blueprint install engineering --overlay gitlab --runtime all --target /path/to/repo
./blueprint sync --target /path/to/repo
./blueprint doctor --target /path/to/repo
```

`init` writes consumer `HARNESS.md`, appends a compact managed harness reference to the highest-priority root instruction file (`AGENTS.md` > `agents.md` > `CLAUDE.md` > `claude.md`), or creates `AGENTS.md` from the canonical template when none exist, and seeds memory skeletons. `install` projects `harness/` into `.cursor/`, `.claude/`, and/or `.agents/` per `--runtime`, and writes a managed `.gitignore` for `--skill-mode rebase` (whole runtime dirs) or `merge` (blueprint skills/commands/rules/templates only). `update` refreshes only `HARNESS.md`.

See [README.md](README.md), [CONTRIBUTING.md](CONTRIBUTING.md), and [docs/](docs/).

## Contributor harness (package source only)

Standards for contributors and agents working **on this package**. Unrelated to consumer/target harness installs under `harness/` / `blueprints/`.

| Playbook | Path |
|---|---|
| `/commit` (no JIRA) | [contributor/commands/commit.md](contributor/commands/commit.md) |
| `/pr` + release notes | [contributor/commands/pr.md](contributor/commands/pr.md) |
| Always-on standards | [contributor/rules/contributor-standards.mdc](contributor/rules/contributor-standards.mdc) |
| `skill-creator` | [harness/skills/skill-creator/SKILL.md](harness/skills/skill-creator/SKILL.md) |

`./blueprint install-contributor --runtime all` projects **only** those four into gitignored `.cursor` / `.claude` / `.agents` (see [CONTRIBUTING.md](CONTRIBUTING.md)). It does not install consumer skills (`context-recall`, `ponytail`, `generate-test-cases`, …). Those stay under `harness/skills/` for target `install`; see [docs/skills.md](docs/skills.md).

- Before adding or substantially rewriting a skill under `harness/skills/`, read and follow `skill-creator` and [docs/standards/skill-naming.md](docs/standards/skill-naming.md).

## Package edit order

1. This file / [CLAUDE.md](CLAUDE.md) for package orientation
2. `VERSION` for package semver (**only** place to bump the release number)
3. `harness/` skills, rules, commands relevant to the change
4. `templates/entrypoints/` when changing the consumer contract
5. `docs/` for adoption and compatibility notes

## Don't

- Commit consumer artifacts (`.cursor/`, `.claude/`, `.agents/`, `PLANNING.md`, etc.) into this package
- Point product repos at this package-root `AGENTS.md` as their runtime contract
- Treat optional overlays (e.g. GitLab) as universal defaults
- Project `contributor/` into consumer/target installs
