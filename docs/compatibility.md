# Compatibility layer

This repository is the **shared blueprint package**. Consuming projects receive a shared `AGENTS.md` contract, memory files, and optional tool runtimes via `./blueprint`.

## Package paths (source of truth)

| Path | Role |
|---|---|
| `harness/` | Canonical shared commands, rules, skills |
| `prompts/` | Prompt library |
| `templates/entrypoints/` | Consumer `HARNESS.md` + `AGENTS.md` / `CLAUDE.md` templates |
| `templates/` | Memory + PRD/ADR/review templates |
| `blueprints/` | Composable profiles (`default`, `engineering`, `startup`) |
| `docs/` | Package documentation |
| `VERSION` | **Single source of truth** for package semver |
| `manifest.yaml` | Package metadata (`version_file: VERSION`; no duplicated semver) |
| `./blueprint` | Init / install / update / sync / doctor CLI (`lib/blueprint/` UX modules) |
| `AGENTS.md` / `CLAUDE.md` | Package-source orientation only |
| `tests/cli/` | CLI smoke + harness tests |

## Consumer-only paths (do not commit in this package)

| Path | Role |
|---|---|
| `.cursor/` | Cursor runtime projected from `harness/` |
| `.claude/` | Claude Code runtime projected from `harness/` |
| `.agents/` | Codex runtime projected from `harness/` (skills live in `.agents/skills/`) |
| `PLANNING.md`, `DECISIONS.md`, `RUN_LOG.md` | Task planning / rationale / telemetry state |
| `HOTCACHE.md`, `LEARNING.md`, `ANTI-PATTERNS.md` | Short-lived / curated consumer memory |
| `ARCHITECTURE.md` | Optional stable design doc in the consumer |
| `.agent-blueprint.yaml` | Install state for that consumer |
| `.agent-blueprint/` | Session resume state (gitignored; not secrets) |

## How adopting projects work

1. Run `./blueprint init --target /path/to/repo` — writes `HARNESS.md`, injects a managed harness reference into `AGENTS.md` or existing `agents.md` (creates `AGENTS.md` when neither exists), memory skeletons, and a managed `.gitignore` section from `templates/gitignore`. Does **not** modify existing `CLAUDE.md`.
2. Run `./blueprint install <blueprint> --runtime all --target /path/to/repo` — projects `harness/` into `.cursor/`, `.claude/`, and/or `.agents/`. `--skill-mode rebase` (default) gitignores those whole runtime dirs; `--skill-mode merge` gitignores only the blueprint-projected skills, commands, rules, and templates.
3. Local overrides (`*.local.md`, `*.local.mdc`, `.agent-blueprint.local.yaml`) always win over managed files.
4. Memory state files are never overwritten by install/sync when they already exist in the target.
5. `./blueprint update` checks target vs package `VERSION`, then refreshes `HARNESS.md` and managed runtime projections; it does not touch agent instruction files.
6. Optional: symlink `blueprint` onto PATH. When `source` in `.agent-blueprint.yaml` is a git URL, install/sync use a cache under `$XDG_CACHE_HOME/blueprint/repos/`.

See [harness-ownership.md](harness-ownership.md) for precedence, markers, and recovery.

## Runtime projection

| Source | Cursor | Claude Code | Codex |
|---|---|---|---|
| `harness/commands/*.md` | `.cursor/commands/` | `.claude/commands/` | `.agents/commands/` |
| `harness/skills/*/` | `.cursor/skills/` | `.claude/skills/` | `.agents/skills/` |
| `harness/rules/*.mdc` | `.cursor/rules/*.mdc` | `.claude/rules/*.md` | `.agents/rules/*.md` |
| `templates/adr.md`, `review-checklist.md`, … | `.cursor/templates/` | `.claude/templates/` | `.agents/templates/` |

Workflow templates (`adr`, `prd`, `review-checklist`) live **inside the runtime** only — they are not copied to the project root `templates/` folder.
