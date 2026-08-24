#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Mojo/Modular Institutional Signals Sync
# Data sources:
#   - modular.com/blog RSS (governance/license announcements, first-party)
#   - GitHub repo modular/modular metadata (repo renamed from modular/mojo 2026-08)
# Institutional framing: 大分流 2.0「特许工程代码 → FLOSS」过渡态样本
#   Mojo open-sourced 2026-08-18 under Apache-2.0 WITH LLVM-exception,
#   merge rights retained (半开源: 发布权开放、合并权保留)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/mojo"
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

sync_blog() {
    local out="${DATA_DIR}/blog-rss-${TODAY}.xml"
    if [[ -f "$out" ]]; then log "(cached) blog RSS ${TODAY}"; return; fi
    log "Fetching Modular blog RSS..."
    retry "curl -sL --max-time ${TIMEOUT} -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36' 'https://www.modular.com/blog/rss.xml' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

sync_github() {
    local out="${DATA_DIR}/github-repo-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) github repo ${TODAY}"; return; fi
    log "Fetching GitHub modular/modular (follow rename 301)..."
    # -L follows the rename redirect modular/mojo → modular/modular
    retry "curl -sL --max-time ${TIMEOUT} -A 'Mozilla/5.0' -H 'Accept: application/vnd.github+json' 'https://api.github.com/repos/modular/modular' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== Mojo/Modular Institutional Signals Cache ==="
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
        --sync)   sync_blog; sync_github ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"