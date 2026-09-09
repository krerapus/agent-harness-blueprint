# HARNESS.md

Shared execution harness for all coding agents in this repository.

This file is managed by **shared-agent-blueprints**. Project-specific agent roles and instructions stay in `AGENTS.md` / `agents.md` (and optional local overrides). When instructions conflict, follow the precedence in this file.

<!-- managed-by: shared-agent-blueprints -->

## Precedence

1. Explicit user instructions for the current task
2. Local overrides (`AGENTS.local.md`, `CLAUDE.local.md`, `.agent-blueprint.local.yaml`, `*.local.mdc`)
3. This `HARNESS.md` (lifecycle, safety, quality gates, completion)
4. Project agent contract (`AGENTS.md` or `agents.md`) outside the managed harness reference
5. Runtime rules / skills under `.cursor/`, `.claude/`, or `.agents/`

## Harness overview

| Layer | Role |
|---|---|
| **Commands** | Named playbooks (`/start`, `/review`, `/commit`, forge overlays) |
| **Rules** | Always-on or path-scoped policy |
| **Skills** | Curated multi-step procedures (`SKILL.md` + optional templates) |
| **Memory files** | Cross-session planning, decisions, telemetry, scratch state |

Canonical sources live in the blueprint package under `harness/`. Consuming repos hold **projections** into tool-specific runtimes plus this root harness file.

## Runtime layout

After `install --runtime …`:

| Tool | Runtime root | Commands | Rules | Skills | Templates |
|---|---|---|---|---|---|
| Cursor | `.cursor/` | `.cursor/commands/` | `.cursor/rules/` | `.cursor/skills/` | `.cursor/templates/` |
| Claude Code | `.claude/` | `.claude/commands/` | `.claude/rules/` | `.claude/skills/` | `.claude/templates/` |
| Codex | `.agents/` | `.agents/commands/` | `.agents/rules/` | `.agents/skills/` | `.agents/templates/` |

Workflow templates (`adr`, `prd`, `review-checklist`) stay under the runtime — they are not copied to a project-root `templates/` folder.

Agents that only read root markdown still get the project contract from `AGENTS.md` / `agents.md`. Claude Code may also load `CLAUDE.md` (user-owned thin pointer).

Prefer updating the blueprint package, then `./blueprint update` (harness) and `./blueprint sync` (runtimes) — do not fork shared playbooks in-place unless you intend a local override.

## AI workflow

1. **Orient** — Read this file (including **Skill use cases**), then the project agent contract (`AGENTS.md` / `agents.md`), then `AGENTS.local.md` / `CLAUDE.local.md` if present, then relevant rules/skills for the task.
2. **Start a task** — Run `/start` (or follow that playbook): create a feature/hotfix branch and reset task-scoped memory templates.
3. **Plan** — Keep goals and checklists truthful in `PLANNING.md`.
4. **Execute in batches** — Implement, then update memory together:
   - `PLANNING.md` — checkboxes / done list
   - `DECISIONS.md` — what changed and why
   - `RUN_LOG.md` — short telemetry only
   - `HOTCACHE.md` — replace stale operational scratch
5. **Review / ship** — Use `/review`, `/commit`, and forge commands (`/pr`, etc.) when installed.
6. **Learn carefully** — Draft notes in `LEARNING.md`; promote to skills/rules only after human review. Ban repeats in `ANTI-PATTERNS.md`.

## Skill use cases

Skills live under the active runtime (`<runtime>/skills/`). Prefer matching a skill to the task; do not dump full skill text into this file.

**Policy:** if a skill fits, enable it or ask once, then keep it for the session. Do not silently enable opt-in skills when the user may want normal prose.

| Situation | Skill | Policy |
|---|---|---|
| Multi-step fix, setup, or “what do I do next?” | `/i-have-adhd` | **Ask once:** “Enable ADHD-friendly output for this session?” Opt-in only (`disable-model-invocation`). Off: `stop adhd mode` / `normal mode`. |
| Implement, fix, refactor, or choose a library | `/ponytail` | **Prefer on coding tasks** (or ask once). Levels: `lite` \| `full` (default) \| `ultra`. Off: `stop ponytail` / `normal mode`. |
| Diff feels bloated / over-engineered | `/ponytail-review` | **Suggest after implementation** before ship. |
| Whole-repo complexity hunt | `/ponytail-audit` | **Ask before** a large audit. |
| Deferred `ponytail:` shortcuts piling up | `/ponytail-debt` | Suggest when harvesting “later” notes. |
| Need ponytail command cheat sheet | `/ponytail-help` | On request. |
| Executing / updating `PLANNING.md` batches | `task-execution` | Use when work must leave PLANNING / DECISIONS / RUN_LOG breadcrumbs. |
| Reading or updating memory layers | `context-recall` | Use when memory files drive the session. |
| Docs IA / README split | `docs-style` | Opt-in / explicit invoke. |
| Creating or tuning a skill | `skill-creator` | Opt-in / explicit invoke. |
| Generate Testiny QA CSV for a change | `generate-test-cases` | Opt-in / explicit invoke (`disable-model-invocation`). Writes `.testiny/testcases-<JIRA>.csv`. |
| Sync OpenAPI YAML / API response examples with routers | `update-api-docs` | Prefer when `app/routers/` or `docs/api/openapi.yaml` changes; or when asked to refresh swagger/OpenAPI/examples. |
| Simplify / dedupe / modularity refactor | `refactor-code` + `/ponytail` | **Required pairing:** when `/refactor-code` (or refactor-code) is invoked, **must** also enable `/ponytail` (default `full`). Applies to any programming language. Do not run refactor-code alone. Prefer `/ponytail-review` on the resulting diff. |

