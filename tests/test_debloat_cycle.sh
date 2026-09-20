#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2329
# Regression test: debloat -> pacman update -> debloat -> restore cycle and
# group selection. Runs on a fake tree in a temp dir; never touches the real
# WPS install.
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dewps.sh"
[[ -f "$SCRIPT" ]] || { echo "dewps.sh not found at $SCRIPT" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/dewps-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/office6/addons"

source "$SCRIPT" help >/dev/null 2>&1

OFFICE_DIR="$WORK/office6"
ADDONS_DIR="$OFFICE_DIR/addons"
need_sudo()    { :; }
check_wps_installed() { :; }
header() { :; }
log_info() { :; }; log_ok() { :; }; log_warn() { :; }; log_err() { :; }

fails=0
check() { # desc expected actual
    if [[ "$2" == "$3" ]]; then
        echo "PASS: $1"
    else
        echo "FAIL: $1 (expected [$2], got [$3])"
        fails=$((fails + 1))
    fi
}

# --- fake install ---
mkdir -p "$ADDONS_DIR"/{kfeedback,kskincenter,kwpscopilot}
echo old > "$ADDONS_DIR/kfeedback/libfeedback.so"
echo old > "$ADDONS_DIR/kskincenter/skin.so"
echo old > "$ADDONS_DIR/kwpscopilot/copilot.so"

# --- run 1: fresh debloat ---
cmd_debloat >/dev/null
check "fresh: telemetry renamed"  yes "$( [[ -d $ADDONS_DIR/kfeedback.disabled && ! -e $ADDONS_DIR/kfeedback ]] && echo yes || echo no )"
check "fresh: ads renamed"        yes "$( [[ -d $ADDONS_DIR/kskincenter.disabled ]] && echo yes || echo no )"
check "fresh: ai renamed"         yes "$( [[ -d $ADDONS_DIR/kwpscopilot.disabled ]] && echo yes || echo no )"

# --- run 2: idempotent ---
cmd_debloat >/dev/null
check "idempotent: no nesting"    no "$( [[ -e $ADDONS_DIR/kfeedback.disabled/kfeedback ]] && echo yes || echo no )"

# --- simulate pacman update ---
mkdir -p "$ADDONS_DIR/kfeedback"
echo new > "$ADDONS_DIR/kfeedback/libfeedback.so"
cmd_debloat >/dev/null
check "update: fresh addon kept as disabled" new "$(cat "$ADDONS_DIR/kfeedback.disabled/libfeedback.so" 2>/dev/null || echo missing)"
check "update: no nested dir"     no "$( [[ -e $ADDONS_DIR/kfeedback.disabled/kfeedback ]] && echo yes || echo no )"

# --- simulate update, then restore BEFORE re-debloat ---
mkdir -p "$ADDONS_DIR/kfeedback"
echo freshest > "$ADDONS_DIR/kfeedback/libfeedback.so"
cmd_restore >/dev/null
check "restore-after-update: fresh addon kept"   freshest "$(cat "$ADDONS_DIR/kfeedback/libfeedback.so")"
check "restore-after-update: no nested junk"     no "$( [[ -e $ADDONS_DIR/kfeedback/kfeedback.disabled ]] && echo yes || echo no )"

# --- group selection ---
rm -rf "$ADDONS_DIR"
mkdir -p "$ADDONS_DIR"/{kfeedback,kskincenter,kwpscopilot}
for n in kfeedback kskincenter kwpscopilot; do echo x > "$ADDONS_DIR/$n/f"; done

cmd_debloat --ads --ai >/dev/null
check "group: ads disabled"       yes "$( [[ -d $ADDONS_DIR/kskincenter.disabled ]] && echo yes || echo no )"
check "group: ai disabled"        yes "$( [[ -d $ADDONS_DIR/kwpscopilot.disabled ]] && echo yes || echo no )"
check "group: telemetry kept"     no  "$( [[ -e $ADDONS_DIR/kfeedback.disabled ]] && echo yes || echo no )"

cmd_debloat --telemetry >/dev/null
check "group: telemetry disabled" yes "$( [[ -d $ADDONS_DIR/kfeedback.disabled ]] && echo yes || echo no )"

if ( cmd_debloat --bogus ) >/dev/null 2>&1; then
    echo "FAIL: unknown group should fail"
    fails=$((fails + 1))
else
    echo "PASS: unknown group fails"
fi

if "$SCRIPT" bogus >/dev/null 2>&1; then
    echo "FAIL: unknown command should fail"
    fails=$((fails + 1))
else
    echo "PASS: unknown command fails"
fi

echo ""
echo "RESULT: $fails failure(s)"
exit "$fails"
