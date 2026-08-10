#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — PSF Steering Council Sync
# =============================================================================
# Fetches PSF Steering Council meeting minutes from GitHub.
# These are the institutional decision log of Python governance.
#
# Data source: https://github.com/python/steering-council
#   - Minutes in docs/meetings/ directory
#   - PEP-based election records
#
# Usage:
#   psf-steering-sync.sh --status
#   psf-steering-sync.sh --sync
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/psf-steering"
REPO="python/steering-council"
BASE_API="https://api.github.com/repos/${REPO}"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=20

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

retry() {
    local cmd="$@"
    local attempt=0
    while [[ $attempt -lt 3 ]]; do
        if eval "$cmd" 2>/dev/null; then return 0; fi
        attempt=$((attempt + 1))
        sleep $((attempt * attempt))
    done
    return 1
}

do_sync_minutes() {
    local out="${DATA_DIR}/commits-${TODAY}.json"
    if [[ -f "$out" ]]; then
        log "(cached) commits-${TODAY}.json"
        return
    fi
    log "Fetching Steering Council commit log..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' '${BASE_API}/commits?per_page=30' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

do_sync_members() {
    local out="${DATA_DIR}/members-${TODAY}.json"
    if [[ -f "$out" ]]; then
        log "(cached) members"
        return
    fi
    log "Fetching Steering Council members..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' '${BASE_API}/contents/README.md' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

do_status() {
    echo ""
    echo "=== PSF Steering Council Cache ==="
    echo ""
    local total
    total=$(ls -1 "${DATA_DIR}/"* 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    ls -1t "${DATA_DIR}/"* 2>/dev/null | head -8 | while read -r f; do
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
        --sync)       do_sync_minutes; do_sync_members ;;
        *)            echo "Usage: $0 {--status|--sync}"; exit 1 ;;
    esac
}

main "$@"