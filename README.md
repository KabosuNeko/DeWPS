# DeWPS

Debloater for WPS Office CN (`wps-office-cn`) on Arch Linux: disable the addons
you do not need (telemetry, ads, cloud, embedded browser, AI) and optionally
block telemetry domains. Everything is reversible: addons are renamed to
`.disabled`, daemons are replaced with `exit 0` stubs, and `/etc/hosts` has a
backup and a removal command. Nothing is installed and nothing is written
outside `/usr/lib/office6` and `/etc/hosts`.

## Run

Pipe the script straight to bash; nothing is saved. `-s --` forwards the
arguments after the URL. Set `RAW` once per shell, then any profile below is a
copy-paste:

```bash
RAW=https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh
```

Local autosave/crash recovery is kept in every profile; only login/cloud is
given up from profile 2 onward.

**0. Inspect** — read-only, changes nothing:

```bash
curl -fsSL "$RAW" | bash -s -- status
```

**1. Daily (recommended)** — removes ads, tips, stores, tracking and AI; keeps
login, cloud, sync:

```bash
curl -fsSL "$RAW" | sudo bash -s -- debloat --ads --telemetry --ai
```

**2. No cloud** — also removes login, WPS Cloud drive/sync, docer and online
templates; keeps editing, Power Query, local search, local autosave:

```bash
curl -fsSL "$RAW" | sudo bash -s -- debloat --ads --telemetry --cloud --ai
```

**3. Max addon debloat** — all groups, including the embedded browser/web
panels (`--cef`) and the background daemons:

```bash
curl -fsSL "$RAW" | sudo bash -s -- debloat
```

**4. Max + DNS block** — profile 3, then sinkhole 570 telemetry/cloud domains
(this also makes any remaining online endpoint, including login, unreachable):

```bash
curl -fsSL "$RAW" | sudo bash -s -- debloat
curl -fsSL "$RAW" | sudo bash -s -- hosts
```

Revert at any point:

```bash
curl -fsSL "$RAW" | sudo bash -s -- restore
curl -fsSL "$RAW" | sudo bash -s -- hosts-remove
```

Pin a commit SHA instead of `main` for reproducible code. Prefer a file?
`curl -fsSLO "$RAW" && chmod +x dewps.sh`. After each WPS package update,
re-run your profile (package updates restore files, not your `/etc/hosts`).

## Groups

Fine-grained alternative to the profiles:

| Group | Addons | What it covers |
| :--- | ---: | :--- |
| `--telemetry` | 20 | Feedback, reporting, config-push and tracking SDKs (`kfeedback`, `kdcsdk`, `kwpskdc`, `kdomainservice`, `kconfigcentersdk`, `kapmsdk`) |
| `--ads` | 28 | Start page, tips, notifications, message/push SDKs, stores (`kskincenter`, `kmulticatalog`), Prometheus hub panels, VIP promos |
| `--cloud` | 60 | Cloud drive, docer/KDocs, sharing, account (`qing`, `yunbox`, `kclouddocs`, `knewdocs`, `knewshare`, `kdocer*`), online fonts, OCR/translate/help panels |
| `--cef` | 6 | Embedded browser/webview (`cef`, `kcef`, `kcefwidgetpool`, `kpromebrowser`, `v8`, web resources) |
| `--ai` | 44 | AI/Copilot features (writing, formula, PDF AI, spreadsheet AI, translation/OCR AI) |
| `--daemons` | 4 | Background binaries (`wpscloudsvr`, `wpslingxi`, `wpsd`, `KPacketInstall`) |

```bash
curl -fsSL "$RAW" | sudo bash -s -- debloat --ads --ai
```

`debloat` without groups disables everything. Local features are never touched:
editing/reading Writer/Spreadsheets/Presentation/PDF, open/save of
`docx`/`xlsx`/`pptx`/`pdf`/`ofd`, printing, formulas, charts, Power Query, local
search index, barcode/QR tools.

## Commands

| Command | Privilege | Effect (and what it writes) |
| :--- | :---: | :--- |
| `debloat [--telemetry --ads --cloud --cef --ai --daemons]` | sudo | Rename the selected groups to `.disabled` and stub daemons. All groups when no flag is given |
| `restore` | sudo | Restore addons/binaries to factory state |
| `hosts` | sudo | Block 570 telemetry/cloud domains in `/etc/hosts` (also blocks login/cloud); backup at `/etc/hosts.dewps-backup` |
| `hosts-remove` | sudo | Remove the `/etc/hosts` block |
| `kill` | user | Terminate running daemons and CEF processes |
| `status` | user | Per-group active/disabled counts, hosts state, running processes |
| `version`, `help` | user | Version, usage |

## Limitations

- `/etc/hosts` is bypassed by DoH, proxies, or hardcoded IPs.
- Group classification is static; vendor renames require updates.
- This is not a privacy/security sandbox. If you need process isolation or
  credential masking, use an open-source office suite instead.
- Tested on Arch/CachyOS with `wps-office-cn` 12.1.2.28080-1. Use at your own
  risk.

## Docs

[SPEC.md](SPEC.md) · [ROADMAP.md](ROADMAP.md) · [TASKS.md](TASKS.md) · [AGENTS.md](AGENTS.md)

MIT — [KabosuNeko](https://github.com/KabosuNeko)
