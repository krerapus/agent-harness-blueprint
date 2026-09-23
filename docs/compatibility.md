# Compatibility layer

This repository is the **CLI + runtime**. Consuming projects receive a shared `AGENTS.md` contract, memory files, and optional tool runtimes via `blueprint`. Harness **content** is resolved from asset packs (see [architecture-split.md](architecture-split.md)).

## This repo — CLI paths (source of truth here)

| Path | Role |
|---|---|
| `./blueprint` | Init / install / update / sync / doctor / assets CLI |
| `lib/blueprint/` | Runtime modules (assets, harness projection, XDG, …) |
| `builtin/` | Offline bootstrap templates shipped with the CLI |
| `contributor/` | Package-only contributor playbooks |
| `VERSION` | **Single source of truth** for CLI semver |
| `manifest.yaml` | Package metadata (`version_file: VERSION`) |
| `docs/` | CLI, projection, release documentation |
| `tests/cli/` | CLI smoke + harness tests |
| `scripts/` | Release packaging and Formula bump helpers |

## Content packs — source of truth in `assets-blueprint`

| Pack path | Role |
|---|---|
| `packs/core/harness/` | Canonical shared commands, rules, skills, migrations |
| `packs/core/templates/` | Entrypoints, memory, PRD/ADR/review templates |
| `packs/core/blueprints/` | Profiles (`default`, `engineering`, `startup`) |
| `packs/prompts/` | Prompt library |
| `packs/memories/` | Root memory skeleton templates |
| `packs/examples/` | Consumer examples |
| `catalog.yaml` | Published pack versions and release asset names |

Resolution order for packs: `BLUEPRINT_ASSETS_ROOT` / sibling checkout → XDG cache → **legacy** in-tree `harness/` (etc.) in this repo.

## Legacy mirrors in this checkout (not SoT)

| Path | Status |
|---|---|
| `harness/`, `templates/`, `blueprints/`, `prompts/`, `examples/` | Transition fallback only — edit the matching pack in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) |

## Consumer-only paths (do not commit in this package)

| Path | Role |
|---|---|
| `.cursor/` | Cursor runtime projected from the resolved `core` pack |
| `.claude/` | Claude Code runtime |
| `.agents/` | Codex runtime (skills under `.agents/skills/`) |
| `PLANNING.md`, `DECISIONS.md`, `RUN_LOG.md` | Task planning / rationale / telemetry state |
| `HOTCACHE.md`, `LEARNING.md`, `ANTI-PATTERNS.md` | Short-lived / curated consumer memory |
| `ARCHITECTURE.md` | Optional stable design doc in the consumer |
| `.agent-blueprint.yaml` | Install state for that consumer |
| `.agent-blueprint/` | Session resume state (gitignored; not secrets) |

## How adopting projects work

1. Install the CLI (Homebrew or git checkout), then `blueprint assets install core`.
2. Run `blueprint init --target /path/to/repo` — writes `HARNESS.md`, injects a managed harness reference into `AGENTS.md` or existing `agents.md`, memory skeletons, and a managed `.gitignore` section. Does **not** modify existing `CLAUDE.md`.
3. Run `blueprint install <blueprint> --runtime all --target /path/to/repo` — projects pack `harness/` into `.cursor/`, `.claude/`, and/or `.agents/`. `--skill-mode rebase` (default) gitignores those whole runtime dirs; `--skill-mode merge` gitignores only the blueprint-projected skills, commands, rules, and templates.
4. Local overrides (`*.local.md`, `*.local.mdc`, `.agent-blueprint.local.yaml`) always win over managed files.
5. Memory state files are never overwritten by install/sync when they already exist in the target.
6. `blueprint update` checks target vs package `VERSION`, then refreshes `HARNESS.md` and managed runtime projections; it does not touch agent instruction files.
7. Optional: when `source` in `.agent-blueprint.yaml` is a git URL, install/sync use a cache under `$XDG_CACHE_HOME/blueprint/repos/`.

See [harness-ownership.md](harness-ownership.md) for precedence, markers, and recovery.

## Runtime projection

| Source (resolved core pack) | Cursor | Claude Code | Codex |
|---|---|---|---|
| `harness/commands/*.md` | `.cursor/commands/` | `.claude/commands/` | `.agents/commands/` |
| `harness/skills/*/` | `.cursor/skills/` | `.claude/skills/` | `.agents/skills/` |
| `harness/rules/*.mdc` | `.cursor/rules/*.mdc` | `.claude/rules/*.md` | `.agents/rules/*.md` |
| `templates/adr.md`, `review-checklist.md`, … | `.cursor/templates/` | `.claude/templates/` | `.agents/templates/` |

Workflow templates (`adr`, `prd`, `review-checklist`) live **inside the runtime** only — they are not copied to the project root `templates/` folder.
