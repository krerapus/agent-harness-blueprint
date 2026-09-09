# Adoption checklist

## Install into a new repository

```bash
/path/to/agent-harness-blueprint/blueprint init --target /path/to/your-repo
/path/to/agent-harness-blueprint/blueprint install default --runtime all --target /path/to/your-repo
# Engineering + GitLab overlay:
/path/to/agent-harness-blueprint/blueprint install engineering --overlay gitlab --runtime all --target /path/to/your-repo
/path/to/agent-harness-blueprint/blueprint doctor --target /path/to/your-repo
```

That writes consumer-only artifacts into the target:

- `AGENTS.md` / `CLAUDE.md` from `templates/entrypoints/` (shared AI workflow contract)
- memory files from `templates/memory/` if absent
- managed `.gitignore` section from `templates/gitignore` (local overrides + conflict siblings; runtime ignores depend on `--skill-mode rebase|merge`)
- `.cursor/`, `.claude/`, and/or `.agents/` from `harness/` + selected blueprint/overlay (`--runtime`)
- install state `.agent-blueprint.yaml`

## Manual cherry-pick (optional)

1. Copy from `harness/commands|skills|rules` (and optional blueprint overlays) into the target `.cursor/`, `.claude/`, and/or `.agents/`.
2. Decide whether automation targets **GitLab (`glab`)** or needs **GitHub (`gh`)** rewrites.
3. Keep `/start` + the memory protocol when you want cross-session continuity and auditable artifacts.
4. Split additional prose into `docs/` whenever the root `README` risks becoming a novel.

## Team standard

Every project should run `init` before coding so `AGENTS.md` documents the harness and AI workflow. Tool-specific runtimes are projections of the same `harness/` sources — edit the package, then `sync`.

See [compatibility.md](compatibility.md).
