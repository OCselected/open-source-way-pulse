#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Aleph Alpha (EU 主权 AI) Institutional Signals Sync
# Data sources:
#   - /news/ 索引页 HTML（公司治理/人事/主权公告）
#   - /blog/ 索引页 HTML（技术/模型公告，含 /en/blog/kolibri-has-landed...）
# Institutional framing: 大分流 2.0「权重开源 vs 训练专有」边界正式制度化样本
#   Kolibri 78B Apache-2.0 权重 + 专有训练管线 (2026-09/10) = Coase 企业边界重画
#   EU 主权 AI 路径（深度嵌入全球开源生态的权重层）vs 中国行政动员式路径对照
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/aleph-alpha"
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

fetch_index() {
    local path="$1"   # news | blog
    local out="${DATA_DIR}/${path}-index-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) /${path}/ ${TODAY}"; return; fi
    log "Fetching Aleph Alpha /${path}/ index..."
    retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://aleph-alpha.com/${path}/' -o '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED /${path}/"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== Aleph Alpha Institutional Signals Cache ==="
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
            fetch_index "news"
            fetch_index "blog"
            ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"