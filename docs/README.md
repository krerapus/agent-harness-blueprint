# Documentation index

Narrative docs for the Blueprint **CLI + runtime** (`agent-harness-blueprint`). Start from the root [README](../README.md) for install, usage, and [where content lives](../README.md#where-content-lives).

Sibling repos: [assets-blueprint](https://github.com/krerapus/assets-blueprint) (packs) · [homebrew-blueprint](https://github.com/krerapus/homebrew-blueprint) (Formula).

**Ownership rule:** CLI / projection / release docs stay here. Pack content inventories describe material whose **canonical home** is `assets-blueprint` (legacy mirrors may still exist in this checkout).

## By category

### Ownership & architecture

| Document | Contents |
|---|---|
| [architecture-split.md](architecture-split.md) | **What stays in which repo** (CLI / assets / Homebrew) |
| [architecture.md](architecture.md) | CLI + packs vs consumer; multi-runtime projection |
| [compatibility.md](compatibility.md) | CLI paths vs pack paths vs consumer-only artifacts |
| [harness-ownership.md](harness-ownership.md) | `HARNESS.md` vs agent files; init/update ownership |

### Release & distribution

| Document | Contents |
|---|---|
| [release.md](release.md) | Tag → CI → GitHub Release → artifacts (this repo) |
| [distribution.md](distribution.md) | Channels, Homebrew layout, troubleshooting |
| [homebrew.md](homebrew.md) | Tap relationship, formula bump, secrets |

### Setup

| Document | Contents |
|---|---|
| [setup.md](setup.md) | Init → assets → install → doctor flow |
| [local-development.md](local-development.md) | Dev mode: sibling packs, XDG sandbox, tests |
| [adoption-and-lineage.md](adoption-and-lineage.md) | Adoption checklist |

### How it works

| Document | Contents |
|---|---|
| [how-it-works.md](how-it-works.md) | Read order, layers, conflict policy |
| [skills.md](skills.md) | Skill concepts (`packs/core/harness/skills/`) |
| [rules.md](rules.md) | Rule concepts (`packs/core/harness/rules/`) |
| [slash-commands.md](slash-commands.md) | Slash playbook inventory |

### Harness workflow

| Document | Contents |
|---|---|
| [harness-workflow.md](harness-workflow.md) | Step-by-step AI delivery loop |
| [quick-start.md](quick-start.md) | `/start` ritual in adopting projects |
| [memory-and-planning.md](memory-and-planning.md) | Consumer memory files + template sources |

### Community

| Document | Contents |
|---|---|
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Dev setup, which repo to edit, testing |
| [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) | Contributor Covenant 3.0 |
| [SECURITY.md](../SECURITY.md) | Vulnerability reporting |
| [CHANGELOG.md](../CHANGELOG.md) | Keep a Changelog release notes |
| [github-labels.md](github-labels.md) | Recommended GitHub labels |
| [standards/skill-naming.md](standards/skill-naming.md) | Skill naming (`<action>-<object>[-<context>]`) |

## CLI

```bash
blueprint assets install core
blueprint doctor
blueprint init --target /path/to/repo
blueprint install default --runtime all --target /path/to/repo
blueprint install engineering --overlay gitlab --runtime all --target /path/to/repo
blueprint update --target /path/to/repo
blueprint sync --target /path/to/repo
```

Smoke tests: `./tests/cli/smoke.sh` · harness ownership tests: `./tests/cli/harness.sh`
