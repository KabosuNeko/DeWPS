#!/usr/bin/env bash
#
# DeWPS — WPS Office CN Debloater
# https://github.com/KabosuNeko/DeWPS
#
# All changes are reversible: addons are renamed to .disabled and binaries are
# replaced with no-op stubs. Run 'dewps help' for the command list.

set -euo pipefail

OFFICE_DIR="/usr/lib/office6"
ADDONS_DIR="${OFFICE_DIR}/addons"
HOSTS_FILE="/etc/hosts"
HOSTS_MARKER_BEGIN="# ── DeWPS BEGIN ──"
HOSTS_MARKER_END="# ── DeWPS END ──"
VERSION="1.1.0"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

# Addon groups used by `debloat` (select with --telemetry --ads --cloud --ai)
BLOAT_TELEMETRY=(
    kfeedback
    kfeedbackcmds
    kdevops
    secanalyze
    kdcsdk
    kwpskdc
    kdomainservice
    konlinefileconfig
    kconfigcentersdk
    kentrycontrol
    kappconnectivity
    ksoftbus
    ksoftbuscore
    ksoftbusproxy
    kaccessbase
    kapmsdk
    kfpccomb
    kwebeditioninfo
)

BLOAT_ADS=(
    ktoast
    kwhatsnew
    ktipsmanager
    ktipsclientmanager
    messagepush
    cloudpushsdk
    kmessagecentersdk
    kmessagecentersrv
    kwebmessagecenterpanel
    khoneycomb
    kspostpay
    kappcenter
    kskincenter
    kmultcatalog
    kwpsofficial
    wpsdoccenter
    kprivilegeresource
    kprivilegerespack
)



# AI/Copilot features — safe to remove
BLOAT_AI=(
    kwpscopilot
    kwppcopilot
    ketcopilot
    kpdfcopilot
    ktaskpanelcopilot
    kcopilotentry
    kcopilotentrylite
    kcopilotsdk
    kcopilotjsapi
    kwpsaigc
    kwpsaitypeset
    kwpsaiwritingsuggest
    kwpsaifindreplace
    kwpsaidoc2ppt
    kwpsaitablestyle
    kpubaigcbox
    kpdfaigcbox
    kpdfaisearch
    kpdfaireference
    kwebaiaccompanywrite
    kwebaiglossary
    kwebaihistorysession
    kwebaipdfinsight
    kwebaireference
    kwebaireport
    kwebwpscopilot
    kaiaccompanywrite
    kaichatclient
    kaipushsdk
    kaiwpp
    kproofread
    kwebsuwellaidocument
    kwebwpsainewfilepanel
    kwebwpsdoccomposing
    kwebwpsdocofficial
    kwebwpsinstructioncenter
    kwebwpscustomtemplateconf
    karticlewebcloudsummary
    kwpslingxi
    # Audit 2026-09: ET AI features calling kvas-api / copilot-api
    ketaiconditionalformat
    ketaidataanalysis
    ketaiselectcontent
    ketaitoolbox
    kwebmultformulamatch
)

# Background binaries to disable
# Background binaries to disable. Only cloud/AI/installer daemons belong here;
# local-only services (wpsquery = Power Query engine, EverythingDaemon = search
# index) are intentionally left untouched.

