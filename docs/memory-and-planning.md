# Memory and planning

`/start` keeps **planning**, **telemetry**, **rationale**, **draft learning**, and **safety memory** in separate files in the **adopting project** so agents do not treat chat logs as the system of record.

These files are **not** part of the CLI package. Templates live in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) under `packs/core/templates/memory/`, `packs/memories/`, and `packs/core/harness/skills/*/templates.md` (legacy mirrors may exist in this checkout).

## Consumer repo-root files

| File | Concept | Lifecycle |
|---|---|---|
| `PLANNING.md` | Checklist-backed goal and tasks; canonical “what remains” | Rewritten each `/start` |
| `RUN_LOG.md` | Batch **telemetry table**—scope, files, tests, status | Header reset on `/start`; append one row per delivery batch (~30-row cap) |
| `DECISIONS.md` | **Why** logs—timestamped outcomes with reasoning | Skeleton on `/start`; append-only afterward |
| `HOTCACHE.md` | Operational scratchpad: branch HEAD, hypotheses, immediate next steps | Replace frequently; avoid append sprawl |
| `LEARNING.md` | Tentative reflections awaiting human consolidation | Cleared `/start`; not authoritative |
| `ANTI-PATTERNS.md` | High-confidence hazards and safety bans | Defaults restored `/start`; grow only with review |
| `ARCHITECTURE.md` | Stable system topology (optional asset) | **Never auto-reset on `/start`** |

## Related skills

- **[context-recall](../harness/skills/context-recall/SKILL.md)** explains consolidation, read order, and why each layer exists.
- **[task-execution](../harness/skills/task-execution/SKILL.md)** governs checklist updates plus `DECISIONS` / `RUN_LOG` hygiene after each execution batch.

Together they turn “what happened?” into auditable artifacts instead of long chat scrollback.
