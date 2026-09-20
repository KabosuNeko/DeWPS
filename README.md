# DeWPS

Debloater for WPS Office CN (`wps-office-cn`) on Arch Linux: disable the addons
you do not need (telemetry, ads, cloud, embedded browser, AI) and optionally
block telemetry domains. Everything is reversible: addons are renamed to
`.disabled`, daemons are replaced with `exit 0` stubs, and `/etc/hosts` has a
backup and a removal command. Nothing is installed and nothing is written
outside `/usr/lib/office6` and `/etc/hosts`.

## Run

Pipe straight to bash; nothing is saved. `-s --` forwards the arguments after
the URL. Local autosave/crash recovery is kept in every profile; only
login/cloud is given up from profile 2 onward.

**0. Inspect** — read-only, changes nothing:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | bash -s -- status
```

**1. Daily (recommended)** — removes ads, tips, stores, tracking and AI; keeps
login, cloud, sync:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat --ads --telemetry --ai
```

**2. No cloud** — also removes login, WPS Cloud drive/sync, docer and online
templates; keeps editing, Power Query, local search, local autosave:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat --ads --telemetry --cloud --ai
```

**3. Max debloat** — every group:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat
```

**4. Max + DNS block** — profile 3, then sinkhole 570 telemetry/cloud domains
(this also makes any remaining online endpoint, including login, unreachable):

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- hosts
```

Revert at any point:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- restore
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- hosts-remove
```

Replace `main` with a commit SHA for reproducible code. Prefer a file?
`curl -fsSLO <url> && chmod +x dewps.sh`. After each WPS package update, re-run
your profile (package updates restore files, not your `/etc/hosts`).

## Groups

Fine-grained alternative to the profiles:

| Group | Addons | What it covers |
| :--- | ---: | :--- |
| `--telemetry` | 18 | Feedback, reporting, config-push and tracking SDKs (`kfeedback`, `kdcsdk`, `kdomainservice`, `kentrycontrol`, `kapmsdk`) |
| `--ads` | 18 | Tips, notifications, message/push SDKs, stores (`kskincenter`, `kmulticatalog`), VIP promos |
| `--cloud` | 49 | Cloud drive, docer/KDocs, sharing, account (`qing`, `yunbox`, `kclouddocs`, `knewdocs`, `knewshare`, `kdocer*`), online fonts, OCR/translate/help panels |
| `--ai` | 44 | AI/Copilot features (writing, formula, PDF AI, spreadsheet AI, translation/OCR AI) |
| `--daemons` | 4 | Background binaries (`wpscloudsvr`, `wpslingxi`, `wpsd`, `KPacketInstall`) |

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat --ads --ai
```

`debloat` without groups disables all of them.

The web shell, embedded browser and runtime infrastructure (`kstartpage`,
`kpromewebapp`, `cef`, `kpluginconfigcenter`, `knetwork`, `kccsdk`, plugin
manager...) are **never touched**: WPS CN boots into that shell, and removing it
leaves a blank window. They are not part of any group.

Local features are never touched: editing/reading Writer/Spreadsheets/Presentation/PDF, open/save of
`docx`/`xlsx`/`pptx`/`pdf`/`ofd`, printing, formulas, charts, Power Query, local
search index, barcode/QR tools.

## Commands

| Command | Privilege | Effect (and what it writes) |
| :--- | :---: | :--- |
| `debloat [--telemetry --ads --cloud --ai --daemons]` | sudo | Rename the selected groups to `.disabled` and stub daemons. All groups when no flag is given |
| `restore` | sudo | Restore addons/binaries to factory state |
| `hosts` | sudo | Block 570 telemetry/cloud domains in `/etc/hosts` (also blocks login/cloud); backup at `/etc/hosts.dewps-backup` |
| `hosts-remove` | sudo | Remove the `/etc/hosts` block |
| `kill` | user | Terminate running daemons and CEF processes |
| `status` | user | Per-group active/disabled counts, hosts state, running processes |
| `version`, `help` | user | Version, usage |

The DNS block also prevents hangs: when a WPS promo/CDN endpoint is unreachable,
the web shell can wait forever on the request; `0.0.0.0` makes it fail instantly.
Remove the block with `hosts-remove` if you need WPS online features and the
endpoints are reachable.

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