# Telemetry domains to block
TELEMETRY_DOMAINS=(
    # WPS CN core telemetry
    home.wps.cn
    hd.wps.cn
    365.wps.cn
    q.wps.cn
    snauth.wps.cn
    kuc.wps.cn
    p.kdocs.cn
    modouks.wps.cn
    store.kdocs.cn
    yun-api.wps.cn
    plussvr.wps.cn
    openapi.wps.cn
    vasvip-pub.wpscdn.cn
    le.wps.cn
    vas2t-api.wps.cn
    airsheet.wps.cn
    securitydoc.kdocs.cn
    docerserver.wps.cn
    open.wps.cn
    vas2c-spa.wps.cn
    lingxi.wps.cn
    copilot.wps.cn
    cc.wps.cn
    notebox.wps.cn
    tastenew.wps.cn
    ppt.wps.cn
    aippt.wps.cn
    v.wps.cn
    365.kdocs.cn
    photo.wps.cn
    cowork.wps.cn
    cowork.kdocs.cn
    aipaper.wps.cn
    agentsai.wps.cn
    analyst.wps.cn
    suji.wps.cn
    personal-web.wps.cn
    ets-monitor.docer.wps.cn
    # WPS CN docer
    clientweb.docer.wps.cn
    clientweb-bak.wps.cn
    caiji-web.docer.wps.cn
    education-web.docer.wps.cn
    resume-web.docer.wps.cn
    ds.docer.wps.cn
    # WPS international (not needed for CN)
    feedback.wps.com
    template.wps.com
    academy.wps.com
    activity.wps.com
    www.wps.com
    docs.wps.com
    us.docs.wps.com
    sg.docs.wps.com
    eu.docs.wps.com
    ru.docs.wps.com
    in.docs.wps.com
    jp.docs.wps.com
    esign.wps.com
    smartform.wps.com
    wdl1.pcfg.cache.wpscdn.com
    jump.wps.com
    account.wps.com
    ovs-activity.wps.com
    clientweb.docer.wps.com
    aibeautify.wps.com
    intl-ippt.wps.com
    help.wps.com
    pdf.wps.com
    aislides.wps.com
    app.wps.com
    ds.cache.wpscdn.com
    # CDN / local API
    global.local.wps.cn
    personal.local.wps.cn
    personal.wpscdn.cn
    global-volc.wpscdn.cn
    wpsaigc.local.wps.cn
    kuc.local.wps.cn
    et.local.wps.cn
    aidocs.local.wps.cn
    # Analytics
    api.growingio.com

    # Audit 2026-09: endpoints found in office6 core libraries and addons
    # (tracking/identity, cloud/login, docer, kdocs, CDN, third-party analytics)
    account.kdocs.cn
    aidocs.wps.cn
    ai-generator-dimension.wpscdn.cn
    api.ai.wps.cn
    api.kdocs.cn
    api-kos.wps.cn
    api.vas.wpscdn.cn
    api.wps.cn
    chn.docer.com
    client-mall.docer.wps.cn
    cloudcdn.wpscdn.cn
    clouddoc.wps.cn
    cloud.wpscdn.com
    cloud.wps.com
    copilot-api.kdocs.cn
    copilot-api.wps.cn
    dce-gateway.docer.wps.cn
    deviceapi.wps.cn
    docer-api.kdocs.cn
    docer-api.wps.cn
    docer.com
    docer-files.wpscdn.cn
    docer.kdocs.cn
    docer-ks3.wpscdn.cn
    docer-mo.kdocs.cn
    docerserver.kdocs.cn
    docer-vcl.kdocs.cn
    docs-dapi.wps.cn
    docteamapi.wps.cn
    download.docer.wps.cn
    drive.kdocs.cn
    drive.wps.com
    d.wps.cn
    dwz.wps.cn
    easy.wps.cn
    entry.wpscdn.com
    f-api.wps.cn
    firebaseperusertopics-pa.googleapis.com
    f.kdocs.cn
    global-entry-conf.wpscdn.cn
    global-entry-conf.wpscdn.com
    global-hwc.wpscdn.cn
    global-ksyun.wpscdn.cn
    global-static.wpscdn.com
    google-analytics.com
    honeycomb-sr-ai.wpscdn.cn
    honeycomb-sr-public.wpscdn.cn
    i18n.wps.cn
    ic.wps.cn
    img1.file.cache.docer.com
    img1.template.cache.wps.cn
    img2.file.cache.docer.com
    img2.template.cache.wps.cn
    img7.file.cache.docer.com
    img8.file.cache.docer.com
    info.kingsoftstore.com
    info.wps.cn
    insight.wps.cn
    ippt.kdocs.cn
    ippt.wps.cn
    jump.wps.cn
    kbee.wps.cn
    kdocs-om.wpscdn.cn
    kdocs-vas.wpscdn.cn
    kmon.kdocs.cn
    koa.wps.cn
    kspdf-api.kdocs.cn
    kspdf-api.wps.cn
    kvas-api.wps.cn
    library-wps-third.docer.wps.cn
    logger.wps.cn
    lrcresource.wps.cn
    mission.u.wps.cn
    msgcenter.kdocs.cn
    msgevent.wps.cn
    msgpush.wps.cn
    notice.wps.cn
    openapp.wpscdn.cn
    order.docer.wps.cn
    o.wpsgo.com
    p2.kdvas.wpscdn.cn
    pay.kdocs.cn
    pay.wps.cn
    pcfg.wps.cn
    pendant.docer.wps.cn
    personal-ai-bus.kdocs.cn
    personal-ai-bus.wps.cn
    personal-volc.wpscdn.cn
    pfe.wps.cn
    plus.kdocs.cn
    plussvr.kdocs.cn
    portal.wps.cn
    preview-font.docer.wps.cn
    pub-api.kdocs.cn
    qdyn.kingsoftstore.com
    qinfo.kingsoftstore.com
    qing.wps.cn
    qpush.wps.cn
    qpush.wps.com
    qr.wps.cn
    recom.docer.wps.cn
    s1.vas.wpscdn.cn
    sharefolder.wps.cn
    skin.docer.wps.cn
    structure-extractor-cert-cdn.wpscdn.com
    svc-modou.kdocs.cn
    svc.modou.wps.cn
    sys.wps.cn
    template-test.wps.com
    tiance.kdocs.cn
    tiance.wpscdn.cn
    tiance.wps.cn
    tj.psvr.wps.cn
    todos-api.kdocs.cn
    todos-api.wps.cn
    t.wps.cn
    uc.wps.com
    userinfo.docer.wps.cn
    vaf.wps.cn
    vas2t.wpscdn.cn
    vas-api.kdocs.cn
    vas.wps.cn
    vipapi.kdocs.cn
    volcengine-kdocs-cache.wpscdn.cn
    wdl1.file.cache.docer.com
    web1.file.cache.docer.com
    web.docer.wpscdn.cn
    webres.docer.wps.cn
    wps.docer.wps.cn
    wpsservice-page.wps.cn
    wwo.wps.cn
    www.docer.com
    wxbmc.kdocs.cn
    wxbmc.wps.cn
    zh-hant.wps.com
)

