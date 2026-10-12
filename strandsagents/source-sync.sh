#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Strands Labs (AWS agent 开源战略) Institutional Signals Sync
# Data sources:
#   - https://strandsagents.com/blog/        (官方博客索引, static HTML)
#   - https://strandsagents.com/changelog/   (产品 changelog, static HTML)
#   - https://api.github.com/orgs/strands-agents/repos (GitHub org 仓库)
# Institutional framing: 「AWS 品牌下的开源」vs「开源」—— Decider 2B + Harness SDK
#   开源组件 Apache-2.0 但治理绑定 AWS。核心观察：第三方维护者能否实质决策
#   （Coase 企业边界在 agent 生态的再定界；A&R 包容性检验）。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/strandsagents"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=25
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

sync_blog() {
    local out="${DATA_DIR}/blog-index-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) blog index ${TODAY}"; return; fi
    log "Fetching strandsagents.com/blog/ ..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://strandsagents.com/blog/' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

sync_changelog() {
    local out="${DATA_DIR}/changelog-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) changelog ${TODAY}"; return; fi
    log "Fetching strandsagents.com/changelog/ ..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://strandsagents.com/changelog/' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

sync_github_org() {
    local out="${DATA_DIR}/github-org-repos-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) github org ${TODAY}"; return; fi
    log "Fetching GitHub org strands-agents repos..."
    retry "curl -sL --max-time ${TIMEOUT} -A 'Mozilla/5.0' -H 'Accept: application/vnd.github+json' 'https://api.github.com/orgs/strands-agents/repos?per_page=100' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== Strands Labs Institutional Signals Cache ==="
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
            printf "  %-55s %8d bytes\n" "$fname" "$size"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_blog
            sync_changelog
            sync_github_org
            ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"
