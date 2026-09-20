# DeWPS specification

## Problem

`wps-office-cn` ships telemetry, ads, and AI addons that most users never need,
plus a cloud/shell stack. Removing package files would break pacman, and manual
debloat recipes are not reversible. Measured details are in `AGENTS.md`.

## Users

- Arch Linux / CachyOS users of `wps-office-cn` who keep WPS for MS Office
  format compatibility but want telemetry, ads and AI gone.
- Maintainers extending the addon classification.

Constraints: `sudo` available, no files installed outside the package manager,
system package management must keep working.

## Required behavior

1. `debloat` accepts group flags `--telemetry`, `--ads`, `--ai`; with no flags
   it selects every group. Selected addon directories are renamed to
   `<name>.disabled`.
2. Unknown group flags fail with a usage message before changing anything.
3. `restore` returns addons to factory state, including after a pacman upgrade
   reinstalled original paths.
4. `hosts` writes unique `0.0.0.0 <domain>` entries (curated list +
   `kblockhost.ini`) between two markers in `/etc/hosts`; `hosts-remove` removes
   exactly that block.
5. `status` is read-only and reports per-group active/disabled counts and hosts
   state.

Error, empty, and recovery behavior:

- WPS missing or missing root → clear error, exit 1.
- "Nothing to do" cases (hosts already blocked) → exit 0 with a message.
- Repeated runs are idempotent. A pacman reinstall must never produce nested
  structures (for example `kfeedback.disabled/kfeedback`) or restore stale
  versions.

## User experience

- Single CLI, `dewps <command>`; `help` lists groups with addon counts and
  examples.
- Runs from a repo checkout, a downloaded file, or piped
  (`curl -fsSL <url> | bash -s -- <command>`) without saving anything.
- Warm path: `debloat --ads --telemetry --ai`, then `status`.
- Human-readable output; no interactive prompts.
- Documentation and code in English.

## Architecture and data flow

- One bash script, `dewps.sh`: constants, three group lists
  (`BLOAT_TELEMETRY` 18, `BLOAT_ADS` 18, `BLOAT_AI` 44), helpers, `cmd_*`,
  `main`. Regression tests in `tests/`.
- State lives in the filesystem: `.disabled` renames, `/etc/hosts` markers,
  backup file. Nothing is written to the home directory.
- Deliberately excluded from every group (boot-required in the default
  Prometheus shell): the cloud/login addons (`qing`, `kdocer*`, `kclouddocs`...),
  the web shell and browser (`cef`, `kcef`, `kstartpage`, `kpromewebapp`,
  `kpluginconfigcenter`, `kccsdk`, `knetwork`, plugin manager, `kapplist`,
  `kappmgr`) and the background daemons (`wpscloudsvr`, `wpslingxi`, `wpsd`,
  `KPacketInstall`). User testing showed WPS hangs or opens a blank window when
  any of them is missing.
- External interfaces: `/usr/lib/office6`, `/etc/hosts`, `pacman`.
- Privilege flow: `sudo` for system paths; nothing else is touched.

## Security and privacy

- Scope: debloat ads/telemetry/AI addons; `hosts` blocks known
  telemetry/cloud domains.
- Guarantees: no deletion of files under `/usr/lib/office6`; every action has an
  inverse (`restore`, `hosts-remove`, backup file).
- Non-guarantees: WPS still runs with user privileges and can read the home
  directory; `/etc/hosts` can be bypassed by DoH/proxies/hardcoded IPs; there is
  no sandbox or credential masking by design. Users who need those should use an
  open-source office suite instead of WPS.

## Performance and compatibility

- Target: Arch Linux/CachyOS, `wps-office-cn` 12.1.2.28080-1 (reference),
  Linux 6.13+, Wayland/X11.
- Runtime deps: bash >= 4.2 (5.x tested), coreutils, grep, sed, awk,
  `pacman`. No `bc`, no Python, no network access from the script.
- Must not break pacman: no package files removed, no ownership changes under
  `/usr/lib`, no pacman hook.

## Non-goals

- No privacy hardening of user data (`Office.conf`, tracking databases, device
  ID), no sandbox, no wrappers, no pacman hook.
- No disabling of the cloud stack, web shell/browser, or background daemons:
  WPS CN needs them to boot in its default mode.
- No support for non-CN WPS packages or installs outside `/usr/lib/office6`.
- No GUI, no self-update, no patching of WPS binaries, no touching user
  documents.

## Acceptance criteria

- [ ] `bash -n dewps.sh` and `shellcheck -S style dewps.sh` report nothing.
- [ ] `tests/test_debloat_cycle.sh` and `tests/test_docs_links.sh` pass.
- [ ] `status` reports per-group counts on a machine with WPS installed.
- [ ] Group selection: `debloat --ads --ai` disables only those groups.
- [ ] Manual reversibility: `debloat` → simulated update → `debloat` →
      `restore` leaves no nested directories and no stale `.disabled` files.
- [ ] `hosts` → `hosts-remove` restores `/etc/hosts` to its pre-`hosts` state.
- [ ] Documentation links resolve (README, SPEC, ROADMAP, TASKS, AGENTS).

## Unresolved questions

- How to keep the group classification current as Kingsoft renames components
  across releases (semi-automated drift report?).
- CI: run the hermetic tests in GitHub Actions?
