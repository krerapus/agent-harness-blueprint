# Architecture — three-repo split

Blueprint is split for Homebrew distribution and independent asset versioning.

## Repositories

| Repo | Role |
|------|------|
| [agent-harness-blueprint](https://github.com/krerapus/agent-harness-blueprint) | CLI + runtime + asset manager + builtin bootstrap |
| [assets-blueprint](https://github.com/krerapus/assets-blueprint) | Versioned packs (core, prompts, memories, examples) |
| [homebrew-blueprint](https://github.com/krerapus/homebrew-blueprint) | Homebrew Formula only |

## Runtime flow

```text
CLI → Runtime → Asset Manager → packs (cache / sibling / legacy)
                 ↓
            Projector → .cursor / .claude / .agents
```

## Local layout (CLI)

```text
agent-harness-blueprint/
├── blueprint                 # CLI entry
├── builtin/                  # Offline bootstrap (entrypoints + memory skeletons)
├── lib/blueprint/            # Modules (assets, xdg, harness, …)
├── contributor/              # Package-contributor tooling
├── VERSION                   # CLI semver only
└── harness/, templates/, …   # LEGACY during transition (prefer assets-blueprint)
```

## Config / cache (XDG)

```text
~/.config/blueprint/     config.yaml, assets.yaml, credentials/, plugins/
~/.cache/blueprint/      assets/<pack>/<ver>/, downloads/, catalog/
~/.local/share/blueprint history.jsonl, targets.json
```

## Asset commands

```bash
blueprint assets list
blueprint assets install core
blueprint assets update core
blueprint assets doctor --offline
```

Dev: place `assets-blueprint` as a sibling of this repo, or set `BLUEPRINT_ASSETS_ROOT`.

## Transition

Until the first assets GitHub Release and Go binary ship:

1. Sibling `../assets-blueprint/packs/core` is preferred.
2. Legacy `harness/` / `templates/` in this repo remain as fallback.
3. Homebrew Formula expects release tarballs named `blueprint_<ver>_<os>_<arch>.tar.gz`.
