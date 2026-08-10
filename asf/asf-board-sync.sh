#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — ASF Board Minutes Sync
# =============================================================================
# Fetches ASF Board meeting minutes (plaintext) and caches them locally.
# Board minutes are the primary institutional signal for ASF governance.
#
# Data source:
#   https://www.apache.org/foundation/records/minutes/<YEAR>/board_minutes_<YYYY>_<MM>_<DD>.txt
# Board meets monthly (1st Monday of each month).
#
# Usage:
#   asf-board-sync.sh --status     Show cached minutes
#   asf-board-sync.sh --sync       Fetch latest minutes
#   asf-board-sync.sh --sync-all   Fetch all available years
#
# Cache layout:
#   data/asf-board/board_minutes_<YYYY>_<MM>_<DD>.txt
#   data/asf-board/latest.txt (symlink to most recent)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/asf-board"
MINUTES_BASE="https://www.apache.org/foundation/records/minutes"
TIMEOUT=15

log() { echo "[$(date +%H:%M:%S)] $*"; }
mkdir -p "${DATA_DIR}"

# Fetch board minutes index for a given year
fetch_year_index() {
    local year="$1"
    local url="${MINUTES_BASE}/${year}/"
    log "Fetching index: ${url}"
    curl -sL --max-time "$TIMEOUT" "$url" 2>/dev/null
}

# Extract minute filenames from year index HTML
extract_minutes_files() {
    year="$1"
    local html
    html=$(fetch_year_index "$year")
    echo "$html" | grep -oP 'board_minutes_\d{4}_\d{2}_\d{2}\.txt' | sort -u
}

do_sync() {
    # Default: sync current year
    local year="${1:-$(date +%Y)}"
    local files
    files=$(extract_minutes_files "$year")

    if [[ -z "$files" ]]; then
        log "No minutes found for ${year}"
        return 1
    fi

    local count=0
    while IFS= read -r fname; do
        [[ -z "$fname" ]] && continue
        local out="${DATA_DIR}/${fname}"
        local url="${MINUTES_BASE}/${year}/${fname}"

        if [[ -f "$out" ]]; then
            log "  (cached) ${fname}"
            continue
        fi

        log "  Fetching: ${fname}"
        if curl -sL --max-time "$TIMEOUT" -o "$out" "$url" 2>/dev/null; then
            local lines
            lines=$(wc -l < "$out")
            log "    ${lines} lines cached"
            count=$((count + 1))
        else
            log "    FAILED"
        fi
    done <<< "$files"

    # Update latest symlink
    local latest
    latest=$(ls -1t "${DATA_DIR}/"board_minutes_*.txt 2>/dev/null | head -1)
    if [[ -n "$latest" ]]; then
        ln -sf "$(basename "$latest")" "${DATA_DIR}/latest.txt"
    fi

    log "Synced ${count} new minutes for ${year}"
}

do_sync_all() {
    for year in $(seq 2020 2026); do
        do_sync "$year"
    done
}

do_status() {
    echo ""
    echo "=== ASF Board Minutes Cache ==="
    echo ""
    local files
    files=$(ls -1 "${DATA_DIR}/"board_minutes_*.txt 2>/dev/null || true)
    if [[ -z "$files" ]]; then
        echo "  (empty)"
        return
    fi

    local total=$(echo "$files" | wc -l)
    echo "  Total cached: ${total}"
    echo ""

    echo "$files" | sort -r | head -12 | while IFS= read -r f; do
        local fname=$(basename "$f")
        local lines=$(wc -l < "$f")
        local date_cached=$(date -r "$f" "+%m-%d %H:%M" 2>/dev/null || echo "?")
        printf "  %-40s %4s lines  cached: %s\n" "$fname" "$lines" "$date_cached"
    done
    echo ""
}

main() {
    local action="${1:-}"
    case "$action" in
        --status)     do_status ;;
        --sync)       do_sync "${2:-$(date +%Y)}" ;;
        --sync-all)   do_sync_all ;;
        *)            echo "Usage: $0 {--status|--sync [YEAR]|--sync-all}"; exit 1 ;;
    esac
}

main "$@"
