#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — FSF/GNU Mailing List Sync
# =============================================================================
# FSF (1985) and GNU (1983) are the oldest institutional infrastructure
# in open source. Their mailing lists are the primary signal for
# "ideology-driven governance" and "institutional decay" analysis.
#
# Data sources:
#   - lists.gnu.org  (GNU Mailman) — archives for gnu-devel, fsf-users
#   - www.gnu.org/email/ — GNU project mailing list index
#   - lists.gnu.org/archive/html/<list>/  — HTML archives
#
# Key lists for institutional analysis:
#   gnu-devel@gnu.org     — GNU project development
#   fsf-users@gnu.org     — FSF community discussions
#   gnu-philosophy@gnu.org — ideological debates (high NIE value)
#
# Usage:
#   fsf-sync.sh --status
#   fsf-sync.sh --sync
#   fsf-sync.sh --sync <list-name>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/fsf"
GUNU_MAIL="https://mail.gnuserv.com"
GNU_ARCH="https://lists.gnu.org/archive/html"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=20

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# GNU mailing lists to monitor (institutional signal value)
LISTS=(
    "gnu-devel"
    "gnu-philosophy"
    "fsf-users"
)

do_sync_list() {
    local list_name="${1:-gnu-devel}"
    local today=$(date +%Y-%m-%d)
    local year_month=$(date +%Y-%m)
    local out="${DATA_DIR}/${list_name}-${year_month}-index.html"

    if [[ -f "$out" ]]; then
        log "(cached) ${list_name} ${year_month}"
        return
    fi

    log "Fetching ${list_name} archive for ${year_month}..."
    local url="${GNU_ARCH}/${list_name}/${year_month}/"
    retry_fetch() {
        local attempt=0
        while [[ $attempt -lt 3 ]]; do
            if curl -sL --max-time "$TIMEOUT" -A 'Mozilla/5.0' "$url" -o "$out" 2>/dev/null; then
                return 0
            fi
            attempt=$((attempt + 1))
            sleep $((attempt * attempt))
        done
        return 1
    }

    retry_fetch && log "  Saved (${list_name})" || log "  FAILED (${list_name})"
}

do_sync_all() {
    for lst in "${LISTS[@]}"; do
        do_sync_list "$lst"
    done

    # Also fetch the main GNU email index page for navigation
    local idx="${DATA_DIR}/gnu-email-index-${TODAY}.html"
    if [[ ! -f "$idx" ]]; then
        log "Fetching GNU email index..."
        curl -sL --max-time "$TIMEOUT" -A 'Mozilla/5.0' 'https://www.gnu.org/email/' -o "$idx" \
            && log "  GNU email index saved" || log "  Index fetch failed"
    fi
}

do_status() {
    echo ""
    echo "=== FSF/GNU Mailing List Cache ==="
    echo ""
    local total
    total=$(ls -1 "${DATA_DIR}/"* 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo "  Monitored lists: ${LISTS[*]}"
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
        --status)     do_status ;;
        --sync)       do_sync_all ;;
        --sync-list)  do_sync_list "${2:-}" ;;
        *)            echo "Usage: $0 {--status|--sync|--sync-list <name>}"; exit 1 ;;
    esac
}

main "$@"