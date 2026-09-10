# Documentation index

Narrative docs for this shared agent blueprint package. Start from the root [README](../README.md) for the categorized overview with diagrams.

## By category

### Architecture

| Document | Contents |
|---|---|
| [architecture.md](architecture.md) | Package vs consumer, multi-runtime projection (mermaid) |
| [architecture-split.md](architecture-split.md) | Three-repo split (CLI / assets / Homebrew) |
| [compatibility.md](compatibility.md) | Package sources vs consumer-only artifacts |
| [harness-ownership.md](harness-ownership.md) | `HARNESS.md` vs agent files; init/update ownership |

### Release & distribution

| Document | Contents |
|---|---|
| [release.md](release.md) | Tag → CI → GitHub Release → artifacts |
| [distribution.md](distribution.md) | Channels, Homebrew layout, troubleshooting |
| [homebrew.md](homebrew.md) | Tap relationship, formula bump, secrets |

### Setup

| Document | Contents |
|---|---|
| [setup.md](setup.md) | Init → install → doctor flow (mermaid) |
| [adoption-and-lineage.md](adoption-and-lineage.md) | Adoption checklist |

### How it works

| Document | Contents |
|---|---|
| [how-it-works.md](how-it-works.md) | Read order, layers, conflict policy (mermaid) |
| [skills.md](skills.md) | Skill concepts under `harness/skills/` |
| [rules.md](rules.md) | Rule concepts under `harness/rules/` |
| [slash-commands.md](slash-commands.md) | Slash playbook inventory |

### Harness workflow

| Document | Contents |
|---|---|
| [harness-workflow.md](harness-workflow.md) | Step-by-step AI delivery loop (mermaid) |
| [quick-start.md](quick-start.md) | `/start` ritual in adopting projects |
| [memory-and-planning.md](memory-and-planning.md) | Consumer memory files + template sources |

### Community

| Document | Contents |
|---|---|
| [CONTRIBUTING.md](../CONTRIBUTING.md) | Dev setup, branches, PRs, testing |
| [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) | Contributor Covenant 3.0 |
| [SECURITY.md](../SECURITY.md) | Vulnerability reporting |
| [CHANGELOG.md](../CHANGELOG.md) | Keep a Changelog release notes |
| [github-labels.md](github-labels.md) | Recommended GitHub labels |
| [standards/skill-naming.md](standards/skill-naming.md) | Canonical Skill naming (`<action>-<object>[-<context>]`) |

## CLI

```bash
# Optional: ln -s /path/to/agent-harness-blueprint/blueprint /usr/local/bin/blueprint
./blueprint doctor
./blueprint init --target /path/to/repo
./blueprint install default --runtime all --target /path/to/repo
./blueprint install engineering --overlay gitlab --runtime all --target /path/to/repo
./blueprint update --target /path/to/repo
./blueprint sync --target /path/to/repo
```

Smoke tests: `./tests/cli/smoke.sh` · harness ownership tests: `./tests/cli/harness.sh`
