#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — FINOS OSERA (金融开源安全) Institutional Signals Sync
# Data sources:
#   - https://www.finos.org/OSERA_Prospectus  (prospectus, static HTML)
#   - https://www.finos.org/news              (FINOS 新闻索引)
#   - https://www.finos.org/blog              (FINOS 社区博客)
# Institutional framing: 金融机构从开源消费者 → 维护者的制度变迁样本；
#   银行联盟安全公地（Premier 成员制）—— Ostrom 八原则在金融场景的具体化；
#   与 OpenGrid/OpenChain/OpenSSF 构成 LF 跨关键基础设施治理枢纽。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/finos-osera"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=25
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

retry() {
    local cmd="$*"
    local a=0
    while [[ $a -lt 3 ]]; do
        if eval "$cmd" 2>/dev/null; then return 0; fi
        a=$((a+1)); sleep $((a*a))
    done
    return 1
}

sync_prospectus() {
    local out="${DATA_DIR}/osera-prospectus-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) prospectus ${TODAY}"; return; fi
    log "Fetching OSERA Prospectus..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://www.finos.org/OSERA_Prospectus' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

sync_news() {
    local out="${DATA_DIR}/finos-news-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) news ${TODAY}"; return; fi
    log "Fetching finos.org/news ..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://www.finos.org/news' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

sync_blog() {
    local out="${DATA_DIR}/finos-blog-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) blog ${TODAY}"; return; fi
    log "Fetching finos.org/blog ..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://www.finos.org/blog' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== FINOS OSERA Institutional Signals Cache ==="
    echo ""
    local total
    total=$(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -10 \
        | while read -r _ts fname; do
            local size
            size=$(wc -c < "${DATA_DIR}/${fname}")
            printf "  %-55s %8d bytes\n" "$fname" "$size"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_prospectus
            sync_news
            sync_blog
            ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"
