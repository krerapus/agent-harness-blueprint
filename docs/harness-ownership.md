# Harness ownership and agent entrypoints

How `HARNESS.md` relates to root instruction files (`AGENTS.md` / `agents.md` / `CLAUDE.md` / `claude.md`) in adopting projects.

## Ownership model

| File or section | Owner | `init` may modify | `update` may modify |
|---|---|---|---|
| `HARNESS.md` | Blueprint Service | Yes | Yes |
| Managed runtime projections (`.cursor/` / `.claude/` / `.agents/`) | Blueprint Service | via `install` | Yes (when runtimes declared) |
| Managed `.gitignore` section | Blueprint Service | Yes | Yes (`rebase` ignores whole runtime dirs; `merge` lists projected skills/commands/rules/templates) |
| `.agent-blueprint.yaml` version fields | Blueprint Service | Yes | Yes |
| Managed block in selected instruction file | Blueprint Service | Yes | No |
| Content outside managed markers | User | No | No |
| Non-selected instruction files | User | No | No |

The Blueprint Service never overwrites a user-owned file completely unless it is **creating** a file that does not exist (`AGENTS.md` from the canonical template).

## Precedence (agent instruction files)

Case-sensitive detection at the **repository root only** (never recursive; ignore nested copies under `.cursor/`, `.claude/`, `docs/`, `examples/`, `templates/`, etc.):

1. `AGENTS.md`
2. `agents.md`
3. `CLAUDE.md`
4. `claude.md`
5. Create `AGENTS.md` from `templates/entrypoints/AGENTS.md`

Rules:

- Do not rename or merge instruction files
- If both `AGENTS.md` and `agents.md` exist, select `AGENTS.md`, leave `agents.md` untouched, emit a non-fatal warning
- If both `CLAUDE.md` and `claude.md` exist, select by the same precedence ladder (Claude files only win when no agents file exists)
- Never create `CLAUDE.md` / `claude.md` automatically
- `templates/entrypoints/CLAUDE.md` is the canonical Claude reference template for humans; it is not written by `init`

## Initialization (`blueprint init`)

1. Detect root instruction files by precedence (report Claude presence)
2. Create or safely install root `HARNESS.md` from `templates/entrypoints/HARNESS.md`
3. If no instruction file exists: copy the canonical `AGENTS.md` template as-is
4. On the selected instruction file: insert or reconcile the compact managed Blueprint block (markers below)
5. Write memory skeletons / managed `.gitignore` / state as before

Managed reference markers (stable):

```markdown
<!-- BLUEPRINT:HARNESS:START -->
## Shared Harness
…
<!-- BLUEPRINT:HARNESS:END -->
```

The compact block only **references** Blueprint-managed files (`HARNESS.md`, memory trackers). It does not duplicate full harness context. Only content between the markers is Blueprint-owned. Everything else is preserved byte-for-byte aside from the smallest patch needed to add or replace that block. Re-running `init` never duplicates the block.

### Existing `HARNESS.md`

- If Blueprint-managed (`<!-- managed-by: shared-agent-blueprints -->` present): refresh from template
- If unmanaged: leave unchanged and warn; use `--force` to backup (`HARNESS.md.blueprint-backup.<timestamp>`) then replace

### Malformed markers

If only `START` or only `END` is present (or duplicates), `init` leaves the instruction file unchanged and warns. Repair markers manually, then re-run `init`. The service does not guess how to splice a broken region.

## Update (`blueprint update`)

1. **Version check** — compare target `.agent-blueprint.yaml` `version` to package `./VERSION`. On mismatch, show a red notice (TUI prompts to confirm).
2. Refresh managed blueprint context:
   - root `HARNESS.md`
   - managed runtime projections (`.cursor/` / `.claude/` / `.agents/` skills, commands, rules, templates) when runtimes are declared
   - managed `.gitignore` section (`skill_mode` from state or `--skill-mode`)
   - stamp package version into state + targets registry

### Skill / rule renames

`update` (and install/sync projections) read [`harness/migrations/renames.log`](../harness/migrations/renames.log) and **remove obsolete paths** under each installed runtime before writing current names. Example: `memory-system-protocol` → `context-recall`, `planning-execution-tracking` → `task-execution`.

On `update` only, package skills and rules are **full-refreshed** (destination skill dirs wiped, then copied from the package) so stale files inside a renamed or rebuilt skill do not linger. Append a new row to `renames.log` whenever you rename a managed skill or rule — keep historical rows.

Does **not** modify:

- `AGENTS.md` / `agents.md` / `CLAUDE.md` / `claude.md`

even when the managed reference block is missing or outdated. Reconcile the reference block with `blueprint init` (or a future dedicated repair command), not `update`.

`sync` remains available to re-apply the installed blueprint without the version-gated update UX (still applies rename cleanup, but uses preserve-local copy semantics for skill files).

## Recovery

| Situation | Action |
|---|---|
| Missing harness reference | `blueprint init --target .` |
| Malformed markers | Fix or remove the partial markers by hand, then `init` |
| Unmanaged `HARNESS.md` | Migrate content, then `init --force` / `update --force` to backup + replace |
| Need runtime projections | `blueprint sync` (still does not rewrite agent instruction files) |

Filesystem remains the source of truth; `.agent-blueprint.yaml` records harness/agents metadata for humans and tooling but is not required for detection.
