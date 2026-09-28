# Documentation index

Narrative docs for the Blueprint **CLI + runtime** (`agent-harness-blueprint`). Start from the root [README](../README.md) for install, usage, and [where content lives](../README.md#where-content-lives).

Sibling repos: [assets-blueprint](https://github.com/krerapus/assets-blueprint) (packs) · [homebrew-blueprint](https://github.com/krerapus/homebrew-blueprint) (Formula).

**Ownership rule:** CLI / projection / release docs stay here. Pack content inventories describe material whose **canonical home** is `assets-blueprint` (no in-tree pack mirrors in this repo).

## By category

### Ownership & architecture

| Document | Contents |
|---|---|
| [architecture-split.md](architecture-split.md) | **What stays in which repo** (CLI / assets / Homebrew) |
| [architecture.md](architecture.md) | CLI + packs vs consumer; multi-runtime projection |
| [compatibility.md](compatibility.md) | CLI paths vs pack paths vs consumer-only artifacts |
| [harness-ownership.md](harness-ownership.md) | `HARNESS.md` vs agent files; install/update ownership |
| [how-it-works.md](how-it-works.md) | Read order, layers, conflict policy |

### Setup & usage

| Document | Contents |
|---|---|
| [setup.md](setup.md) | Install CLI, first consumer project |
| [quick-start.md](quick-start.md) | `/start` ritual in adopting projects |
| [adoption-and-lineage.md](adoption-and-lineage.md) | Adoption checklist |
| [harness-workflow.md](harness-workflow.md) | Step-by-step AI delivery loop |
| [memory-and-planning.md](memory-and-planning.md) | Consumer memory files + template sources |
| [slash-commands.md](slash-commands.md) | Slash playbook inventory |
| [rules.md](rules.md) | Rule concepts (`packs/core/harness/rules/`) |
| [profiles.md](profiles.md) | Install profiles → canonical in [assets-blueprint](https://github.com/krerapus/assets-blueprint/blob/master/docs/profiles.md) |
| [skills.md](skills.md) | Skill concepts → canonical inventory in [assets-blueprint](https://github.com/krerapus/assets-blueprint/blob/master/docs/skills.md) |
| [standards/skill-naming.md](standards/skill-naming.md) | Naming → canonical in [assets-blueprint](https://github.com/krerapus/assets-blueprint/blob/master/docs/standards/skill-naming.md) |

### Release

| Document | Contents |
|---|---|
| [release.md](release.md) | **Release architecture:** versioning, channels, artifacts, ownership |
| [release-workflow.md](release-workflow.md) | **Operational runbook:** pre-release → production + Formula |
| [homebrew.md](homebrew.md) | Tap, Formula bump, secrets, Formula troubleshooting |

### Development

| Document | Contents |
|---|---|
| [local-development.md](local-development.md) | Dev mode: sibling packs, XDG sandbox, tests |

### Community

| Document | Contents |
|---|---|
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Dev setup, which repo to edit, testing |
| [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) | Contributor Covenant 3.0 |
| [SECURITY.md](../SECURITY.md) | Vulnerability reporting |
| [CHANGELOG.md](../CHANGELOG.md) | Keep a Changelog release notes |
| [github-labels.md](github-labels.md) | Recommended GitHub labels |

## CLI

```bash
blueprint assets install core
blueprint doctor
blueprint install default --runtime all --target /path/to/repo
blueprint install engineering --overlay gitlab --runtime all --target /path/to/repo
blueprint update --target /path/to/repo
blueprint sync --target /path/to/repo
```

Smoke tests: `./tests/cli/smoke.sh` · harness ownership tests: `./tests/cli/harness.sh`
