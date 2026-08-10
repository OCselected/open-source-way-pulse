#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Homebrew Community Discussions Sync
# =============================================================================
# Homebrew's "brew.guide incident" (2021) is the canonical case of governance
# failure and institutional reconstruction. The community now uses GitHub
# Discussions for policy proposals and voting.
#
# Data source: GitHub API /repos/Homebrew/discussions/discussions
# Note: unauthenticated API is rate-limited (60 req/hr) and default sort
# is oldest-first. We use the issue-search API for recency.
#
# Usage:
#   homebrew-sync.sh --status
#   homebrew-sync.sh --sync
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/homebrew-discussions"
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

do_sync() {
    local out="${DATA_DIR}/discussions-${TODAY}.json"
    if [[ -f "$out" ]]; then
        log "(cached) discussions-${TODAY}.json"
        return
    fi
    log "Fetching Homebrew discussions (latest 30)..."
    # Use search API for recency (discussions are issues under the hood)
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' \
        'https://api.github.com/search/issues?q=repo:Homebrew/brew+label:discussion&sort:created&order:desc&per_page=30' \
        -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

do_status() {
    echo ""
    echo "=== Homebrew Discussions Cache ==="
    echo ""
    local total
    total=$(ls -1 "${DATA_DIR}/"* 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    ls -1t "${DATA_DIR}/"* 2>/dev/null | head -5 | while read -r f; do
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
        --sync)       do_sync ;;
        *)            echo "Usage: $0 {--status|--sync}"; exit 1 ;;
    esac
}

main "$@"