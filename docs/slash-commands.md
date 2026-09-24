# Slash commands

Inventory of playbooks under `packs/core/harness/commands/` in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) (projected into the consumer runtime `commands/` directory). See [architecture-split.md](architecture-split.md).

After install, the same playbooks appear under `.cursor/commands/`, `.claude/commands/`, and/or `.agents/commands/`.

| Command | Source (core pack) | Purpose |
|---|---|---|
| `/start` | `harness/commands/start.md` | Branch + reset task memory skeletons (`PLANNING`, `RUN_LOG`, caches). |
| `/commit` | `harness/commands/commit.md` | Inspect diffs/staging, craft conventional commits, push. Does **not** open a PR/MR — use `/pr`. *(Template references JIRA + guarded branches—adapt on GitHub-only repos.)* |
| `/review` | `harness/commands/review.md` | Diff review checklist (security, correctness, performance). |
| `/sync-dev` | `blueprints/engineering/gitlab/commands/` | Merge latest `develop` using `merge-tree` previews + conflict playbook. |
| `/prerequisite` | GitLab overlay | GitLab **`glab`** bootstrap shared by MR-oriented commands. |
| `/pr` | GitLab overlay | Open a GitLab merge request via `glab`, seeding title/body from planning artifacts. |
| `/fix-comment` | GitLab overlay | Resolve a specific GitLab MR discussion via deterministic `glab` steps. |

## Forge portability

GitLab/`glab` playbooks are an **optional overlay** (`--overlay gitlab`), not part of `default`. If you live on GitHub, skip that overlay or add a future `gh` overlay.
