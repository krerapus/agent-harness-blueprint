# CLAUDE.md

Claude Code entrypoint for this repository.

## Read order

1. `HARNESS.md` — shared lifecycle, workflow, memory harness, Do/Don't
2. `AGENTS.md` — project-specific topics and overrides (source of local contract)
3. `AGENTS.local.md` / `CLAUDE.local.md` if present (project overrides)
4. `.claude/rules/` — always-on / path-scoped policy
5. Relevant `.claude/skills/*/SKILL.md` for the active task
6. Root memory files when executing planned work (`PLANNING.md`, `DECISIONS.md`, `RUN_LOG.md`, `HOTCACHE.md`, etc.)

## Notes

- Commands live under `.claude/commands/` after `./blueprint install … --runtime claude|all`.
- Do not fork shared playbooks here; sync from the blueprint package or use local overrides.
- Honor safety and memory rules in `HARNESS.md`.
