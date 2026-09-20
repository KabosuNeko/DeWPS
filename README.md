# DeWPS

Debloater for WPS Office CN (`wps-office-cn`) on Arch Linux: disable the addons
you do not need (telemetry, ads, AI) and optionally block telemetry domains.
Everything is reversible: addons are renamed to `.disabled` and `/etc/hosts` has
a backup and a removal command. Nothing is installed and nothing is written
outside `/usr/lib/office6` and `/etc/hosts`.

Cloud, the web shell/browser and the background daemons are **never touched**:
WPS CN boots into a Prometheus web shell that needs them, and removing any of
them leaves a blank window or breaks startup. They are excluded from every
group by design.

## Run

Pipe straight to bash; nothing is saved. `-s --` forwards the arguments after
the URL.

**0. Inspect** — read-only, changes nothing:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | bash -s -- status
```

**1. Daily (recommended)** — removes ads, tips, stores, tracking and AI; keeps
login, cloud and every local feature:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat --ads --telemetry --ai
```

**2. AI only** — just the Copilot/assistant addons:

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat --ai
```

**3. Everything managed** — telemetry + ads + AI (same as profile 1 without
listing groups):

```bash
curl -fsSL https://raw.githubusercontent.com/KabosuNeko/DeWPS/main/dewps.sh | sudo bash -s -- debloat
```

Optional DNS block (also prevents hangs when a WPS promo/CDN endpoint is
unreachable; it blocks login/cloud domains too):

```bash
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

| Group | Addons | What it covers |
| :--- | ---: | :--- |
| `--telemetry` | 18 | Feedback, reporting, config-push and tracking SDKs (`kfeedback`, `kdcsdk`, `kdomainservice`, `kentrycontrol`, `kapmsdk`) |
| `--ads` | 18 | Tips, notifications, message/push SDKs, stores (`kskincenter`, `kmulticatalog`), VIP promos |
| `--ai` | 44 | AI/Copilot features (writing, formula, PDF AI, spreadsheet AI, translation/OCR AI) |

`debloat` without groups disables all of them. Addons never touched: cloud
drive/login (`qing`, `yunbox`, `kclouddocs`, `kdocer*`), the web shell and
browser (`cef`, `kcef`, `kstartpage`, `kpromewebapp`, `kpluginconfigcenter`),
and the background daemons (`wpscloudsvr`, `wpslingxi`, `wpsd`,
`KPacketInstall`).

Local features are never touched: editing/reading Writer/Spreadsheets/
Presentation/PDF, open/save of `docx`/`xlsx`/`pptx`/`pdf`/`ofd`, printing,
formulas, charts, Power Query, local search index, barcode/QR tools.

## Commands

| Command | Privilege | Effect (and what it writes) |
| :--- | :---: | :--- |
| `debloat [--telemetry --ads --ai]` | sudo | Rename the selected groups to `.disabled`. All groups when no flag is given |
| `restore` | sudo | Restore all disabled addons to factory state |
| `hosts` | sudo | Block 570 telemetry/cloud domains in `/etc/hosts` (also blocks login/cloud); backup at `/etc/hosts.dewps-backup` |
| `hosts-remove` | sudo | Remove the `/etc/hosts` block |
| `status` | user | Per-group active/disabled counts, hosts state |
| `version`, `help` | user | Version, usage |

The DNS block also prevents hangs: when a WPS promo/CDN endpoint is unreachable,
the web shell can wait forever on the request; `0.0.0.0` makes it fail instantly.
Remove the block with `hosts-remove` if you need WPS online features and the
endpoints are reachable.

## Limitations

- `/etc/hosts` is bypassed by DoH, proxies, or hardcoded IPs.
- Group classification is static; vendor renames require updates.
- This is not a privacy/security sandbox, and it deliberately keeps the cloud
  and daemon stack. If you need process isolation or credential masking, use an
  open-source office suite instead.
- Tested on Arch/CachyOS with `wps-office-cn` 12.1.2.28080-1. Use at your own
  risk.

## Docs

[SPEC.md](SPEC.md) · [ROADMAP.md](ROADMAP.md) · [TASKS.md](TASKS.md) · [AGENTS.md](AGENTS.md)

MIT — [KabosuNeko](https://github.com/KabosuNeko)
