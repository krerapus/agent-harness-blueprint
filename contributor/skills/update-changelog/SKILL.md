---
name: update-changelog
description: >-
  Maintain Keep a Changelog CHANGELOG.md for blueprint package repos
  (agent-harness-blueprint, assets-blueprint, homebrew-blueprint). Use when
  releasing, bumping VERSION/pack versions/Formula, writing PR release notes,
  or when the user says update changelog, add unreleased notes, or cut a
  release section.
---

# Update Changelog

Keep **one** `CHANGELOG.md` at the package root for each blueprint package repo. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) + [SemVer](https://semver.org/).

## Scope (which repo)

| Repo | What a “release” means | Version source of truth |
|---|---|---|
| `agent-harness-blueprint` | CLI release (`vX.Y.Z` / pre-release) | `./VERSION` |
| `assets-blueprint` | Pack release (`core-v…`, catalog bump) | `catalog.yaml` + `packs/*/pack.yaml` |
| `homebrew-blueprint` | Formula bump for a CLI version | `Formula/blueprint.rb` `version` / URL |

Detect the current checkout with directory basename (or layout markers). Do **not** write consumer-app changelogs with this skill.

## Required file

If `CHANGELOG.md` is missing at the repo root, create it:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed
```

Omit empty subsections only when cutting a dated release section (keep empty stubs under `[Unreleased]` while the branch is open).

## When to update

| Moment | Action |
|---|---|
| Feature / fix lands on the package branch | Append bullets under `## [Unreleased]` → Added / Changed / Fixed / Removed |
| Opening `/pr` | Mirror PR **Release notes** into `[Unreleased]` (same bullets) |
| Cutting a release | Rename `[Unreleased]` → `[X.Y.Z] - YYYY-MM-DD`, then recreate empty `[Unreleased]` above it |

## Bullet rules

- Prefer **outcome/intent** over file lists
- **Do not** include filenames unless the filename *is* the user-facing interface (e.g. a CLI command name)
- One bullet = one user-visible change
- Keep bullets short; group related tiny edits
- Use categories: **Added**, **Changed**, **Deprecated**, **Removed**, **Fixed**, **Security**

## Release cut (checklist)

1. Confirm version SoT matches the section heading (`VERSION`, pack/`catalog.yaml`, or Formula).
2. Move all `[Unreleased]` bullets into `## [X.Y.Z] - YYYY-MM-DD` (UTC date preferred).
3. Recreate blank `## [Unreleased]` with empty Added/Changed/Fixed stubs at the top.
4. Link compare URLs at the bottom when the repo already uses them (optional; match existing style in `agent-harness-blueprint/CHANGELOG.md`).
5. Do not invent history for past releases you cannot verify — start `[Unreleased]` / first dated section from known current version.

## Anti-patterns

- Do not maintain changelogs only in PR bodies — they must land in `CHANGELOG.md`
- Do not duplicate the same bullet under multiple categories
- Do not put secrets, tokens, or internal-only paths in changelog text
- Do not skip `CHANGELOG.md` on `assets-blueprint` or `homebrew-blueprint` because “only the CLI matters” — each package ships on its own cadence
