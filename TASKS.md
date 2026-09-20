# DeWPS tasks

## Current phase

Phase 3: Scope cut and docs.

- [ ] Commit the pending project state.
  - Scope: untracked files (`dewps.sh`, `README.md`, `SPEC.md`, `ROADMAP.md`,
    `TASKS.md`, `AGENTS.md`, `tests/`) in separate commits for the group split,
    tests, and docs.
  - Acceptance criteria: `git status --short` empty after committing; no
    credentials, machine-specific paths, or runtime artifacts committed.
  - Automated validation: `git status --short` empty; tests re-run on the
    committed tree.
  - Manual validation: read the staged diff.
  - Dependencies or blockers: user approval to commit and push.
- [ ] Verify `debloat` on the reference machine.
  - Scope: close WPS, run `sudo ./dewps.sh debloat --ads --telemetry --ai`,
    check `./dewps.sh status`, then `sudo ./dewps.sh restore` if a rollback is
    wanted.
  - Acceptance criteria: only the selected groups show as disabled; local
    features (Power Query, search, editing) still work; nothing written outside
    `/usr/lib/office6` and `~/.config/dewps`.
  - Automated validation: `bash -n`, `shellcheck -S style`, `tests/*.sh`.
  - Manual validation: inspect `status`, launch WPS, open/save a document.
  - Dependencies or blockers: requires explicit approval for system-changing
    commands.

## Completed

- [x] Split debloat into selectable groups.
  - Validation: `--telemetry` (20), `--ads` (28), `--cloud` (60), `--cef` (6),
    `--ai` (44), `--daemons` (4); no flags means all groups; unknown flags abort
    before changes; group selection covered by the debloat cycle test.
- [x] Cut the tool down to debloat only.
  - Validation: removed `privacy`, `clean`, `harden`, `sandbox-*`, `hook-*`,
    `hide-hub`/`show-hub`, `scan`, and the selective command layer; `hosts` kept
    as the optional DNS block; script is ~890 lines; full repository backed up
    to `~/.local/share/dewps/dewps-backup-2026-09-20.tar.gz` before the cuts.
- [x] Leave local-only daemons untouched by default.
  - Validation: `BLOAT_BINARIES` contains only cloud/AI/installer daemons
    (`wpsquery` = Power Query and `EverythingDaemon` = search index removed
    after string analysis showed no network use).
- [x] Close debloat coverage gaps.
  - Validation: docer/online-content addons and 135 curated domains added (570
    merged with `kblockhost.ini`); all names verified against the installed
    tree.
- [x] Fix the debloat/update lifecycle.
  - Validation: simulated pacman upgrade keeps the freshest copy, never nests
    directories, and `restore` prefers the fresh copy.
- [x] Add hermetic tests.
  - Validation: `tests/test_debloat_cycle.sh` (27 checks) and
    `tests/test_docs_links.sh` (0 broken links) pass in isolated temp
    directories.
- [x] Rewrite project docs per the `project-docs` template.
  - Validation: link checker passes; group counts match `status` and the help
    text; single handover document in `AGENTS.md`.