log_info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_err()     { echo -e "${RED}[ERR]${RESET}  $*"; }

header() {
    echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}\n"
}




check_wps_installed() {
    if [[ ! -d "$OFFICE_DIR" ]]; then
        log_err "WPS Office not found at $OFFICE_DIR"
        exit 1
    fi
}

need_sudo() {
    if [[ $EUID -ne 0 ]]; then
        log_err "This command requires root privileges. Run with: sudo dewps $*"
        exit 1
    fi
}


_count_addons() {
    # addon names as args -> "active disabled"
    local addon active=0 disabled=0

    for addon in "$@"; do
        if [[ -d "${ADDONS_DIR}/${addon}" ]]; then
            active=$((active + 1))
        elif [[ -d "${ADDONS_DIR}/${addon}.disabled" ]]; then
            disabled=$((disabled + 1))
        fi
    done
    printf '%s %s\n' "$active" "$disabled"
}



_disable_addons() {
    # $1 = label; remaining args = addon names
    local label=$1
    local disabled=0
    local skipped=0
    local addon addon_path disabled_path

    for addon in "${@:2}"; do
        addon_path="${ADDONS_DIR}/${addon}"
        disabled_path="${addon_path}.disabled"

        if [[ -d "$addon_path" ]]; then
            # A pacman update reinstalls the addon while the stale .disabled
            # rename may still exist. Keep the fresh copy as the disabled one.
            if [[ -e "$disabled_path" ]]; then
                rm -rf "$disabled_path"
            fi
            mv "$addon_path" "$disabled_path"
            disabled=$((disabled + 1))
        else
            skipped=$((skipped + 1))
        fi
    done

    log_ok "${label}: disabled ${disabled} addons (${skipped} already disabled/missing)"
}


