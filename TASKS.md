# DeWPS tasks

## Current phase

Phase 3: Scope cut and docs.

- [ ] Verify `debloat` on the reference machine.
  - Scope: close WPS, run `sudo ./dewps.sh debloat --ads --telemetry --ai`,
    check `./dewps.sh status`, then `sudo ./dewps.sh restore` if a rollback is
    wanted.
  - Acceptance criteria: only the selected groups show as disabled; local
    features (Power Query, search, editing) still work; nothing written outside
    `/usr/lib/office6`.
  - Automated validation: `bash -n`, `shellcheck -S style`, `tests/*.sh`.
  - Manual validation: inspect `status`, launch WPS, open/save a document.
  - Dependencies or blockers: requires explicit approval for system-changing
    commands.

## Completed

- [x] Commit the project state.
  - Validation: three commits on `main` (`feat` tool, `test` suite, `docs`);
    `git status --short` clean; tests re-run on the committed tree. Not pushed
    yet.
- [x] Split debloat into selectable groups.
  - Validation: `--telemetry` (20), `--ads` (28), `--cloud` (60), `--cef` (6),
    `--ai` (44), `--daemons` (4); no flags means all groups; unknown flags abort
    before changes; group selection covered by the debloat cycle test.
- [x] Cut the tool down to debloat only.
  - Validation: removed `privacy`, `clean`, `harden`, `sandbox-*`, `hook-*`,
    `hide-hub`/`show-hub`, `scan`, and the selective command layer; `hosts` kept
    as the optional DNS block; script is ~860 lines; a pre-cut backup was taken
    and later deleted on request.
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
  - Validation: `tests/test_debloat_cycle.sh` (25 checks) and
    `tests/test_docs_links.sh` (0 broken links) pass in isolated temp
    directories.
- [x] Rewrite project docs per the `project-docs` template.
  - Validation: link checker passes; group counts match `status` and the help
    text; single handover document in `AGENTS.md`.
