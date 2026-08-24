#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Omarchy/Omacom Foundation Institutional Signals Sync
# Data sources:
#   - omarchy.org/news/ dated news index (static HTML, /news/YYYY/MM/slug)
#   - GitHub repo basecamp/omarchy metadata (code hosted under basecamp org;
#     omarchy/omarchy is only a profile placeholder repo)
# Institutional framing: 魅力权威基金会化 — DHH personal-brand OS → charitable
#   foundation (Omacom Foundation, $8M initial, 2026-08-21). Track whether it
#   lands in 赛博庄园 (personal veto retained) or 基金会制度化 (meritocracy).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/omarchy"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=20

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

sync_news() {
    local out="${DATA_DIR}/news-index-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) news index ${TODAY}"; return; fi
    log "Fetching omarchy.org/news/ index..."
    retry "curl -sL --max-time ${TIMEOUT} -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36' 'https://omarchy.org/news/' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

sync_github() {
    local out="${DATA_DIR}/github-repo-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) github repo ${TODAY}"; return; fi
    log "Fetching GitHub basecamp/omarchy..."
    retry "curl -sL --max-time ${TIMEOUT} -A 'Mozilla/5.0' -H 'Accept: application/vnd.github+json' 'https://api.github.com/repos/basecamp/omarchy' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== Omarchy/Omacom Foundation Institutional Signals Cache ==="
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
            printf "  %-50s %8d bytes\n" "$fname" "$size"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)   sync_news; sync_github ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"