cmd_debloat() {
    local groups=()
    local arg group
    if [[ $# -eq 0 ]]; then
        groups=(telemetry ads ai)
    else
        for arg in "$@"; do
            case "$arg" in
                --telemetry|--ads|--ai) groups+=("${arg#--}") ;;
                *) log_err "Unknown debloat group: $arg (use --telemetry --ads --cloud --ai --daemons)"; exit 1 ;;
            esac
        done
    fi

    need_sudo debloat
    check_wps_installed
    header "DeWPS Debloat"

    for group in "${groups[@]}"; do
        case "$group" in
            telemetry) _disable_addons "Telemetry" "${BLOAT_TELEMETRY[@]}" ;;
            ads)       _disable_addons "Ads/Promotions" "${BLOAT_ADS[@]}" ;;
            ai)        _disable_addons "AI/Copilot" "${BLOAT_AI[@]}" ;;
        esac
    done

    echo ""
    log_ok "Debloat complete!"
    log_info "Run ${CYAN}dewps kill${RESET} to stop any running WPS background processes"
    log_info "Run ${CYAN}sudo dewps hosts${RESET} to also block telemetry domains"
    log_info "Run ${CYAN}sudo dewps restore${RESET} to undo all changes"
    echo ""
}

cmd_restore() {
    need_sudo restore
    check_wps_installed
    header "DeWPS — Restore All Components"

    local restored=0
    local addon_dir original

    for addon_dir in "${ADDONS_DIR}"/*.disabled; do
        if [[ -d "$addon_dir" ]]; then
            original="${addon_dir%.disabled}"
            if [[ -e "$original" ]]; then
                # Fresh package copy already present (pacman update): drop stale rename
                rm -rf "$addon_dir"
            else
                mv "$addon_dir" "$original"
            fi
            restored=$((restored + 1))
        fi
    done

    echo ""
    log_ok "Restored ${restored} components"
    log_info "WPS Office is back to original state"
    echo ""
}


cmd_hosts() {
    need_sudo hosts
    header "DeWPS — Block Telemetry Domains"

    if grep -q "$HOSTS_MARKER_BEGIN" "$HOSTS_FILE" 2>/dev/null; then
        log_warn "WPS telemetry domains are already blocked in /etc/hosts"
        log_info "Run ${CYAN}sudo dewps hosts-remove${RESET} to remove them first"
        return 0
    fi

    cp "$HOSTS_FILE" "${HOSTS_FILE}.dewps-backup"
    log_info "Backed up /etc/hosts to /etc/hosts.dewps-backup"

    local -A all_domains
    local d
    for d in "${TELEMETRY_DOMAINS[@]}"; do
        all_domains["$d"]=1
    done

    local kfile
    for kfile in "${ADDONS_DIR}/kblockhost/kblockhost.ini" "${ADDONS_DIR}/kblockhost.disabled/kblockhost.ini"; do
        if [[ -f "$kfile" ]]; then
            while IFS='=' read -r raw_domain _; do
                d=$(echo "$raw_domain" | tr -d ' \r\n' | sed 's/^\.//')
                local first_char="${d:0:1}"
                if [[ "$d" == *.* && ! "$d" =~ [[:space:]] && "$first_char" != "[" && "$first_char" != ";" && "$first_char" != "#" ]]; then
                    all_domains["$d"]=1
                fi
            done < "$kfile"
        fi
    done

    local sorted_domains total_domains
    sorted_domains=$(printf "%s\n" "${!all_domains[@]}" | sort -u)
    total_domains=${#all_domains[@]}

    {
        echo ""
        echo "$HOSTS_MARKER_BEGIN"
        echo "# Blocked by DeWPS v${VERSION} — $(date -Iseconds)"
        echo "# WPS Office CN telemetry, tracking, and partner domains (${total_domains} total)"
        while IFS= read -r domain; do
            [[ -n "$domain" ]] && echo "0.0.0.0 ${domain}"
        done <<< "$sorted_domains"
        echo "$HOSTS_MARKER_END"
    } >> "$HOSTS_FILE"

    log_ok "Blocked ${total_domains} telemetry domains in /etc/hosts"
    echo ""
}

cmd_hosts_remove() {
    need_sudo hosts-remove
    header "DeWPS — Unblock Telemetry Domains"

    if ! grep -q "$HOSTS_MARKER_BEGIN" "$HOSTS_FILE" 2>/dev/null; then
        log_info "No DeWPS entries found in /etc/hosts"
        return 0
    fi

    sed -i "/${HOSTS_MARKER_BEGIN}/,/${HOSTS_MARKER_END}/d" "$HOSTS_FILE"
    # Remove trailing blank line if left behind
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$HOSTS_FILE"

    log_ok "Removed WPS telemetry domain blocks from /etc/hosts"
    echo ""
}

cmd_status() {
    check_wps_installed
    header "DeWPS Status"

    local hosts_blocked=false
    if grep -q "$HOSTS_MARKER_BEGIN" "$HOSTS_FILE" 2>/dev/null; then
        hosts_blocked=true
    fi

    echo -e "  ${BOLD}Addons:${RESET}"
    local label arr active disabled
    for label in Telemetry Ads AI; do
        case "$label" in
            Telemetry) arr=("${BLOAT_TELEMETRY[@]}") ;;
            Ads)       arr=("${BLOAT_ADS[@]}") ;;
            AI)        arr=("${BLOAT_AI[@]}") ;;
        esac
        read -r active disabled < <(_count_addons "${arr[@]}")
        if [[ $active -eq 0 && $disabled -gt 0 ]]; then
            printf "    %-10s ${GREEN}%3d disabled${RESET}\n" "$label:" "$disabled"
        elif [[ $active -gt 0 ]]; then
            printf "    %-10s ${RED}%3d active${RESET}, %d disabled\n" "$label:" "$active" "$disabled"
        else
            printf "    %-10s ${DIM}none found${RESET}\n" "$label:"
        fi
    done

    echo -e "  ${BOLD}Telemetry domain blocking:${RESET}"
    if $hosts_blocked; then
        local blocked_count
        blocked_count=$(sed -n "/${HOSTS_MARKER_BEGIN}/,/${HOSTS_MARKER_END}/p" "$HOSTS_FILE" 2>/dev/null | grep -c '^0.0.0.0' || true)
        echo -e "    ${GREEN}✓ Active${RESET} (${blocked_count} domains blocked in /etc/hosts)"
    else
        echo -e "    ${RED}✗ Not active${RESET} (run: sudo dewps hosts)"
    fi

    local disabled_mb
    disabled_mb=$(du -sm "${ADDONS_DIR}"/*.disabled 2>/dev/null | awk '{s+=$1} END {print s+0}')
    if [[ ${disabled_mb:-0} -gt 0 ]]; then
        echo -e "  ${BOLD}Space freed:${RESET} ${disabled_mb} MB (disabled addons)"
    fi

    echo ""
}

cmd_version() {
    echo "DeWPS v${VERSION} — WPS Office CN Debloater"
}

cmd_help() {
    echo -e "${BOLD}DeWPS${RESET} v${VERSION} — WPS Office CN Debloater"
    echo ""
    echo -e "${BOLD}USAGE:${RESET}"
    echo "    dewps debloat [groups]        Disable addon groups            ${DIM}[sudo]${RESET}"
    echo "    dewps restore                 Restore everything             ${DIM}[sudo]${RESET}"
    echo "    dewps hosts | hosts-remove    Block / unblock domains        ${DIM}[sudo]${RESET}"
    echo "    dewps status                  Show debloat state"
    echo "    dewps version | help"
    echo ""
    echo -e "${BOLD}DEBLOAT GROUPS:${RESET}"
    echo -e "    ${CYAN}--telemetry${RESET}     Feedback, reporting, config-push SDKs   (18 addons)"
    echo -e "    ${CYAN}--ads${RESET}           Tips, stores, notifications, promos   (18 addons)"
    echo -e "    ${CYAN}--ai${RESET}            AI/Copilot features                     (44 addons)"
    echo ""
    echo -e "    Without groups, ${CYAN}debloat${RESET} disables all of them."
    echo -e "    ${DIM}Cloud, the web shell/browser and the background daemons are never"
    echo -e "    touched (WPS needs them to boot).${RESET}"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo "    sudo dewps debloat --ads --telemetry --ai    # keep login/cloud"
    echo "    sudo dewps debloat --ai                      # AI only"
    echo "    sudo dewps debloat                           # everything managed"
}

main() {
    local cmd="${1:-help}"

    case "$cmd" in
        debloat)         shift; cmd_debloat "$@" ;;
        restore)         cmd_restore ;;
        hosts)           cmd_hosts ;;
        hosts-remove)    cmd_hosts_remove ;;
        status)          cmd_status ;;
        version|-v|--version) cmd_version ;;
        help|-h|--help)  cmd_help ;;
        *)
            log_err "Unknown command: ${cmd}"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
