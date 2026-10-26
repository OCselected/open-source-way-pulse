#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — OSS Scanner（审计配额分配机制）Institutional Sync
# Data sources:
#   - 政策文本: https://red.anthropic.com/oss-scanner/ （静态 HTML，含完整 FAQ）
#   - 入册档案: anthropics/oss-scanner projects/ 目录（GitHub contents API）
#   - PR 流量:  open / merged / closed-unmerged 三分解（search/issues API）
#   - 仓库元信息: stars / forks / pushed_at / created_at
# Institutional framing: 「谁配得到免费深度审计」—— 关键基础设施的判定权 + 深度审计能力
#   的分配权由单一公司持有，判据通过公开 PR 自助入册执行，拒绝留痕。对照 advisory-grader
#   （公共度量基础设施收缩）：同一治理功能一个私有化扩张、一个公共服务收缩。
# NIE 轴：Coase（审计作为独立生产环节被划入企业边界）/ Williamson（单方定价 + 市场式准入的
#         层级倒置）/ North（披露时钟按报告可信度分层）/ Ostrom（准入边界规则由外部行动者书写）
#         / A&R（谁被优先服务由判据名单而非需求决定）
# 2026-10-27 队列评估 P0 落地（队列 2026-10-21 ~ 2026-10-27）。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/oss-scanner"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=30
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
GH_API="https://api.github.com"

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

gh_curl() {
    local url="$1" out="$2"
    local token=""
    token=$(gh auth token 2>/dev/null || true)
    if [[ -n "${token}" ]]; then
        curl -sfL --max-time "${TIMEOUT}" -H 'Accept: application/vnd.github+json' \
            -H 'User-Agent: pulse-cron' -H "Authorization: Bearer ${token}" "$url" -o "$out"
    else
        curl -sfL --max-time "${TIMEOUT}" -H 'Accept: application/vnd.github+json' \
            -H 'User-Agent: pulse-cron' "$url" -o "$out"
    fi
}

# --- 1. 政策文本（强制前置来源）---------------------------------------------
# 注意：无 RSS / sitemap.xml（返回的是 HTML 页）。政策页是静态可抓的单一长页，
# 披露规则与准入判据全部在此，因此每日整页快照 + sha256 变化检测即可。
sync_policy() {
    local out="${DATA_DIR}/policy-${TODAY}.html"
    if [[ -f "$out" ]]; then log "(cached) policy ${TODAY}"; return; fi
    log "Fetching OSS Scanner policy page..."
    if retry "curl -sfL --max-time ${TIMEOUT} -A '${UA}' 'https://red.anthropic.com/oss-scanner/' -o '${out}'"; then
        log "  Saved ${out} ($(wc -c < "$out") bytes)"
        echo "$(date -Iseconds) sha256=$(sha256sum "$out" | cut -d' ' -f1)" >> "${DATA_DIR}/policy.sha256.log"
    else
        log "  FAILED policy page"; rm -f "$out"
    fi
}

# --- 2. 入册项目清单（「什么算关键基础设施」的通过样本）---------------------
sync_roster() {
    local out="${DATA_DIR}/projects-roster-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) roster ${TODAY}"; return; fi
    log "Fetching projects roster..."
    if retry "gh_curl '${GH_API}/repos/anthropics/oss-scanner/contents/projects' '${out}'"; then
        local n
        n=$(python3 -c "import json;print(len(json.load(open('${out}'))))" 2>/dev/null || echo "?")
        log "  Saved ${out} — ${n} enrolled projects"
        echo "${TODAY} ${n}" >> "${DATA_DIR}/roster-count.history"
    else
        log "  FAILED roster"; rm -f "$out"
    fi
}

# --- 3. PR 流量三分解（通过率可计算；拒绝清单 = 判词集）---------------------
sync_pr_flow() {
    local out="${DATA_DIR}/pr-flow-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) pr-flow ${TODAY}"; return; fi
    local q_open="repo:anthropics/oss-scanner+type:pr+state:open"
    local q_merged="repo:anthropics/oss-scanner+type:pr+is:merged"
    local q_closed="repo:anthropics/oss-scanner+type:pr+is:unmerged+is:closed"
    local f_open="${DATA_DIR}/.pr_open.tmp" f_merged="${DATA_DIR}/.pr_merged.tmp" f_closed="${DATA_DIR}/.pr_closed.tmp"
    log "Fetching PR flow (open / merged / closed-unmerged)..."
    retry "gh_curl '${GH_API}/search/issues?q=${q_open}&per_page=1' '${f_open}'" || { log "  FAILED open"; rm -f "$f_open"; return; }
    retry "gh_curl '${GH_API}/search/issues?q=${q_merged}&per_page=1' '${f_merged}'" || { log "  FAILED merged"; rm -f "$f_merged"; return; }
    retry "gh_curl '${GH_API}/search/issues?q=${q_closed}&per_page=1' '${f_closed}'" || { log "  FAILED closed"; rm -f "$f_closed"; return; }
    python3 - "$f_open" "$f_merged" "$f_closed" "$out" <<'PY'
import json,sys,datetime
def cnt(p):
    d=json.load(open(p)); return d.get('total_count',0), d.get('incomplete_results',True)
o,oi=cnt(sys.argv[1]); m,mi=cnt(sys.argv[2]); c,ci=cnt(sys.argv[3])
decided=m+c
doc={"as_of":datetime.date.today().isoformat(),"open":o,"merged":m,"closed_unmerged":c,
     "decided":decided,"accept_rate":round(m/decided,4) if decided else None,
     "incomplete_results":bool(oi or mi or ci)}
json.dump(doc,open(sys.argv[4],'w'),indent=2)
print(f"  open={o} merged={m} closed_unmerged={c} accept_rate={doc['accept_rate']}")
PY
    rm -f "$f_open" "$f_merged" "$f_closed"
    log "  Saved ${out}"
}

# --- 4. 仓库元信息 -----------------------------------------------------------
sync_repo_meta() {
    local out="${DATA_DIR}/repo-meta-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) repo-meta ${TODAY}"; return; fi
    log "Fetching repo metadata..."
    retry "gh_curl '${GH_API}/repos/anthropics/oss-scanner' '${out}'" \
        && log "  Saved ${out}" || { log "  FAILED repo-meta"; rm -f "$out"; }
}

do_status() {
    echo ""
    echo "=== OSS Scanner Institutional Signals Cache ==="
    echo ""
    local total
    total=$(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "Files: ${total}  (${DATA_DIR})"
    echo ""
    echo "--- recent ---"
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -10 \
        | while read -r _ts fname; do
            local size
            size=$(wc -c < "${DATA_DIR}/${fname}")
            printf "  %-46s %8d bytes\n" "$fname" "$size"
        done
    echo ""
    if [[ -f "${DATA_DIR}/roster-count.history" ]]; then
        echo "--- roster count history (last 10) ---"
        tail -10 "${DATA_DIR}/roster-count.history"
        echo ""
    fi
    if [[ -f "${DATA_DIR}/policy.sha256.log" ]]; then
        echo "--- policy sha256 (last 5) ---"
        tail -5 "${DATA_DIR}/policy.sha256.log"
        echo ""
    fi
}

main() {
    case "${1:-}" in
        --sync)
            sync_policy
            sync_roster
            sync_pr_flow
            sync_repo_meta
            ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--status}"; exit 1 ;;
    esac
}

main "$@"
