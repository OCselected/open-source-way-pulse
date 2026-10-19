#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Advisory Grader（漏洞披露计量基础设施）Institutional Sync
# Data sources:
#   - GitHub Advisory Database (CC-BY-4.0): 可复算时序的公开数据集
#     https://github.com/github/advisory-database  (advisories/github-reviewed/YYYY/MM/*)
#   - GHSA REST API (逐条 advisory 元数据: published / severity / aliases)
#   - GitHub Blog · Advisory Database 策展团队一手运维自陈
#   - NIST NVD 运营变更公告（2026-04-15）: 强制前置来源
# Institutional framing: 「度量权」—— 漏洞披露的计数、复核、时序在平台侧 vs
#   国家实验室侧的分岔（GHSA 中位 2.04 天 vs NVD 27.69 天）；NVD 主动收缩富化服务
#   = 公共基础设施退场的可观察断点。数据 CC-BY-4.0 可独立复算是本模块存在的理由。
# NIE 轴：Coase（度量基础设施的生产边界）/ Williamson（平台-国家实验室混合治理）
#         / North（NVD 2026-04-15 政策断点）/ Ostrom（CVE 记录作为公共池塘资源）
#         / A&R（谁被优先富化：KEV/联邦软件 vs 其余 = 会员制公共品）
# 2026-10-20 队列评估 P0 落地。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/advisory-grader"
TODAY=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(date +%m)
TIMEOUT=30
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
GH_API="https://api.github.com"
RAW="https://raw.githubusercontent.com"

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

# --- 1. 当月 github-reviewed advisory 目录（发现层） -------------------------
# 注意：/contents 对 >=1000 项的目录返回 403；自动退回 git trees?recursive=1 前缀计数。
sync_advisory_index() {
    local year="$1" month="$2"
    local out="${DATA_DIR}/index-${year}-${month}-${TODAY}.json"
    if [[ -f "$out" ]] && python3 -c "import json;d=json.load(open('$out'));raise SystemExit(0 if isinstance(d,dict) and 'count' in d else 1)" 2>/dev/null; then
        log "(cached) advisory index ${year}/${month}"; return
    fi
    log "Fetching advisory index ${year}/${month} ..."
    local tmp="${out}.contents"
    if gh_curl "${GH_API}/repos/github/advisory-database/contents/advisories/github-reviewed/${year}/${month}" "$tmp" \
       && python3 -c "import json;d=json.load(open('$tmp'));raise SystemExit(0 if isinstance(d,list) else 1)" 2>/dev/null; then
        python3 - "$tmp" "$out" "$year" "$month" <<'PY'
import json, sys
src, dst, year, month = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
items = json.load(open(src))
ids = [i['name'] for i in items if i.get('type') == 'dir']
json.dump({'year_month': f'{year}-{month}', 'count': len(ids),
           'method': 'contents', 'sample_ids': sorted(ids)[:20]},
          open(dst, 'w'), indent=1)
print(f"  contents: {len(ids)} advisories in {year}/{month}")
PY
        rm -f "$tmp"; return
    fi
    rm -f "$tmp"
    log "  contents API unavailable → falling back to git tree (recursive)"
    local tree="${DATA_DIR}/tree-${TODAY}.json"
    if [[ ! -f "$tree" ]]; then
        gh_curl "${GH_API}/repos/github/advisory-database/git/trees/main?recursive=1" "$tree" || { log "  FAILED (tree)"; return; }
    fi
    python3 - "$tree" "$out" "$year" "$month" <<'PY'
import json, sys
tree, dst, year, month = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
d = json.load(open(tree))
prefix = f"advisories/github-reviewed/{year}/{month}/"
ids = {p['path'].split('/')[3] for p in d.get('tree', [])
       if p['path'].startswith(prefix) and p['path'].endswith('.json')}
json.dump({'year_month': f'{year}-{month}', 'count': len(ids), 'method': 'git-tree',
           'sample_ids': sorted(ids)[:20], 'truncated': d.get('truncated', False)},
          open(dst, 'w'), indent=1)
print(f"  git-tree: {len(ids)} advisories in {year}/{month} (truncated={d.get('truncated')})")
PY
}

