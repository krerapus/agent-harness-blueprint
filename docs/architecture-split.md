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

## 3. Homebrew Formula (libexec)

Formula installs the **full** release tree under `libexec` and wraps `bin/blueprint`.
Installing only the script into `bin/` breaks `source lib/blueprint/*.sh`.

See [homebrew.md](homebrew.md) and [release.md](release.md).
