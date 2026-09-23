# Quick start (`/start` ritual)

`/start` aligns planning, telemetry, and scratchpads in the **consuming project** before heavy implementation. Canonical playbook: [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) `packs/core/harness/commands/start.md` (legacy mirror: [harness/commands/start.md](../harness/commands/start.md)).

Canonical pack sources: `packs/core/harness/` and `packs/core/templates/`. After `blueprint assets install core` and `blueprint install --runtime …`, the same assets appear under the consumer's `.cursor/`, `.claude/`, and/or `.agents/`.

## Steps (in the adopting project)

1. **Pick a branch** — `feature/[ticket-or-slug]` or `hotfix/[ticket-or-slug]`. Confirm the full name (e.g. `feature/ABC-1234`).
2. **Create & switch**:

   ```bash
   git checkout -b feature/ABC-1234
   ```

3. **Reset task-scoped templates exactly** (copy bodies verbatim; do not delete files). Use the active runtime skill path:
   - `<runtime>/skills/task-execution/templates.md` → `PLANNING.md`, `DECISIONS.md`, `RUN_LOG.md`
   - `<runtime>/skills/context-recall/templates.md` → `HOTCACHE.md`, `ANTI-PATTERNS.md`, `LEARNING.md`
   - Runtime root is `.cursor`, `.claude`, or `.agents` depending on the agent
   - Pack equivalents: `packs/core/harness/skills/*/templates.md` and `packs/core/templates/memory/`
   - Never reset items listed under **Do not reset** inside the memory templates (for example installed skill trees, `ARCHITECTURE.md`).
4. **Prime `HOTCACHE.md`** with branch name, today’s UTC date, and a one-line focus statement.
5. Optionally pre-fill `PLANNING.md` sections `## Goal` / `## Context for AI` from the user’s summary.

## Safety rails baked into the command

- Do not create work directly on `main`, `master`, or `develop` without explicit confirmation.
- Never pair `/start` with destructive git (`push --force`, `reset --hard`, etc.).
- Replace template **content** only—keep the files in the adopting project's version control.

When finished, announce `✅ Started : [branch name]` so humans know the ritual completed.

See [memory-and-planning.md](memory-and-planning.md) for how the reset files behave afterward.

## Consumer repo-root files after `/start` (counts)

Templates from two skills recreate **six** Markdown trackers at the **adopting** repository root—these files are not part of the CLI package:

| When | Repo-root trackers | Count |
| --- | --- | --- |
| After **`/start`** | `PLANNING.md`, `DECISIONS.md`, `RUN_LOG.md`, `HOTCACHE.md`, `ANTI-PATTERNS.md`, `LEARNING.md` | **6** |
| Optional stable layer | Add `ARCHITECTURE.md` when you maintain system design; **`/start` must not reset it** (see installed `context-recall` skill templates **Do not reset**). | **up to 7** |
| During **delivery batches** | Same files updated in place (checkboxes in `PLANNING`, rows in `DECISIONS`/`RUN_LOG`, scratch edits in `HOTCACHE`). | — |

## Bundled skills (under `packs/core/harness/skills/`)

| Folder | Typical trigger |
| --- | --- |
| `context-recall/` | Layered memory read/update; `/start` templates for `HOTCACHE`, `ANTI-PATTERNS`, `LEARNING`. |
| `task-execution/` | Tasks from `PLANNING`; `/start` templates for `PLANNING`, `DECISIONS`, `RUN_LOG`. |
| `refactor-code/` | Refactors; human applies risky edits (`disable-model-invocation`). Pair with `ponytail`. |
| `docs-style/` | README/doc IA refactors (`disable-model-invocation`). |
| `skill-creator/` | Creating or iterating new skills under the active runtime `skills/<name>/`. |
| `i-have-adhd/` | ADHD-friendly output style (`/i-have-adhd`). |
| `ponytail/` (+ review/audit/debt/gain/help) | Minimal-code / YAGNI bias (`/ponytail`). |
| `generate-test-cases/` | Testiny-importable CSV under `.testiny/testcases-<JIRA>.csv`. |
| `update-api-docs/` | Sync FastAPI OpenAPI YAML and response examples. |

See [skills.md](skills.md) for concepts.