# --- 2. 抽样逐条 GHSA 记录（结构校验 + 字段可复算性演示） --------------------
sync_advisory_sample() {
    local year="$1" month="$2" n="${3:-10}"
    local idx="${DATA_DIR}/index-${year}-${month}-${TODAY}.json"
    local out="${DATA_DIR}/sample-${year}-${month}-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) advisory sample ${year}/${month}"; return; fi
    [[ -f "$idx" ]] || { log "  skip sample: no index"; return; }
    log "Fetching up to ${n} sampled GHSA records (${year}/${month}) ..."
    local ids recs="[]" got=0 gid body
    ids=$(python3 -c "
import json
d=json.load(open('$idx'))
print('\n'.join((d.get('sample_ids') or [])[:$n]))
")
    while read -r gid; do
        [[ -z "$gid" ]] && continue
        body="${DATA_DIR}/.ghsa.tmp"
        if curl -sfL --max-time "${TIMEOUT}" \
            "${RAW}/github/advisory-database/main/advisories/github-reviewed/${year}/${month}/${gid}/${gid}.json" \
            -o "$body"; then
            recs=$(python3 - "$recs" "$body" <<'PY'
import json, sys
acc = json.loads(sys.argv[1]); r = json.load(open(sys.argv[2]))
acc.append({
    'id': r.get('id'), 'published': r.get('published'), 'modified': r.get('modified'),
    'severity': (r.get('database_specific') or {}).get('severity'),
    'aliases': r.get('aliases', []),
    'ecosystems': sorted({(a.get('package') or {}).get('ecosystem', '?') for a in r.get('affected', [])}),
})
print(json.dumps(acc))
PY
)
            got=$((got+1))
        fi
        rm -f "$body"
    done <<< "$ids"
    echo "$recs" > "$out"
    log "  sampled records fetched: ${got}"
}

# --- 3. 可复算性基准：发布月份 / 严重度 / CVE 映射分布 -----------------------
sync_series() {
    local year="$1" month="$2"
    local sample="${DATA_DIR}/sample-${year}-${month}-${TODAY}.json"
    local out="${DATA_DIR}/series-${year}-${month}-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) series ${year}/${month}"; return; fi
    [[ -f "$sample" ]] || { log "  skip series: no sample"; return; }
    log "Recomputing series from sampled records ..."
    python3 - "$sample" "$out" <<'PY'
import json, sys, collections
recs = json.load(open(sys.argv[1]))
by_month = collections.Counter((r.get('published') or '')[:7] for r in recs if r.get('published'))
sev = collections.Counter(r.get('severity') or 'UNKNOWN' for r in recs)
eco = collections.Counter(e for r in recs for e in (r.get('ecosystems') or []))
with_cve = sum(1 for r in recs if any(a.startswith('CVE-') for a in (r.get('aliases') or [])))
json.dump({'sample_size': len(recs), 'by_month': dict(sorted(by_month.items())),
           'severity': dict(sev), 'ecosystems': dict(eco.most_common(10)),
           'ghsa_with_cve_alias': with_cve,
           'cve_alias_rate': round(with_cve / len(recs), 3) if recs else None},
          open(sys.argv[2], 'w'), indent=1)
print(f"  series: {len(recs)} records, cve_alias_rate={with_cve}/{len(recs)}")
PY
}

# --- 4. 一手运维自陈与政策原文（强制前置来源） -------------------------------
sync_primary_texts() {
    local blog="${DATA_DIR}/github-blog-advisory-db-${TODAY}.html"
    if [[ ! -f "$blog" ]]; then
        log "Fetching GitHub Blog advisory-database ops post ..."
        retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://github.blog/security/supply-chain-security/inside-the-advisory-database-and-what-happens-when-vulnerability-volume-breaks-records/' -o '${blog}'" \
            && log "  Saved $(basename "$blog")" || { log "  FAILED"; rm -f "$blog"; }
    else
        log "(cached) github blog ops post"
    fi

    local nist="${DATA_DIR}/nist-nvd-ops-change-${TODAY}.html"
    if [[ ! -f "$nist" ]]; then
        log "Fetching NIST NVD operations change notice ..."
        retry "curl -sL --max-time ${TIMEOUT} -A '${UA}' 'https://www.nist.gov/news-events/news/2026/04/nist-updates-nvd-operations-address-record-cve-growth' -o '${nist}'" \
            && log "  Saved $(basename "$nist")" || { log "  FAILED"; rm -f "$nist"; }
    else
        log "(cached) nist nvd notice"
    fi
}

# --- 5. 数据集本体元信息（branch HEAD = 数据更新指针） -----------------------
sync_repo_meta() {
    local out="${DATA_DIR}/repo-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) repo meta ${TODAY}"; return; fi
    log "Fetching advisory-database repo metadata ..."
    gh_curl "${GH_API}/repos/github/advisory-database" "$out" || { log "  FAILED"; return; }
    local head
    head=$(curl -sL --max-time "${TIMEOUT}" "${GH_API}/repos/github/advisory-database/commits/main" \
        -H 'Accept: application/vnd.github+json' -H 'User-Agent: pulse-cron' \
        | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('sha','?')[:12], d.get('commit',{}).get('committer',{}).get('date','?'))" 2>/dev/null || echo "?")
    log "  HEAD: ${head}"
}

do_extract() {
    echo ""
    echo "=== Advisory Grader — 可复算性 / 度量权 信号 ==="
    local series idx
    series=$(ls -1t "${DATA_DIR}"/series-*.json 2>/dev/null | head -1 || true)
    idx=$(ls -1t "${DATA_DIR}"/index-*.json 2>/dev/null | head -1 || true)
    if [[ -n "${idx}" ]]; then
        python3 - "$idx" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 当月 advisory 计数（github-reviewed {d.get('year_month')}）: {d.get('count')} 条  [method={d.get('method')}]")
PY
    fi
    if [[ -n "${series}" ]]; then
        python3 - "$series" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 抽样规模: {d['sample_size']} 条（抽样，非全量）")
print(f"- 发布月份分布: {d['by_month']}")
print(f"- 严重等级分布: {d['severity']}")
print(f"- 生态分布(top): {d['ecosystems']}")
print(f"- GHSA 带 CVE 别名比例: {d['cve_alias_rate']}（GHSA↔CVE 双轨映射的可复算证据）")
PY
    else
        echo "- ⚠️ 无 series（先跑 --sync）"
    fi
    echo "- 判据: 数据集 CC-BY-4.0 可全量重算 → 「可复算性」基准样本（对照 OSPO 报告 / 基金会理事会投票的不可复算）"
    echo ""
}

do_status() {
    echo ""
    echo "=== Advisory Grader Cache ==="
    echo ""
    local total
    total=$(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "  Total cached: ${total}"
    echo ""
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -12 \
        | while read -r _ts fname; do
            local size
            size=$(wc -c < "${DATA_DIR}/${fname}")
            printf "  %-52s %10d bytes\n" "$fname" "$size"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_repo_meta
            sync_advisory_index "$YEAR" "$MONTH"
            sync_advisory_sample "$YEAR" "$MONTH" 10
            sync_series "$YEAR" "$MONTH"
            sync_primary_texts
            ;;
        --extract) do_extract ;;
        --status)  do_status ;;
        *) echo "Usage: $0 {--sync|--extract|--status}"; exit 1 ;;
    esac
}

main "$@"
