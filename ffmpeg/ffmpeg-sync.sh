#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — FFmpeg Institutional Signals Sync
# =============================================================================
# FFmpeg = canonical "pure community governance" — no foundation, no corporate
# controller. The pipermail archive STALLED at 2025-08 (no institutional
# maintenance), which is itself a NIE signal: without a foundation to maintain
# infrastructure, even archival decays.
#
# Signals:
#   1. Git commit history (github.com/FFmpeg/FFmpeg) — governance activity
#      (commits, authors, reviewer patterns)
#   2. Historical pipermail (up to 2025-08) — archived decision records
#   3. FFmpeg Git Web (git.ffmpeg.org) — release tags, commit stats
#
# Cache:
#   data/ffmpeg-dev/commits-<YYYY-MM-DD>.json     (recent commits)
#   data/ffmpeg-dev/atom-<YYYY-MM-DD>.xml         (feed)
#   data/ffmpeg-dev/pipermail-<YYYY-MM>-thread.html (historical)
#
# Usage:
#   ffmpeg-sync.sh --status
#   ffmpeg-sync.sh --sync            Sync git activity signals
#   ffmpeg-sync.sh --sync-archived   Fetch 2024-2025 archived mbox
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/ffmpeg-dev"
TODAY=$(date +%Y-%m-%d)
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

# Signal 1: GitHub commit activity (recent governance activity)
sync_commits() {
    local out="${DATA_DIR}/commits-${TODAY}.json"
    if [[ -f "$out" ]]; then
        log "(cached) commits-${TODAY}.json"
        return
    fi
    log "Fetching FFmpeg recent commits..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' \
        'https://api.github.com/repos/FFmpeg/FFmpeg/commits?per_page=30' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

# Signal 2: Atom feed (commit timeline)
sync_atom() {
    local out="${DATA_DIR}/atom-${TODAY}.xml"
    if [[ -f "$out" ]]; then
        log "(cached) atom feed"
        return
    fi
    log "Fetching FFmpeg commit atom feed..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' \
        'https://github.com/FFmpeg/FFmpeg/commits/master.atom' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

# Signal 3: Historical pipermail archive (2024-01 to 2025-08)
sync_archived() {
    log "Fetching historical FFmpeg pipermail archives..."
    local YEAR_MONTHS=(
        "2025-January" "2025-February" "2025-March" "2025-April"
        "2025-May" "2025-June" "2025-July" "2025-August"
    )
    for ym in "${YEAR_MONTHS[@]}"; do
        local out="${DATA_DIR}/pipermail-${ym}-thread.html"
        if [[ -f "$out" ]]; then
            log "  (cached) ${ym}"
            continue
        fi
        # Only fetch if server returns 200 (not 404)
        local code
        code=$(curl -sI --max-time 10 -A 'Mozilla/5.0' \
            "https://ffmpeg.org/pipermail/ffmpeg-devel/${ym}/thread.html" 2>&1 | head -1)
        if echo "$code" | grep -q "200"; then
            curl -sL --max-time "$TIMEOUT" -A 'Mozilla/5.0' \
                "https://ffmpeg.org/pipermail/ffmpeg-devel/${ym}/thread.html" -o "$out" \
                && log "  ${ym}: saved" || log "  ${ym}: FAILED"
        else
            log "  ${ym}: 404 (not archived)"
        fi
    done
}

do_sync() {
    sync_commits
    sync_atom
}

do_status() {
    echo ""
    echo "=== FFmpeg Institutional Signals Cache ==="
    echo ""
    local total
    total=$(ls -1 "${DATA_DIR}/"* 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo "  Note: pipermail archive stalled at 2025-08 (no foundation = no maintenance)"
    echo ""
    ls -1t "${DATA_DIR}/"* 2>/dev/null | head -12 | while read -r f; do
        local fname=$(basename "$f")
        local size=$(wc -c < "$f")
        printf "  %-50s %8d bytes\n" "$fname" "$size"
    done
    echo ""
}

main() {
    local action="${1:-}"
    case "$action" in
        --status)       do_status ;;
        --sync)         do_sync ;;
        --sync-archived) sync_archived ;;
        *)              echo "Usage: $0 {--status|--sync|--sync-archived}"; exit 1 ;;
    esac
}

main "$@"