#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — FFmpeg Development Mailing List Sync
# =============================================================================
# FFmpeg is the canonical "pure community governance" project — no foundation,
# no corporate controller, just a mailing list and a Git repo.
#
# lore.kernel.org has Anubis bot protection (JS challenge), so we use
# ffmpeg.org pipermail HTML archives + downloadable .txt.gz mbox files.
# Note: pipermail archive has a gap (last updated 2025-08). marc.info is
# the fallback for more recent threads.
#
# Cache:
#   data/ffmpeg-dev/pipermail-<YYYY-MM>-thread.html
#   data/ffmpeg-dev/pipermail-<YYYY-MM>.txt.gz  (mbox download)
#   data/ffmpeg-dev/marc-recent-<YYYY-MM-DD>.html
#
# Usage:
#   ffmpeg-sync.sh --status
#   ffmpeg-sync.sh --sync              Sync current month
#   ffmpeg-sync.sh --sync 2025-08      Sync specific month
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/ffmpeg-dev"
PIPERMAIL="https://ffmpeg.org/pipermail/ffmpeg-devel"
MARC_URL="https://marc.info/?l=ffmpeg-devel&r=1&w=2"
TIMEOUT=25

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }
retry() {
    local cmd="$@"
    local a=0
    while [[ $a -lt 3 ]]; do
        if eval "$cmd" 2>/dev/null; then return 0; fi
        a=$((a+1)); sleep $((a*a))
    done
    return 1
}

do_sync_month() {
    local ym="${1:-$(date +%Y-%m)}"
    local thread_out="${DATA_DIR}/pipermail-${ym}-thread.html"
    local mbox_out="${DATA_DIR}/pipermail-${ym}.txt.gz"

    # Thread index (HTML)
    if [[ ! -f "$thread_out" ]]; then
        log "Fetching ffmpeg-devel thread index for ${ym}..."
        retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' '${PIPERMAIL}/${ym}/thread.html' -o '$thread_out'" \
            && log "  Thread index saved" || log "  Thread index FAILED (maybe no data for ${ym})"
    else
        log "(cached) thread index ${ym}"
    fi

    # Downloadable mbox (gzip)
    if [[ ! -f "$mbox_out" ]]; then
        log "Fetching ffmpeg-devel mbox for ${ym}..."
        retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' '${PIPERMAIL}/${ym}.txt.gz' -o '$mbox_out'" \
            && log "  Mbox saved" || log "  Mbox FAILED"
    else
        log "(cached) mbox ${ym}"
    fi
}

do_sync_marc() {
    local today=$(date +%Y-%m-%d)
    local out="${DATA_DIR}/marc-recent-${today}.html"
    if [[ -f "$out" ]]; then
        log "(cached) marc recent"
        return
    fi
    log "Fetching ffmpeg-devel recent threads from marc.info..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' '${MARC_URL}' -o '$out'" \
        && log "  marc.info saved" || log "  marc.info FAILED"
}

do_status() {
    echo ""
    echo "=== FFmpeg Dev Mailing List Cache ==="
    echo ""
    local total
    total=$(ls -1 "${DATA_DIR}/"* 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    ls -1t "${DATA_DIR}/"* 2>/dev/null | head -10 | while read -r f; do
        local fname=$(basename "$f")
        local size=$(wc -c < "$f")
        printf "  %-50s %8d bytes\n" "$fname" "$size"
    done
    echo ""
}

main() {
    local action="${1:-}"
    case "$action" in
        --status)      do_status ;;
        --sync)        do_sync_month; do_sync_marc ;;
        --sync-month)  do_sync_month "${2:-$(date +%Y-%m)}" ;;
        --sync-marc)   do_sync_marc ;;
        *)             echo "Usage: $0 {--status|--sync|--sync-month <YYYY-MM>|--sync-marc}"; exit 1 ;;
    esac
}

main "$@"