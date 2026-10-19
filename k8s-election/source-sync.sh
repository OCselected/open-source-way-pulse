#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — K8s Election Verifier（可复算治理数据）Institutional Sync
# Data sources:
#   - kubernetes/community/elections/steering/YYYY/  (ballots.csv, voters.yaml,
#     election.yaml, results.md) —— 原始选票 + 官方结果公开
#   - elekto-dev/elekto  elekto/core/__init__.py   —— 计数算法实现（Schulze）
# Institutional framing: 「可复算性」作为治理判据。K8s steering 选举是当今开源界
#   少数「外部可独立重算」的治理机制：原始选票公开（ballots.csv）、算法公开
#   （Elekto schulze_d/p/rank）、官方结果公开（results.md）。对照 OSPO 年度报告
#   （不可复算）与基金会理事会投票（不可复算），构成「透明」的可检验量。
# 关键实现语义（Elekto 源码）：**排名数字越大 = 偏好越高**；'No opinion' 整票跳过。
#   按字面「1=首选」反向解读会得到错误排序 —— 这是本模块要常态防住的误读。
# NIE 轴：Ostrom（治理规则的公开可验证性）/ Williamson（选举制度作为治理机制）
#         / A&R（贡献者→治理权的转换是否可审计）
# 2026-10-20 队列评估 P0 落地。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/k8s-election"
TODAY=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
TIMEOUT=30
GH_API="https://api.github.com"
RAW="https://raw.githubusercontent.com"
COMMUNITY="kubernetes/community"

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

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

# --- 1. 选举目录清单（发现层） -----------------------------------------------
sync_election_index() {
    local year="$1"
    local out="${DATA_DIR}/index-steering-${year}-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) election index ${year}"; return; fi
    log "Fetching steering election dir listing ${year} ..."
    gh_curl "${GH_API}/repos/${COMMUNITY}/contents/elections/steering/${year}" "$out" || { log "  FAILED"; return; }
    python3 - "$out" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
names = [x['name'] for x in d] if isinstance(d, list) else []
print(f"  files: {names}")
PY
}

# --- 2. 原始材料：ballots.csv / results.md / election.yaml / voters.yaml ------
sync_election_raw() {
    local year="$1"
    local base="elections/steering/${year}"
    local got=0 f
    for f in ballots.csv results.md election.yaml voters.yaml; do
        local out="${DATA_DIR}/${year}-${f//\//_}"
        if [[ -f "$out" ]]; then log "(cached) ${year}/${f}"; got=$((got+1)); continue; fi
        log "Fetching ${year}/${f} ..."
        if curl -sfL --max-time "${TIMEOUT}" "${RAW}/${COMMUNITY}/main/${base}/${f}" -o "$out"; then
            log "  Saved $(basename "$out") ($(wc -c < "$out") bytes)"; got=$((got+1))
        else
            log "  MISSING ${f}"; rm -f "$out"
        fi
    done
    log "  raw artifacts: ${got}/4"
    # hash 指纹：让「同一份选票」可被第三方校验是本批数据未变
    [[ -f "${DATA_DIR}/${year}-ballots.csv" ]] && \
        log "  ballots.csv sha256: $(sha256sum "${DATA_DIR}/${year}-ballots.csv" | cut -c1-16)"
}

# --- 3. 计数算法源码（可复算的前提：算法本身可读） ---------------------------
sync_algorithm() {
    local out="${DATA_DIR}/elekto-core-init-pinned-${TODAY}.py"
    if [[ -f "$out" ]]; then log "(cached) elekto schulze source"; return; fi
    log "Fetching Elekto schulze implementation ..."
    # 注意 org 已迁移 elekto-io → elekto-dev；core 包为单文件 __init__.py
    curl -sfL --max-time "${TIMEOUT}" \
        "${RAW}/elekto-dev/elekto/main/elekto/core/__init__.py" -o "$out" \
        && log "  Saved $(basename "$out") ($(wc -c < "$out") bytes, sha256 $(sha256sum "$out" | cut -c1-16))" \
        || { log "  FAILED"; rm -f "$out"; }
}

