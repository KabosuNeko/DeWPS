# DeWPS

Debloater for WPS Office CN (`wps-office-cn`) on Arch Linux: disable the addons
you do not need (telemetry, ads, cloud, embedded browser, AI) and optionally
block telemetry domains. Everything is reversible: addons are renamed to
`.disabled`, daemons are replaced with `exit 0` stubs, and `/etc/hosts` has a
backup and a removal command. Nothing is installed.

## Run

```bash
mkdir -p ~/.local/share/dewps && cd ~/.local/share/dewps
curl -fsSLO https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh
chmod +x dewps.sh

sudo ./dewps.sh debloat --ads --telemetry --ai   # pick groups
./dewps.sh status
```

`debloat` without groups disables everything. Pin a commit SHA instead of `main`
for reproducible code; prefer git? `git clone https://github.com/KabosuNeko/DeWPS.git`.

After each WPS package update, re-run your `debloat` command (package updates
restore files, not your `/etc/hosts`).

## Groups

| Group | Addons | What it covers |
| :--- | ---: | :--- |
| `--telemetry` | 20 | Feedback, reporting, config-push and tracking SDKs (`kfeedback`, `kdcsdk`, `kwpskdc`, `kdomainservice`, `kconfigcentersdk`, `kapmsdk`) |
| `--ads` | 28 | Start page, tips, notifications, message/push SDKs, stores (`kskincenter`, `kmulticatalog`), Prometheus hub panels, VIP promos |
| `--cloud` | 60 | Cloud drive, docer/KDocs, sharing, account (`qing`, `yunbox`, `kclouddocs`, `knewdocs`, `knewshare`, `kdocer*`, online fonts, OCR/translate/help panels) |
| `--cef` | 6 | Embedded browser/webview (`cef`, `kcef`, `kcefwidgetpool`, `kpromebrowser`, `v8`, web resources) |
| `--ai` | 44 | AI/Copilot features (writing, formula, PDF AI, spreadsheet AI, translation/OCR AI) |
| `--daemons` | 4 | Background binaries (`wpscloudsvr`, `wpslingxi`, `wpsd`, `KPacketInstall`) |

Examples:

```bash
sudo ./dewps.sh debloat --ads --telemetry --ai   # nothing useful lost
sudo ./dewps.sh debloat --cloud --cef            # extra disk/RAM savings
sudo ./dewps.sh debloat                          # all groups
```

Local features are never touched: editing/reading Writer/Spreadsheets/
Presentation/PDF, open/save of `docx`/`xlsx`/`pptx`/`pdf`/`ofd`, printing,
formulas, charts, Power Query, local search index, barcode/QR tools.

## Commands

| Command | Privilege | Effect |
| :--- | :---: | :--- |
| `debloat [--telemetry --ads --cloud --cef --ai --daemons]` | sudo | Disable the selected groups (all when none given) |
| `restore` | sudo | Restore addons/binaries to factory state |
| `hosts`, `hosts-remove` | sudo | Block/remove 570 telemetry/cloud domains in `/etc/hosts` |
| `kill` | user | Terminate running daemons and CEF processes |
| `status` | user | Per-group active/disabled counts, hosts state, running processes |
| `version`, `help` | user | Version, usage |

`hosts` is optional and separate: the addon groups already cut the parts that
phone home; the DNS block also makes login/cloud unreachable.

## Revert

```bash
sudo ./dewps.sh restore        # addons + binaries
sudo ./dewps.sh hosts-remove   # /etc/hosts
```

Backup: `/etc/hosts.dewps-backup`.

## Files touched

| Command | Writes |
| :--- | :--- |
| `debloat` | renames/stubs under `/usr/lib/office6`; audit log in `~/.config/dewps` |
| `hosts` | `/etc/hosts` block (+ `/etc/hosts.dewps-backup`) |

## Limitations

- Package updates restore WPS files; re-run `debloat` afterwards.
- `/etc/hosts` is bypassed by DoH, proxies, or hardcoded IPs.
- Group classification is static; vendor renames require updates.
- This is not a privacy/security sandbox. If you need process isolation or
  credential masking, use an open-source office suite instead.
- Tested on Arch/CachyOS with `wps-office-cn` 12.1.2.28080-1. Use at your own
  risk.

## Docs

[SPEC.md](SPEC.md) · [ROADMAP.md](ROADMAP.md) · [TASKS.md](TASKS.md) · [AGENTS.md](AGENTS.md)

MIT — [KabosuNeko](https://github.com/KabosuNeko)
