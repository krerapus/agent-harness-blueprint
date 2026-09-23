# Rules

Concepts for files under `packs/core/harness/rules/` in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) (projected into the consumer runtime `rules/` directory). Legacy mirror: `harness/rules/` in this checkout — see [architecture-split.md](architecture-split.md).

Rules are markdown files with YAML frontmatter:

- **`alwaysApply: true`** — broadly injected context; keep bullets tight so prompts stay usable.
- **`alwaysApply: false` + `globs`** — only attach when editing matching paths.

Shared defaults ship in the `core` pack. After install:

- Cursor: `.cursor/rules/*.mdc`
- Claude Code: `.claude/rules/*.md` (same content; Cursor-only frontmatter keys are ignored)
- Codex: `.agents/rules/*.md` (same markdown projection as Claude; Codex itself loads skills from `.agents/skills/`)

## `task-execution`

Thin shim that points agents to the **task-execution** skill: after each coded batch ensure `PLANNING.md` stays truthful, append `DECISIONS.md`, and rotate `RUN_LOG.md` telemetry with retention enforced.

## `safety-rules`

Operational red lines for agents—disruptive git/db/infra/credential/package edits default to **destructive** until a human confirms, with preference for previews/dry-runs (`git diff`, `terraform plan`, etc.).

Project-specific engineering etiquette belongs in local overrides (`*.local.mdc` / local rule files) or a team overlay—not in the shared default profile.
