# Skills

Canonical sources live in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) under `packs/core/harness/skills/`. Edit packs there; bump pack version + `catalog.yaml`. A legacy mirror may still exist at [harness/skills/](../harness/skills/) in this checkout (fallback only — see [architecture-split.md](architecture-split.md)).

After `blueprint install`, the same folders appear under the consumer's `.cursor/skills/`, `.claude/skills/`, and/or `.agents/skills/` as `SKILL.md` plus optional bundles. They are **human-curated** procedures—load them when the task matches their scope.

## `task-execution`

**Intent:** Tie each implementation batch back to observable artifacts in the **adopting project**:

- reconcile `PLANNING.md` checkboxes / `## ✅ Done`,
- append a succinct `DECISIONS.md` line (did / why),
- append one capped `RUN_LOG.md` telemetry row,
- enforce RUN_LOG retention (keep ~30 freshest rows beneath the header).

Use whenever execution must leave audit breadcrumbs—not casual Q&A.

## `context-recall`

**Intent:** Define *how layered memory behaves* versus chat history:

- what belongs in telemetry vs rationale vs drafts,
- which layers to read before executing,
- how humans promote `LEARNING.md` ideas into curated skills/rules.

## `refactor-code` (+ `test-strategy.md`)

**Intent:** Opinionated simplification playbook—flatten complexity, extract duplication thoughtfully, preserve behavior (any programming language). Ships with **`disable-model-invocation`** so tooling does not auto-load it—invoke deliberately when refactoring.

**Required pairing:** when active, also enable `/ponytail` (see HARNESS skill use cases). Companion **test-strategy** lays out regression priorities and safety rails. The workflow expects humans to apply risky edits/tests while the assistant analyzes and proposes increments.

## `docs-style`

**Intent:** Opinionated docs layout—thin root `README`, deeper material inside `docs/` plus guidance for richer `ARCHITECTURE.md` write-ups (Mermaid, lifecycle fidelity). Also `disable-model-invocation`; use when refactoring documentation IA.

## `i-have-adhd`

**Intent:** ADHD-friendly agent output — lead with the next action, number multi-step work, restate state each turn, suppress tangents, concrete time estimates, no preamble/closers. Invoke with `/i-have-adhd`; stays on until `stop adhd mode`.

Vendored from [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) (MIT). Ships with `disable-model-invocation`.

## `ponytail` (+ review / audit / debt / gain / help)

**Intent:** Minimal-code bias — YAGNI ladder before writing (skip / reuse / stdlib / native / dependency / one line / minimum). Default intensity `full`; switch with `/ponytail lite|full|ultra|off`. Companion skills:

- `ponytail-review` — delete-list for over-engineering in the current diff
- `ponytail-audit` — repo-wide over-engineering audit
- `ponytail-debt` — harvest deferred `ponytail:` shortcuts
- `ponytail-gain` — benchmark impact scoreboard reference
- `ponytail-help` — command quick reference

Vendored from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT).

**Required with `refactor-code`:** invoking `/refactor-code` must also enable `/ponytail` for that session.

## `generate-test-cases`

**Intent:** Senior-QA playbook that analyzes a software change (JIRA / branch / PR / `PLANNING.md`) and writes a Testiny-importable CSV to `.testiny/testcases-<JIRA>.csv` (gitignored). Ships with `disable-model-invocation` — invoke explicitly (`/generate-test-cases`). Schema and column rules live in the skill markdown (no bundled CSV). Opt-in only; never auto-run for ordinary coding work.

## `update-api-docs`

**Intent:** Keep FastAPI OpenAPI YAML (`docs/api/openapi.yaml`) and response example JSON files in sync with `app/routers/`. Prefer re-export via `app.openapi()`; fall back to manual path/schema/example edits. Use when adding, removing, or changing API endpoints, refreshing swagger/OpenAPI, or updating response examples.

## `skill-creator`

**Intent:** Meta-playbook for authoring new skills:

- interviewing intent/trigger phrases,
- bundling supplementary assets,
- qualitative + quantitative evaluation loops,
- tightening descriptions (“slightly pushy” wording) so retrieval triggers reliably.

Treat it as **authoring infrastructure**, not coding policy baked into builds.
