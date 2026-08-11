#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — OpenSSF Institutional Signals Sync
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/openssf"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=20

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

PULSE_PROJECTS=(
    "kubernetes/kubernetes"
    "pytorch/pytorch"
    "llvm/llvm-project"
    "Homebrew/brew"
    "FFmpeg/FFmpeg"
    "vllm-project/vllm"
    "sgl-project/sglang"
)

do_scorecard() {
    local repo="$1"
    local slug=$(echo "$repo" | tr '/' '-')
    local out="${DATA_DIR}/scorecard-${slug}-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) scorecard ${repo}"; return; fi
    log "Fetching Scorecard for ${repo}..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' 'https://api.scorecard.dev/projects/github.com/${repo}' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

do_scorecard_all() {
    for repo in "${PULSE_PROJECTS[@]}"; do
        do_scorecard "$repo"
    done
}

sync_blog() {
    local out="${DATA_DIR}/blog-rss-${TODAY}.xml"
    [[ -f "$out" ]] && { log "(cached) blog RSS"; return; }
    log "Fetching OpenSSF blog RSS..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' 'https://openssf.org/feed/' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

sync_charter() {
    local out="${DATA_DIR}/charter-${TODAY}.md"
    [[ -f "$out" ]] && { log "(cached) charter"; return; }
    log "Fetching OpenSSF Technical Charter..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' 'https://raw.githubusercontent.com/ossf/community/main/CHARTER.md' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

sync_github() {
    local out="${DATA_DIR}/github-events-${TODAY}.json"
    [[ -f "$out" ]] && { log "(cached) github events"; return; }
    log "Fetching OpenSSF GitHub org events..."
    retry "curl -sL --max-time $TIMEOUT -A 'Mozilla/5.0' 'https://api.github.com/orgs/ossf/events?per_page=30' -o '$out'" \
        && log "  Saved" || log "  FAILED"
}

do_sync() {
    sync_blog
    sync_charter
    sync_github
}

do_status() {
    echo ""
    echo "=== OpenSSF Institutional Signals Cache ==="
    echo ""
    local total
    total=$(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -10 \
        | while read -r _ts fname; do
            local size=$(wc -c < "${DATA_DIR}/${fname}")
            printf "  %-50s %8d bytes\n" "$fname" "$size"
        done
    echo ""
}

main() {
    local action="${1:-}"
    case "$action" in
        --status)          do_status ;;
        --sync)            do_sync ;;
        --scorecard)       do_scorecard "${2:-}" ;;
        --scorecard-all)   do_scorecard_all ;;
        *)                 echo "Usage: $0 {--status|--sync|--scorecard <repo>|--scorecard-all}"; exit 1 ;;
    esac
}

main "$@"