# --- 4. 复算 verification（核心）：把 ballots.csv 重算并逐项比对 results.md ----
verify_election() {
    local year="$1"
    local ballots="${DATA_DIR}/${year}-ballots.csv"
    local results="${DATA_DIR}/${year}-results.md"
    local out="${DATA_DIR}/verification-${year}-${TODAY}.json"
    if [[ ! -f "$ballots" ]]; then log "  skip verify: no ballots.csv"; return; fi
    log "Recomputing ${year} election (Elekto semantics) ..."
    python3 - "$ballots" "$results" "$out" "$year" <<'PY'
import csv, json, re, sys, collections
ballots_path, results_path, out_path, year = sys.argv[1:5]

rows = list(csv.reader(open(ballots_path)))
header, ballots = rows[0], rows[1:]
cands = header[:]

# Elekto 语义：rank 数字越大 = 偏好越高；'No opinion' 不参与比较
d = {(v, w): 0 for v in cands for w in cands if v != w}
for b in ballots:
    prefs = []
    for c, val in zip(header, b):
        val = val.strip()
        if val == 'No opinion' or val == '':
            continue
        prefs.append((c, int(val)))
    for v, vr in prefs:
        for w, wr in prefs:
            if v != w and vr > wr:
                d[(v, w)] += 1

p = {}
for x in cands:
    for y in cands:
        if x != y:
            s = d.get((x, y), 0)
            p[(x, y)] = s if s > d.get((y, x), 0) else 0
for x in cands:
    for z in cands:
        if x != z:
            for y in cands:
                if x != y and z != y:
                    p[(z, y)] = max(p.get((z, y), 0), min(p.get((z, x), 0), p.get((x, y), 0)))

wins = collections.defaultdict(list)
for v in cands:
    n = sum(1 for w in cands if v != w and p.get((v, w), 0) > p.get((w, v), 0))
    wins[n].append(v)
ranks = sorted(wins.items())
recomputed = [v for _n, vs in ranks for v in vs]

official, turnout = [], {}
# results.md 用人名（非 handle）→ 统一按人名比较：把重算出的 handle 映射回人名
HANDLE_TO_NAME = {'elmiko': 'Michael McCune', 'janetkuo': 'Janet Kuo',
                  'priyankasaggu11929': 'Priyanka Saggu', 'kaslin': 'Kaslin Fields',
                  'jackfrancis': 'Jack Francis', 'stmcginnis': 'Sean McGinnis'}
recomputed_named = [HANDLE_TO_NAME.get(v, v) for v in recomputed]
if results_path:
    try:
        txt = open(results_path).read()
        for m in re.finditer(r'^\s*\d+\.\s*\[([^\]]+)\]', txt, re.M):
            official.append(m.group(1).strip())
        for key, pat in (('eligible_voters', r'eligible voters:\s*([\d,]+)'),
                         ('votes_cast', r'votes cast:\s*([\d,]+)'),
                         ('turnout', r'Turnout:\s*([\d.]+%)')):
            mm = re.search(pat, txt)
            if mm:
                turnout[key] = mm.group(1)
    except FileNotFoundError:
        pass

pairwise = {f"{v}>{w}": d[(v, w)] for (v, w) in d if d[(v, w)] > d[(w, v)]}
json.dump({'year': year,
           'candidates': cands,
           'voter_rows': len(ballots),
           'recomputed_order': recomputed_named,
           'official_order': official,
           'top3_match': recomputed_named[:3] == official[:3] if official else None,
           'full_match': recomputed_named == official if official else None,
           'schulze_wins': {v: sum(1 for w in cands if v != w and p.get((v, w), 0) > p.get((w, v), 0)) for v in cands},
           'turnout': turnout,
           'majority_edges': pairwise},
          open(out_path, 'w'), indent=1)
print(f"  voter rows: {len(ballots)} | recomputed: {recomputed_named}")
print(f"  official:   {official}")
print(f"  full_match: {recomputed_named == official if official else 'n/a'}")
PY
}

# --- 5. 结果提取（供上游日报消费） -------------------------------------------
do_extract() {
    echo ""
    echo "=== K8s Election Verifier — 可复算性信号 ==="
    local v f
    v=$(ls -1t "${DATA_DIR}"/verification-*.json 2>/dev/null | head -1 || true)
    if [[ -n "${v}" ]]; then
        python3 - "$v" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 选举年度: {d['year']} | 选票行数: {d['voter_rows']} | 候选人: {len(d['candidates'])}")
print(f"- 官方结果顺序: {d['official_order']}")
print(f"- 独立复算顺序: {d['recomputed_order']}")
print(f"- 前三名一致: {d['top3_match']} | 完整序列一致: {d['full_match']}")
print(f"- 投票率数据: {d['turnout']}")
print(f"- Schulze wins: {d['schulze_wins']}（wins 数字=击败人数；低 wins = 排位靠前，Elekto 语义）")
PY
    else
        echo "- ⚠️ 无 verification 记录（先跑 --sync）"
    fi
    echo "- 判据: 原始选票 + 算法源码 + 官方结果三者齐备 → 「可复算性」基准样本"
    echo ""
}

do_status() {
    echo ""
    echo "=== K8s Election Verifier Cache ==="
    echo ""
    echo "  Total cached: $(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)"
    echo ""
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -12 \
        | while read -r _ts fname; do
            printf "  %-52s %10d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_election_index "$YEAR"
            sync_election_raw "$YEAR"
            sync_algorithm
            verify_election "$YEAR"
            ;;
        --verify) verify_election "${2:-$YEAR}" ;;
        --extract) do_extract ;;
        --status)  do_status ;;
        *) echo "Usage: $0 {--sync|--verify [year]|--extract|--status}"; exit 1 ;;
    esac
}

main "$@"
