# DeWPS specification

## Problem

`wps-office-cn` ships telemetry, ads, cloud services, an embedded browser, AI
addons, a remote addon loader, and background daemons that most users never
need. Removing package files would break pacman, and manual debloat recipes are
not reversible and do not survive package updates. Measured details are in
`AGENTS.md`.

## Users

- Arch Linux / CachyOS users of `wps-office-cn` who keep WPS for MS Office
  format compatibility but want unnecessary features gone.
- Maintainers extending the addon classification.

Constraints: `sudo` available, no files installed outside the package manager,
system package management must keep working.

## Required behavior

1. `debloat` accepts group flags `--telemetry`, `--ads`, `--cloud`, `--cef`,
   `--ai`, `--daemons`; with no flags it selects every group. Each addon group
   is renamed to `<name>.disabled`; `--daemons` replaces the four background
   binaries with `exit 0` stubs, keeping originals at `<binary>.disabled`.
2. Unknown group flags fail with a usage message before changing anything.
3. `restore` returns addons and binaries to factory state, including after a
   pacman upgrade reinstalled original paths.
4. `hosts` writes unique `0.0.0.0 <domain>` entries (curated list +
   `kblockhost.ini`) between two markers in `/etc/hosts`; `hosts-remove` removes
   exactly that block.
5. `kill` terminates matching daemon and CEF processes with SIGTERM.
6. `status` is read-only and reports per-group active/disabled counts, hosts
   state, and running processes.

Error, empty, and recovery behavior:

- WPS missing or missing root → clear error, exit 1.
- "Nothing to do" cases (hosts already blocked, nothing to kill) → exit 0 with a
  message.
- Repeated runs are idempotent. A pacman reinstall must never produce nested
  structures (for example `cef.disabled/cef`) or restore stale versions.
- Local-only daemons (`wpsquery` = Power Query, `EverythingDaemon` = search
  index) are never disabled.

## User experience

- Single CLI, `dewps <command>`; `help` lists groups with addon counts and
  examples.
- Warm path: `sudo dewps debloat --ads --telemetry --ai`, then `dewps status`.
- Human-readable output; no interactive prompts.
- Documentation and code in English.

## Architecture and data flow

- One bash script, `dewps.sh`: constants, group lists, helpers, `cmd_*`
  functions, `main` dispatch. Regression tests in `tests/`.
- State lives in the filesystem: `.disabled` renames, the `Disabled by DeWPS`
  stub marker, `/etc/hosts` markers, backup file. The audit log
  `~/.config/dewps/changes.log` is not used for rollback.
- Groups: `BLOAT_TELEMETRY` (20), `BLOAT_ADS` (28), `BLOAT_CLOUD` (60),
  `BLOAT_CEF` (6), `BLOAT_AI` (44), `BLOAT_BINARIES` (4).
- External interfaces: `/usr/lib/office6`, `/etc/hosts`, `pgrep`/`ps`, `pacman`.
- Privilege flow: `sudo` for system paths; `get_target_user` / `get_target_home`
  resolve the real user for the audit log.

## Security and privacy

- Scope: debloat only. `hosts` blocks known telemetry/cloud domains.
- Guarantees: no deletion of files under `/usr/lib/office6`; every action has an
  inverse (`restore`, `hosts-remove`, backup file).
- Non-guarantees: WPS still runs with user privileges and can read the home
  directory; `/etc/hosts` can be bypassed by DoH/proxies/hardcoded IPs; there is
  no sandbox or credential masking by design. Users who need those should use an
  open-source office suite instead of WPS.

## Performance and compatibility

- Target: Arch Linux/CachyOS, `wps-office-cn` 12.1.2.28080-1 (reference),
  Linux 6.13+, Wayland/X11.
- Runtime deps: bash >= 4.2 (5.x tested), coreutils, grep, sed, awk, procps-ng,
  `pacman`. No `bc`, no Python, no network access from the script.
- Must not break pacman: no package files removed, no ownership changes under
  `/usr/lib`, no pacman hook.

## Non-goals

- No privacy hardening of user data (`Office.conf`, tracking databases, device
  ID), no sandbox, no wrappers, no pacman hook.
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
