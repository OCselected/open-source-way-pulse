#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — PSF PEP Stream Sync
# =============================================================================
# Fetches PEP index page and extracts new/recent PEPs.
# PEPs are the formal governance proposals of the Python community — the
# closest thing to a constitutional amendment process in open source.
#
# Data source: https://peps.python.org/  (index page with all PEPs)
#               https://peps.python.org/pep-XXXX.html (individual PEP pages)
#
# Cache:
#   data/psf-peps/index-<YYYY-MM-DD>.html
#   data/psf-peps/latest-index.html
#   data/psf-peps/pep-<num>-<YYYY-MM-DD>.md  (per-PEP markdown)
#
# Usage:
#   pep-sync.sh --status
#   pep-sync.sh --sync            Fetch fresh index
#   pep-sync.sh --sync-PEP 8107   Fetch one PEP page
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/psf-peps"
PEP_BASE="https://peps.python.org"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=20

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

do_sync_index() {
    local out="${DATA_DIR}/index-${TODAY}.html"
    if [[ -f "$out" ]]; then
        log "(cached) index-${TODAY}.html"
    else
        log "Fetching PEP index..."
        curl -sL --max-time "$TIMEOUT" -A 'Mozilla/5.0' "$PEP_BASE/" -o "$out" \
            && log "  Saved (${SIZE} bytes)" || log "  FAILED"
    fi
    ln -sf "index-${TODAY}.html" "${DATA_DIR}/latest-index.html"
}

do_sync_pep() {
    local pep_num="$1"
    local pep_id=$(printf "pep-%04d" "$pep_num")
    local out="${DATA_DIR}/${pep_id}-${TODAY}.md"
    if [[ -f "$out" ]]; then
        log "(cached) ${pep_id}"
    else
        log "Fetching ${pep_id}..."
        curl -sL --max-time "$TIMEOUT" -A 'Mozilla/5.0' "${PEP_BASE}/${pep_id}.html" -o "$out" \
            && log "  Saved" || log "  FAILED"
    fi
}

do_status() {
    echo ""
    echo "=== PSF PEP Stream Cache ==="
    echo ""
    local total
    total=$(ls -1 "${DATA_DIR}/"*.md "${DATA_DIR}/"*.html 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    ls -1t "${DATA_DIR}/"*.html "${DATA_DIR}/"*.md 2>/dev/null | head -10 | while read -r f; do
        local fname=$(basename "$f")
        local size=$(wc -c < "$f")
        printf "  %-45s %8d bytes\n" "$fname" "$size"
    done
    echo ""
}

main() {
    local action="${1:-}"
    case "$action" in
        --status)     do_status ;;
        --sync)       do_sync_index ;;
        --sync-PEP)   do_sync_pep "${2:-}" ;;
        *)            echo "Usage: $0 {--status|--sync|--sync-PEP <num>}"; exit 1 ;;
    esac
}

main "$@"