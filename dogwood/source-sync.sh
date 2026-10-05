#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Dogwood Policy (agent harness 治理语言) Institutional Sync
# Data sources:
#   - GitHub API: dogwood-policy/dogwood (reference parser/interpreter, 423★)
#   - GitHub API: dogwood-policy/dogwood-local-engine (authorization engine, 24★)
#   - Pages homepage: https://dogwood-policy.github.io/dogwood/
# Institutional framing: Kuerbis & Ghosh 论文(North #186) 制度的第一次产品化实现
#   agent harness 治理语言 —— allow/deny 时间感知策略 = Williamson 混合治理机制产品化
#   (2026-07 建仓 / 2026-08-31 local-engine 建仓 / Apache-2.0)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/dogwood"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=20
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

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

sync_github_repo() {
    local repo="$1"
    local out="${DATA_DIR}/github-${repo##*/}-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) github ${repo##*/} ${TODAY}"; return; fi
    log "Fetching GitHub ${repo}..."
    retry "curl -sL --max-time ${TIMEOUT} -A 'Mozilla/5.0' -H 'Accept: application/vnd.github+json' 'https://api.github.com/repos/${repo}' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED ${repo}"; rm -f "$out"; }
}

sync_pages() {
    local out="${DATA_DIR}/dogwood-pages-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) pages ${TODAY}"; return; fi
    # 队列所给根路径 dogwood-policy.github.io 404；正确 homepage 是 /dogwood/
    log "Fetching Dogwood Pages homepage (/dogwood/)..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://dogwood-policy.github.io/dogwood/' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== Dogwood Policy Institutional Signals Cache ==="
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
        --sync)
            sync_github_repo "dogwood-policy/dogwood"
            sync_github_repo "dogwood-policy/dogwood-local-engine"
            sync_pages
            ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"