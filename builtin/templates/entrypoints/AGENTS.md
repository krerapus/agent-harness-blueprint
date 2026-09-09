# AGENTS.md

Shared agent contract for this repository. Every coding agent (Cursor, Claude Code, Copilot, or others) should follow this file.

This project uses **shared-agent-blueprints**. Shared lifecycle, quality gates, and workflow rules live in root [`HARNESS.md`](./HARNESS.md). Keep **project-specific** roles, conventions, and overrides in this file (and local overrides).

## Required setup

Before starting product work, install the harness:

```bash
# 1) Shared harness + memory skeletons (no tool runtime yet)
/path/to/agent-harness-blueprint/blueprint init --target .

# 2) Project commands/rules/skills into tool runtimes
/path/to/agent-harness-blueprint/blueprint install default --runtime all --target .
# engineering + GitLab MR playbooks:
# /path/to/agent-harness-blueprint/blueprint install engineering --overlay gitlab --runtime all --target .
```

`--runtime` may be `cursor`, `claude`, `codex`, or `all`. Omit it to pick interactively. Refresh shared harness later with `./blueprint update --target .`. Re-sync runtimes with `./blueprint sync --target .`.

## Project topics

Use this file for repository-specific guidance, for example:

- Product / domain context
- Stack conventions and non-obvious patterns
- Service boundaries and ownership
- Links to architecture docs (`ARCHITECTURE.md`, ADRs)

Do not duplicate the shared harness here — read [`HARNESS.md`](./HARNESS.md) for overview, runtime layout, AI workflow, memory files, and Do/Don't.

## Overrides (always win)

- `AGENTS.local.md`
- `CLAUDE.local.md`
- `.agent-blueprint.local.yaml`
- `*.local.mdc` / local rule files under the active runtime

Shared installs must not overwrite local state or unmanaged local files (conflict siblings use `*.blueprint-conflict`).
