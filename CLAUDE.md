# CLAUDE.md

Package-source entrypoint for Claude-oriented agents working on **agent-harness-blueprint** (CLI + runtime).

## Read order

1. [docs/architecture-split.md](docs/architecture-split.md) — which repo owns the change
2. `AGENTS.md` (package orientation)
3. `contributor/` for package-contributor commit/PR/skill standards (not consumer harness)
4. `blueprint` / `lib/blueprint/` / `builtin/` for CLI work
5. For harness content: [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) packs (not legacy in-tree mirrors alone)
6. `docs/` for adoption and compatibility notes

## Contributor harness

Package-source only — does not install into target projects:

- Commits: `contributor/commands/commit.md` (conventional commits, **no JIRA**)
- PRs: `contributor/commands/pr.md` (GitHub `gh` + short **Release notes** for `CHANGELOG.md`)
- Skill: `skill-creator` from the `core` pack (legacy mirror may exist under `harness/skills/skill-creator/`). See [docs/standards/skill-naming.md](docs/standards/skill-naming.md) and [docs/skills.md](docs/skills.md).
- Optional local IDE projection: `./blueprint install-contributor --runtime all` (`/commit`, `/pr`, `skill-creator`)

## Do

- Prefer editing the owning repo (CLI here, packs in assets, Formula in homebrew)
- Prefer composition and blueprint overlays over one-off forks
- Keep offline bootstrap in `builtin/`; keep pack entrypoints in `assets-blueprint`
- Update docs when CLI or runtime projection behavior changes

## Don't

- Commit consumer memory files or `.cursor/` / `.claude/` / `.agents/` into this package
- Assume GitLab or stack-specific overlays apply to every install
- Promote every learning note into a shared rule without human review
- Treat `contributor/` as content for consumer blueprint installs
- Diverge pack content only in this repo’s legacy `harness/` / `templates/` trees
