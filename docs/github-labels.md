# Recommended GitHub labels

Suggested labels for [krerapus/agent-harness-blueprint](https://github.com/krerapus/agent-harness-blueprint). Create these in **Settings → Labels** (or via `gh label create`) so issues and PRs stay sortable for newcomers. Harness *content* issues usually belong in [`assets-blueprint`](https://github.com/krerapus/assets-blueprint).

## Core

| Label | Color (hex) | Description |
|---|---|---|
| `bug` | `#d73a4a` | Something is broken or incorrect |
| `enhancement` | `#a2eeef` | New feature or improvement request |
| `documentation` | `#0075ca` | Docs-only changes or doc gaps |
| `good first issue` | `#7057ff` | Suitable for first-time contributors |
| `help wanted` | `#008672` | Extra attention or community help welcome |
| `question` | `#d876e3` | Clarification or discussion |
| `duplicate` | `#cfd3d7` | Already tracked elsewhere |
| `invalid` | `#e4e669` | Not actionable or out of scope as filed |
| `wontfix` | `#ffffff` | Will not be addressed (with rationale) |

## Optional (project-specific)

| Label | Color (hex) | Description |
|---|---|---|
| `cli` | `#0e8a16` | `blueprint` CLI / runtime behavior (this repo) |
| `harness` | `#1d76db` | Pack content (prefer filing against `assets-blueprint`) |
| `assets` | `#5319e7` | Asset manager / pack install path in this CLI |
| `breaking` | `#b60205` | Breaking change for adopters |
| `security` | `#ee0701` | Security-related (prefer private advisories first) |

## Create with GitHub CLI

```bash
gh label create "bug" --color "d73a4a" --description "Something is broken or incorrect"
gh label create "enhancement" --color "a2eeef" --description "New feature or improvement request"
gh label create "documentation" --color "0075ca" --description "Docs-only changes or doc gaps"
gh label create "good first issue" --color "7057ff" --description "Suitable for first-time contributors"
gh label create "help wanted" --color "008672" --description "Extra attention or community help welcome"
gh label create "question" --color "d876e3" --description "Clarification or discussion"
gh label create "duplicate" --color "cfd3d7" --description "Already tracked elsewhere"
gh label create "invalid" --color "e4e669" --description "Not actionable or out of scope as filed"
gh label create "wontfix" --color "ffffff" --description "Will not be addressed"
```

Reuse existing GitHub defaults when present; only create missing labels.
