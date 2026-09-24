# Local development & testing

How to run the Blueprint CLI from a git checkout in **dev mode** — sibling packs, isolated XDG, throwaway consumers, and automated tests.

End-user install (Homebrew / Release): [setup.md](setup.md). Repo ownership: [architecture-split.md](architecture-split.md).

## Recommended layout

```text
~/Developer/blueprint/          # any parent directory
├── agent-harness-blueprint/    # this repo (CLI)
├── assets-blueprint/           # packs (auto-detected as sibling)
└── homebrew-blueprint/         # Formula only (optional for CLI work)
```

```bash
mkdir -p ~/Developer/blueprint && cd ~/Developer/blueprint

git clone https://github.com/krerapus/agent-harness-blueprint.git
git clone https://github.com/krerapus/assets-blueprint.git

cd agent-harness-blueprint
./blueprint doctor
./blueprint assets list
./blueprint assets doctor --offline
```

With this layout you do **not** need `blueprint assets install core` for day-to-day work: the CLI prefers the sibling checkout over the download cache (see [Pack resolution](#pack-resolution-dev-mode)).

Optional PATH symlink (still runs the checkout script):

```bash
ln -sf "$(pwd)/blueprint" /usr/local/bin/blueprint
which blueprint   # should resolve to your checkout
```

## Pack resolution (dev mode)

When the CLI needs `core` (or another pack), it resolves in this order:

1. `BLUEPRINT_ASSETS_ROOT` (if set and contains `packs/`)
2. Sibling `../assets-blueprint` (directory next to this repo with `packs/core`)
3. Cached pack under `$XDG_CACHE_HOME/blueprint/assets/<pack>/<ver>/`

There is **no** in-tree `harness/` fallback in this repo. So “dev mode” usually means: **edit packs in the sibling repo; run `./blueprint` from the CLI checkout.**

| Goal | What to do |
|------|------------|
| Iterate on CLI code | Edit `blueprint` / `lib/blueprint/`; run `./blueprint …` |
| Iterate on harness content | Edit `assets-blueprint/packs/…`; no pack bump required locally |
| Force a specific packs tree | `export BLUEPRINT_ASSETS_ROOT=/path/to/assets-blueprint` |
| Test like Homebrew (no sibling) | Unset `BLUEPRINT_ASSETS_ROOT`; hide/rename sibling; `blueprint assets install core` |

## Environment variables

| Variable | Purpose |
|----------|---------|
| `BLUEPRINT_ASSETS_ROOT` | Absolute path to an `assets-blueprint` checkout |
| `BLUEPRINT_ASSETS_BASE_URL` | Override pack Release download base URL |
| `BLUEPRINT_OFFLINE=1` | Do not fetch catalog/releases (local/sibling/cache only) |
| `BLUEPRINT_ASSETS_OFFLINE=1` | Same for assets subsystem |
| `XDG_CONFIG_HOME` / `XDG_CACHE_HOME` / `XDG_DATA_HOME` | Isolate config, pack cache, history/targets from your real home |
| `BLUEPRINT_TARGETS_FILE` | Override known-targets JSON path |
| `BLUEPRINT_RESUME=1` | Resume an interrupted install/sync from consumer `.agent-blueprint/` |
| `BLUEPRINT_NO_CLEAR=1` | Skip terminal clear in the interactive menu |
| `CI=1` | Non-interactive defaults (used by tests) |
| `NO_COLOR=1` | Disable ANSI colors |

User config (created on first run): `~/.config/blueprint/config.yaml` (`offline`, `assets.base_url`, …).

## Isolated sandbox (recommended for manual tests)

Avoid polluting your real `~/.cache/blueprint` and targets list:

```bash
cd /path/to/agent-harness-blueprint

export XDG_CONFIG_HOME="$(pwd)/.tmp-dev/config"
export XDG_CACHE_HOME="$(pwd)/.tmp-dev/cache"
export XDG_DATA_HOME="$(pwd)/.tmp-dev/data"
export BLUEPRINT_TARGETS_FILE="$(pwd)/.tmp-dev/targets.json"
# optional: export BLUEPRINT_ASSETS_ROOT="$(cd ../assets-blueprint && pwd)"
# optional: export BLUEPRINT_OFFLINE=1

mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"

./blueprint doctor
./blueprint assets list
```

Throwaway consumer:

```bash
CONSUMER="$(pwd)/.tmp-dev/consumer"
rm -rf "$CONSUMER"
mkdir -p "$CONSUMER"

./blueprint init --target "$CONSUMER"
./blueprint install default --runtime all --target "$CONSUMER"
./blueprint doctor --target "$CONSUMER"

# Preview without writing
./blueprint sync --dry-run --target "$CONSUMER"

# Clean up when done
rm -rf "$(pwd)/.tmp-dev"
```

Do **not** use this package root as `--target` (the CLI rejects installing into itself).

## Daily CLI change loop

```bash
# 1. Edit CLI
$EDITOR lib/blueprint/harness.sh   # example

# 2. Sanity
./blueprint doctor
./blueprint assets doctor --offline

# 3. Exercise against a sandbox consumer (see above)
./blueprint install default --runtime cursor --target "$CONSUMER" --dry-run
./blueprint install default --runtime cursor --target "$CONSUMER"
./blueprint sync --target "$CONSUMER"
./blueprint update --target "$CONSUMER"

# 4. Automated tests
./tests/cli/smoke.sh
./tests/cli/harness.sh
```

## Daily pack content loop

```bash
cd ../assets-blueprint
$EDITOR packs/core/harness/skills/…   # or commands/rules/templates/blueprints

cd ../agent-harness-blueprint
./blueprint assets list                # should show sibling / local repo
./blueprint sync --target "$CONSUMER"  # re-project from sibling packs
./blueprint doctor --target "$CONSUMER"
```

No `catalog.yaml` bump is required until you publish a pack Release. Local sibling resolution always reads the working tree.

To exercise the **download/cache** path instead of the sibling:

```bash
unset BLUEPRINT_ASSETS_ROOT
# temporarily move sibling out of the way, or work from a non-sibling path
./blueprint assets install core
./blueprint assets doctor
```

## Automated tests

Run from the **CLI package root**:

| Script | What it covers |
|--------|----------------|
| `./tests/cli/smoke.sh` | init/install/sync/doctor/del, skill-mode, conflicts, remote source, clean |
| `./tests/cli/harness.sh` | `HARNESS.md` / agent-file ownership for init/update |
| `./tests/cli/package-release.sh` | `package-release.sh`, archive verify, formula bump dry-run |

Smoke and harness tests set their own temporary `XDG_*` and `BLUEPRINT_TARGETS_FILE` under `.tmp-*` (gitignored). They require a resolvable `core` pack (sibling `assets-blueprint` or `BLUEPRINT_ASSETS_ROOT`).

```bash
./tests/cli/smoke.sh
./tests/cli/harness.sh

# Only when changing packaging / Formula bump scripts:
./tests/cli/package-release.sh
```

## Contributor harness (optional)

While developing **this** repo, project local `/commit`, `/pr`, and `skill-creator` into gitignored runtimes:

```bash
./blueprint install-contributor --runtime all
```

Do not commit `.cursor/`, `.claude/`, `.agents/`, or `.agent-blueprint.local.yaml` produced by that command. Details: [CONTRIBUTING.md](../CONTRIBUTING.md).

## Interactive menu

```bash
./blueprint
# or
./blueprint menu --target /path/to/throwaway-consumer
```

Use Esc to go back. Prefer a sandbox consumer and isolated XDG when experimenting with `rm` / `del`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `assets doctor` / install cannot find harness | Clone sibling `assets-blueprint`, or set `BLUEPRINT_ASSETS_ROOT`, or `blueprint assets install core` |
| Sibling ignored | Confirm `../assets-blueprint/packs/core` exists; or set `BLUEPRINT_ASSETS_ROOT` explicitly |
| Changes in packs not appearing | Confirm resolution via `blueprint assets list`; run `sync` on the consumer; avoid testing only against a stale cache while a sibling is present (sibling wins) |
| Polluted targets / history | Use isolated `XDG_*` + `BLUEPRINT_TARGETS_FILE` as above |
| `Target must not be this package` | Point `--target` at a consumer directory outside this checkout |
| Network errors during `assets install` | `BLUEPRINT_OFFLINE=1` with sibling packs, or fix connectivity to GitHub Releases |
| Homebrew `blueprint` shadows checkout | `hash -r`; use `./blueprint` or fix PATH / symlink |

## Related

- [setup.md](setup.md) — consumer adoption flow
- [architecture-split.md](architecture-split.md) — which repo to edit
- [release.md](release.md) — tagging and GitHub Releases
- [CONTRIBUTING.md](../CONTRIBUTING.md) — PR expectations
