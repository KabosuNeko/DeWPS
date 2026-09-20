# DeWPS roadmap

## Phase 1: Foundation

### Outcome

A single-script debloater that disables unnecessary `wps-office-cn` addons
reversibly and needs no installation.

### Included work

- Group lists: telemetry (20), ads (28), cloud (60), CEF (6), AI (44),
  daemons (4).
- Commands: `debloat` with group flags, `restore`, `hosts`, `hosts-remove`,
  `kill`, `status`, `version`, `help`.
- Reference-machine findings captured in `AGENTS.md`.

### Dependencies and risks

- Requires WPS at `/usr/lib/office6` and `sudo` for system paths.
- Risk: vendor renames components; package upgrades overwrite changes.

### Exit criteria

- All commands implemented and manually exercised on Arch/CachyOS with
  `wps-office-cn` 12.1.2.28080-1; `restore` returns factory state.

### Validation

- Manual command runs; `bash -n`; `status` checked against observed bloat.

## Phase 2: Correctness and coverage

### Outcome

Package upgrades cannot corrupt state; telemetry coverage is measured; local
features are preserved.

### Included work

- Collision handling after upgrades: the freshest copy is kept as disabled,
  directories are never nested, `restore` prefers the fresh copy, stubs are
  idempotent via the `Disabled by DeWPS` marker.
- Coverage audit: docer/online-content addons added, 135 extra curated domains,
  final counts per group.
- Local-only daemons (`wpsquery` = Power Query, `EverythingDaemon` = search
  index) removed from the stub list after string analysis showed no network use.
- Hermetic tests for the debloat/update/restore cycle and group selection.

### Dependencies and risks

- Tests run against fake trees; real pacman behavior still needs manual
  verification.

### Exit criteria

- Tests pass, static analysis is clean, `status` output verified on the
  reference machine.

### Validation

- `tests/*.sh`, `shellcheck -S style dewps.sh tests/*.sh`, manual
  update/restore cycle.

## Phase 3: Scope cut and docs (current)

### Outcome

Only debloat remains: no privacy hardening, no sandbox, no installers.

### Included work

- Removed `privacy`, `clean`, `harden`, `sandbox-run`, `sandbox-install`/
  `remove`, `hook-install`/`remove`, `hide-hub`/`show-hub`, `scan`, and the
  selective command layer.
- `debloat` now takes group flags so users choose what to remove.
- `hosts` kept as the optional DNS-block companion.
- README rewritten; SPEC/ROADMAP/TASKS/AGENTS synced.

### Dependencies and risks

- Removed features were deleted before they reached a public release; the
  decisions are recorded here instead of in git history.

### Exit criteria

- Tests pass, links resolve, group counts match the script; work committed.

### Validation

- `tests/*.sh`, `bash -n`, `shellcheck`, read-through.

## Phase 4: Release readiness (planned)

### Outcome

Committed, tested release with a maintenance workflow for list drift.

### Included work

- Commit the repository with readable history; tag a release.
- CI: `bash -n`, `shellcheck`, both test scripts.
- Drift report: active addons not covered by any group, and new domains found in
  `kblockhost.ini`.

### Dependencies and risks

- CI has no WPS; tests must stay hermetic.

### Exit criteria

- CI green; install-free usage verified from a clean download.

### Validation

- CI run plus a manual download → `debloat --ads --telemetry --ai` → `status` →
  `restore` cycle.
