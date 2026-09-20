# DeWPS project instructions

## Purpose

DeWPS is a debloater for WPS Office CN (`wps-office-cn`) on Arch/CachyOS: pick
which addon groups to disable (telemetry, ads, cloud, embedded browser, AI) plus
the background daemons, optionally sinkhole telemetry domains. One reversible
bash script; nothing is installed, and it deliberately does not attempt privacy
hardening or sandboxing — users who need those should use an open-source office
suite instead of WPS.

- Repository: <https://github.com/KabosuNeko/DeWPS> — Author: KabosuNeko — MIT.
- Target: Arch Linux / AUR `wps-office-cn`, install root `/usr/lib/office6`.
- Tested: Arch/CachyOS, Linux 6.13+, Wayland (Niri), bash 5.2.

## Problem and findings

Measured on `wps-office-cn` 12.1.2.28080-1:

| Category | Finding | Location |
| :--- | :--- | :--- |
| Footprint | ~2 GB installed; addons ~1.1 GB | `/usr/lib/office6` |
| Embedded browser | CEF addon ~246 MB, `libcef.so` 188 MB; idle CEF processes | `addons/`, `office6/` |
| Background daemons | Persistent processes, ~550 MB RAM idle | `wpscloudsvr`, `promecefpluginhost`, `wpsoffice --server=browser` |
| Telemetry | `kdcsdk`, `kwpskdc`, feedback/reporting addons, `tiance` DB | addons, `~/.local/share/Kingsoft` |
| Ads/content | Start page, tips, notifications, stores, hub panels | addons |
| Remote addons | `listV3` allows silent addon pushes | `~/.local/share/Kingsoft/wps/addons/listV3` |
| Domain telemetry | 442 endpoints in `kblockhost.ini`; 570 blocked after merging with the curated list | `addons/kblockhost/kblockhost.ini` |

## Architecture

- `dewps.sh` — the whole tool: constants, the five group lists
  (`BLOAT_TELEMETRY` 18, `BLOAT_ADS` 18, `BLOAT_CLOUD` 49,
  `BLOAT_AI` 44, `BLOAT_BINARIES` 4), helpers, `cmd_*`, `main`. Command table in
  `README.md`, required behavior in `SPEC.md`.
- `tests/` — hermetic regression scripts: `test_debloat_cycle.sh`,
  `test_docs_links.sh`.
- Docs: `SPEC.md`, `ROADMAP.md`, `TASKS.md`, `README.md`.
- State lives in the filesystem: `.disabled` renames, `Disabled by DeWPS` stub
  marker, `/etc/hosts` markers, `/etc/hosts.dewps-backup`. Nothing is written to
  the home directory.
- No installed artifacts: nothing in `/usr/local/bin`, no pacman hook, no
  desktop overrides, no changes to `Office.conf`, tracking databases, or the
  device ID.
- Toolchain: bash >= 4.2 (5.x tested), coreutils, grep, sed, awk, procps-ng,
  `pacman`. No `bc`, no Python, no network access from the script.

### Defense model

```
[1] group debloat     selected addon groups renamed to .disabled
[2] daemon stubs      wpscloudsvr, wpslingxi, wpsd, KPacketInstall replaced with exit-0 stubs
                      (local wpsquery/EverythingDaemon untouched)
[3] DNS sinkhole      /etc/hosts blocks 570 merged domains to 0.0.0.0 between markers (optional)
```

## Script internals

**Reversibility.** Never delete files under `/usr/lib/office6`. Addons rename to
`<name>.disabled`; binaries move to `<bin>.disabled` and are replaced by
`#!/bin/sh` + `exit 0` stubs. Rollback: `restore` plus `hosts-remove`.

**Update lifecycle.** Pacman reinstalls original paths while stale `.disabled`
copies remain. `_disable_addons` / `_disable_binaries` drop the stale copy and
keep the freshest one disabled (never nest); stubs are recognized by the
`Disabled by DeWPS` marker; `restore` prefers the fresh copy. There is no pacman
hook by design: re-run `debloat` after a WPS update.

**Group flags.** `cmd_debloat` parses `--telemetry --ads --cloud --ai
--daemons`; no flags means all groups. Unknown flags abort before any change.

## Working boundaries

- Preserve unrelated changes; treat untracked files as user work until proven
  otherwise.
- Never expose or commit credentials, tokens, sessions, or private data.
- Core invariant: fully reversible. Never permanently delete files under
  `/usr/lib/office6`; every disabling action needs an inverse (`restore`,
  `hosts-remove`).
- Keep it minimal: no privacy hardening (config, tracking DBs, device ID), no
  sandbox, no installers, no pacman hook, no selective-command layer. Those were
  removed on purpose; do not reintroduce without an explicit product decision.
- No new runtime dependencies; prefer coreutils and bash builtins.
- Ask before system-changing commands on the real machine or destructive
  operations.
- Never run `debloat` or `hosts` on a live system without explicit approval;
  tests use fake trees and stubs.

## Commands

```bash
# No build step. Run from the repo, a download, or piped (see README).

# Static analysis
bash -n dewps.sh
shellcheck -S style dewps.sh tests/*.sh

# Tests (isolated temp dirs)
./tests/test_debloat_cycle.sh
./tests/test_docs_links.sh

# Read-only
./dewps.sh version
./dewps.sh help
./dewps.sh status

# System-changing (requires explicit approval)
sudo ./dewps.sh debloat --ads --telemetry --ai   # daily profile
sudo ./dewps.sh debloat                          # all groups
sudo ./dewps.sh hosts
# Piped form: curl -fsSL <url> | sudo bash -s -- debloat --ads --telemetry --ai
```

## Validation

- Full gate before reporting done: `bash -n`, `shellcheck -S style`, both test
  scripts.
- Inspect `git status` and the diff; leave no system-changing artifacts from
  tests.
- Verify behavior changes with real `status` output.
- Keep group counts in sync between the script, help text, and docs; update
  `SPEC.md`, `ROADMAP.md`, `TASKS.md`, and `README.md` when classifications
  change.

## Documentation routing

- Read `SPEC.md` for requirements and acceptance criteria.
- Read `ROADMAP.md` for phase order and exit criteria.
- Read `TASKS.md` for current work and validation status.
- Read `README.md` for group selection and rollback steps.
