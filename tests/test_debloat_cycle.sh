#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2329
# Regression test: debloat -> pacman update -> debloat -> restore cycle,
# privacy config rewrites, and change-log handling. Runs on a fake tree in
# a temp dir; never touches the real WPS install.
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dewps.sh"
[[ -f "$SCRIPT" ]] || { echo "dewps.sh not found at $SCRIPT" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/dewps-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/fakehome" "$WORK/office6/addons"

source "$SCRIPT" help >/dev/null 2>&1

OFFICE_DIR="$WORK/office6"
ADDONS_DIR="$OFFICE_DIR/addons"
get_target_home() { echo "$WORK/fakehome"; }
get_target_user() { id -un; }
need_sudo()    { :; }
check_wps_installed() { :; }
header() { :; }
cmd_kill() { :; }
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
mkdir -p "$ADDONS_DIR/cef" "$ADDONS_DIR/kwpscopilot" "$ADDONS_DIR/kccsdk" "$ADDONS_DIR/kdocerresource"
echo old > "$ADDONS_DIR/cef/libcef.so"
echo old > "$ADDONS_DIR/kwpscopilot/copilot.so"
echo old > "$ADDONS_DIR/kccsdk/cc.so"
echo old > "$ADDONS_DIR/kdocerresource/res.so"
echo real-binary > "$OFFICE_DIR/wpscloudsvr"
echo real-binary > "$OFFICE_DIR/wpsd"

# --- run 1: fresh debloat ---
cmd_debloat >/dev/null
check "fresh: cef renamed"          yes "$( [[ -d $ADDONS_DIR/cef.disabled && ! -e $ADDONS_DIR/cef ]] && echo yes || echo no )"
check "fresh: kccsdk renamed"       yes "$( [[ -d $ADDONS_DIR/kccsdk.disabled ]] && echo yes || echo no )"
check "fresh: kdocerresource renamed" yes "$( [[ -d $ADDONS_DIR/kdocerresource.disabled ]] && echo yes || echo no )"
check "fresh: wpsd stubbed"         yes "$(grep -q 'Disabled by DeWPS' "$OFFICE_DIR/wpsd" && echo yes || echo no)"
check "fresh: original preserved"   real-binary "$(cat "$OFFICE_DIR/wpsd.disabled")"

# --- run 2: idempotent ---
cmd_debloat >/dev/null
check "idempotent: no nesting"      no "$( [[ -e $ADDONS_DIR/cef.disabled/cef ]] && echo yes || echo no )"
check "idempotent: stub intact"     yes "$(grep -q 'Disabled by DeWPS' "$OFFICE_DIR/wpsd" && echo yes || echo no)"

# --- simulate pacman update ---
mkdir -p "$ADDONS_DIR/cef"
echo new > "$ADDONS_DIR/cef/libcef.so"
echo new-binary > "$OFFICE_DIR/wpsd"
cmd_debloat >/dev/null
check "update: fresh addon kept as disabled" new "$(cat "$ADDONS_DIR/cef.disabled/libcef.so" 2>/dev/null || echo missing)"
check "update: no nested dir"       no "$( [[ -e $ADDONS_DIR/cef.disabled/cef ]] && echo yes || echo no )"
check "update: new binary stubbed"  yes "$(grep -q 'Disabled by DeWPS' "$OFFICE_DIR/wpsd" && echo yes || echo no)"
check "update: new binary preserved" new-binary "$(cat "$OFFICE_DIR/wpsd.disabled")"

# --- simulate update, then restore BEFORE re-debloat ---
mkdir -p "$ADDONS_DIR/cef"
echo freshest > "$ADDONS_DIR/cef/libcef.so"
echo freshest-binary > "$OFFICE_DIR/wpsd"
cmd_restore >/dev/null
check "restore-after-update: fresh addon kept"   freshest "$(cat "$ADDONS_DIR/cef/libcef.so")"
check "restore-after-update: no nested junk"     no "$( [[ -e $ADDONS_DIR/cef/cef.disabled ]] && echo yes || echo no )"
check "restore-after-update: fresh binary kept"  freshest-binary "$(cat "$OFFICE_DIR/wpsd")"
check "restore-after-update: stale copy removed" no "$( [[ -e $OFFICE_DIR/wpsd.disabled ]] && echo yes || echo no )"

# --- group selection ---
rm -rf "$ADDONS_DIR"
mkdir -p "$ADDONS_DIR"/{kfeedback,kskincenter,kccsdk,cef,kwpscopilot}
for n in kfeedback kskincenter kccsdk cef kwpscopilot; do echo x > "$ADDONS_DIR/$n/f"; done
echo real-daemon > "$OFFICE_DIR/wpscloudsvr"

cmd_debloat --ads --ai >/dev/null
check "group: ads disabled"       yes "$( [[ -d $ADDONS_DIR/kskincenter.disabled ]] && echo yes || echo no )"
check "group: ai disabled"        yes "$( [[ -d $ADDONS_DIR/kwpscopilot.disabled ]] && echo yes || echo no )"
check "group: telemetry kept"     no  "$( [[ -e $ADDONS_DIR/kfeedback.disabled ]] && echo yes || echo no )"
check "group: cloud kept"         no  "$( [[ -e $ADDONS_DIR/kccsdk.disabled ]] && echo yes || echo no )"
check "group: cef kept"           no  "$( [[ -e $ADDONS_DIR/cef.disabled ]] && echo yes || echo no )"
check "group: daemons kept"       real-daemon "$(cat "$OFFICE_DIR/wpscloudsvr")"

cmd_debloat --telemetry --daemons >/dev/null
check "group: telemetry disabled" yes "$( [[ -d $ADDONS_DIR/kfeedback.disabled ]] && echo yes || echo no )"
check "group: daemons disabled"   yes "$(grep -q 'Disabled by DeWPS' "$OFFICE_DIR/wpscloudsvr" && echo yes || echo no)"

if ( cmd_debloat --bogus ) >/dev/null 2>&1; then
    echo "FAIL: unknown group should fail"
    fails=$((fails + 1))
else
    echo "PASS: unknown group fails"
fi

# --- unknown command exits nonzero ---
if "$SCRIPT" bogus >/dev/null 2>&1; then
    echo "FAIL: unknown command should fail"
    fails=$((fails + 1))
else
    echo "PASS: unknown command fails"
fi

echo ""
echo "RESULT: $fails failure(s)"
exit "$fails"
