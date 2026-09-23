# Adoption checklist

## Install into a new repository

```bash
blueprint assets install core
blueprint init --target /path/to/your-repo
blueprint install default --runtime all --target /path/to/your-repo
# Engineering + GitLab overlay:
blueprint install engineering --overlay gitlab --runtime all --target /path/to/your-repo
blueprint doctor --target /path/to/your-repo
```

That writes consumer-only artifacts into the target:

- `AGENTS.md` / `HARNESS.md` from pack (or builtin) entrypoint templates
- memory files from pack memory templates if absent
- managed `.gitignore` section (local overrides + conflict siblings; runtime ignores depend on `--skill-mode rebase|merge`)
- `.cursor/`, `.claude/`, and/or `.agents/` from the resolved `core` pack harness + selected blueprint/overlay (`--runtime`)
- install state `.agent-blueprint.yaml`

Content for those projections is owned by [`assets-blueprint`](https://github.com/krerapus/assets-blueprint) (`packs/core/…`). See [architecture-split.md](architecture-split.md).

## Manual cherry-pick (optional)

Prefer `blueprint install` over hand-copying. If you must:

1. Copy from the resolved core pack’s `harness/commands|skills|rules` (and optional blueprint overlays) into the target `.cursor/`, `.claude/`, and/or `.agents/`.
2. Decide whether automation targets **GitLab (`glab`)** or needs **GitHub (`gh`)** rewrites.
3. Keep `/start` + the memory protocol when you want cross-session continuity and auditable artifacts.
4. Split additional prose into `docs/` whenever the root `README` risks becoming a novel.

## Team standard

Every project should run `init` before coding so `AGENTS.md` documents the harness and AI workflow. Tool-specific runtimes are projections of the same pack sources — edit [`assets-blueprint`](https://github.com/krerapus/assets-blueprint), publish/update the pack, then `sync` / `assets update` in consumers.

See [compatibility.md](compatibility.md).
