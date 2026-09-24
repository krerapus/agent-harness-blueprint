# Harness workflow

Step-by-step AI delivery loop once the blueprint is installed in a consumer repo.

## End-to-end

```mermaid
flowchart TD
  orient[1 Orient] --> start[2 /start]
  start --> plan[3 Plan]
  plan --> exec[4 Execute batch]
  exec --> update[5 Update memory]
  update --> more{More work?}
  more -->|yes| exec
  more -->|no| review[6 Review / commit / PR]
  review --> learn[7 Learn carefully]
```

## Steps

### 1. Orient

Read root `HARNESS.md` first for lifecycle and gates (template SoT: [`assets-blueprint` packs/core/templates/entrypoints/HARNESS.md](https://github.com/krerapus/assets-blueprint/blob/master/packs/core/templates/entrypoints/HARNESS.md); projected on `init`), then `AGENTS.md`, then local overrides, then rules/skills relevant to the task.

### 2. `/start`

Create a `feature/` or `hotfix/` branch and reset **task-scoped** memory templates from the active runtime skills:

- planning skill → `PLANNING.md`, `DECISIONS.md`, `RUN_LOG.md`
- memory skill → `HOTCACHE.md`, `ANTI-PATTERNS.md`, `LEARNING.md`

Do **not** reset `ARCHITECTURE.md` or installed skill trees.

See [quick-start.md](quick-start.md).

### 3. Plan

Keep goals and checklists truthful in `PLANNING.md` (`## Goal`, task list, `## Context for AI`).

### 4. Execute in batches

Implement a coherent slice of work. Prefer existing project patterns; confirm before destructive Git/DB/infra operations.

### 5. Update memory together

After each batch, update all of:

| File | Update |
|---|---|
| `PLANNING.md` | Checkboxes / `## ✅ Done` |
| `DECISIONS.md` | What changed and why |
| `RUN_LOG.md` | One telemetry row only |
| `HOTCACHE.md` | Replace stale operational scratch |

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant Agent as AI agent
  participant Mem as Memory files

  Dev->>Agent: Request batch
  Agent->>Agent: Implement
  Agent->>Mem: PLANNING checkboxes
  Agent->>Mem: DECISIONS append
  Agent->>Mem: RUN_LOG row
  Agent->>Mem: HOTCACHE refresh
  Agent->>Dev: Batch complete
```

### 6. Review / ship

Use `/review`, `/commit`, and forge commands (`/pr`, `/sync-dev`, …) when the overlay is installed.

### 7. Learn carefully

- Draft notes in `LEARNING.md` (not authoritative).
- Promote to skills/rules only after human review.
- Ban repeats in `ANTI-PATTERNS.md`.

## Memory map

```mermaid
flowchart TB
  subgraph resetOnStart [Reset on /start]
    P[PLANNING.md]
    D[DECISIONS.md]
    R[RUN_LOG.md]
    H[HOTCACHE.md]
    L[LEARNING.md]
    AP[ANTI-PATTERNS.md]
  end
  subgraph neverReset [Never auto-reset]
    AR[ARCHITECTURE.md]
    SK[Installed skills]
  end
```

Full layer semantics: [memory-and-planning.md](memory-and-planning.md).