Pairing: `/ponytail` shrinks what you build; `/i-have-adhd` shapes how replies are written. Suggest both when a coding task is also multi-step and easy to lose track of — still ask before enabling ADHD mode.

**Required:** `/refactor-code` ⇒ `/ponytail` (always). If the user invokes refactor-code without ponytail, enable ponytail for the session (or ask once, then enable) before continuing the refactor.

## Memory harness

| File | Role |
|---|---|
| `PLANNING.md` | Goals and task checklists |
| `DECISIONS.md` | Why logs |
| `RUN_LOG.md` | Execution telemetry only |
| `HOTCACHE.md` | Short-lived operational state |
| `LEARNING.md` | Candidate insights |
| `ANTI-PATTERNS.md` | High-confidence safety bans |
| `ARCHITECTURE.md` | Stable design (never auto-reset) |

Install/sync never overwrites these once they exist. `/start` may reset **content** of task-scoped files from skill templates; it must not reset `ARCHITECTURE.md` or installed skill trees.

## Execution lifecycle

1. **Orient** — Read this file (including **Skill use cases**), then the project agent contract, then local overrides and relevant rules/skills.
2. **Plan** — Keep goals and checklists truthful before large or multi-step work.
3. **Implement** — Prefer existing project patterns; make the smallest change that satisfies the task.
4. **Verify** — Run the checks this repo expects (lint, tests, typecheck, smoke) for the change surface.
5. **Review** — Self-review against quality gates below before claiming done.
6. **Complete** — Only mark work complete when completion criteria are met.

## Planning rules

- Prefer a short written plan for multi-file or behavioral changes.
- If the repo uses `PLANNING.md`, keep checklists accurate (`[x]` / `[ ]`) and update `## ✅ Done` when used.
- Do not expand scope beyond the requested outcome without confirmation.

## Implementation workflow

- Read related code before editing.
- Keep handlers/routes thin when the project uses that pattern; put business logic in services.
- Avoid drive-by refactors and unrelated file churn.
- Match existing naming, layout, and formatting conventions.
- After each coherent batch, update planning / decisions / run-log together when those memory files are in use.

## Quality gates

- Changes must be consistent with existing architecture and style.
- Public contracts (API, CLI, docs consumers rely on) stay backward compatible unless the task explicitly changes them.
- No secrets, credentials, or environment-impacting defaults committed.
- Managed blueprint markers and user-owned content outside those markers must both be respected.

## Review requirements

Before finishing:

- Diff is scoped to the task
- Error paths and edge cases are handled
- User-facing messages are clear and safe
- Docs that describe changed behavior are updated when required

## Testing requirements

- Add or update tests for changed behavior when the repo has a test suite.
- Prefer focused unit tests plus targeted integration/smoke coverage for CLI or external boundaries.
- Do not claim tests passed unless they were run (or explain why they could not be).

## Logging rules

- Log enough context to debug failures; keep user-facing errors concise.
- Do not log secrets.
- When using memory telemetry (`RUN_LOG.md`), keep rows short and factual — no reflections.

## Safety constraints

- Never run destructive, irreversible, or environment-impacting commands without explicit confirmation.
- Prefer dry-run, preview, backup, and reversible strategies.
- Do not rewrite git history, force-push shared branches, or mass-delete without an explicit request.
- Do not apply production schema migrations or production deploys automatically.

## Do

- Follow existing project patterns; prefer composition over inventing architecture
- Keep handlers/routes thin when the project uses that pattern
- Update planning, decisions, and run-log together after execution batches
- Confirm before destructive Git, DB, infra, credential, or mass-refactor operations

## Don't

- Skip `init` / `install` and invent a parallel agent layout
- Treat forge (GitHub vs GitLab) or stack rules as universal unless this repo installed them
- Store reflections in `RUN_LOG.md` or promote every `LEARNING.md` note into a rule without review
- Commit secrets into `.agent-blueprint.yaml` or playbooks

## Completion criteria

Work is complete only when:

1. The requested outcome is implemented
2. Relevant quality gates and tests for the change are satisfied
3. Required docs / memory tracking files for this repo are updated
4. No known regressions were introduced in the touched surface
5. Remaining risks or follow-ups are stated clearly when relevant
