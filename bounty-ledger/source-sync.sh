#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Bounty Ledger Sync（公地对漏洞发现者定价的台账）
# 数据对象：curl 官方 CVE 台账 docs/vuln.pm（含逐条 award 金额）+ 其治理决策链
#
# 为什么值得一个模块：开源世界里，几乎没有任何一份可机器读取的台账
#   同时记着「哪个缺陷、谁报的、哪天报的、给了多少钱」。
#   curl 的 vuln.pm 是目前唯一一份把「公地对发现的定价」写成时间序列的文件 ——
#   每行一条 CVE，字段含 announce 日 / report 日 / CWE / award(USD) / severity / 原始报告 URL。
#   有了它，「AI 时代漏洞申报量暴涨而奖金归零」这件事第一次可以被逐条复算，
#   而不是靠描述。
#
# 本模块测的不是漏洞，是**激励制度**：
#   - 市场端：award 列（发现被定价多少）
#   - 科层/合法化端：BUG-BOUNTY.md 的文本演化（项目如何宣布停止定价）
#   - 治理执行端：该决定是走 PR 共识还是直推 master（BDFL 的执行形态）
#
# 已实测的坑（勿重复踩）：
#   - vuln.pm 每行 13 或 14 个 `|` 分隔字段（issue URL 可能缺失）→ 必须按长度容错解析，
#     naive split 会把 award 与 severity 错位，得出完全相反的年趋势
#   - award 的 0 有双重含义：『未给奖』与『给 0 美元』无法区分，
#     金额 0 的行不代表「奖励取消」，只代表「无金额记录」→ 所有统计必须分开报 n 与 sum
#   - 2026-01-22 ca7ef4b817 的 BUG-BOUNTY.md 改动**不是 PR 合并**：
#     PR #20312 至今 state=closed / merged=false，而同一 commit 由 BDFL 直推 master。
#     引用「PR 关闭」时必须同时引用 commit，否则会漏掉真正的执行者
#   - 2026-03-10 ed7bf43a0 把 BUG-BOUNTY.md 从「说明何时结束」改写成
#     「No curl bug bounty」+ 反赏金理由 → 制度从『暂停』固化为『否定』，是第二个阶段
#   - vuln.pm 由 curl-www 仓库维护，不在 curl/curl → 查不到会误判为「台账已消失」
#
# 2026-11-04 ~ 11-10 队列评估 P0 落地（11-04 发现 / 11-09 制度退化案例 / 11-10 复用）
# NIE 轴：Coase 5（赏金即产权定价，取消即退出市场定价）/ Williamson 4（市场→科层→
#         自述的治理位移）/ North 5（制度退化的两阶段文本证据）/ A&R 4（谁承担噪声成本）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/bounty-ledger"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=30
GH_API="https://api.github.com"
RAW="https://raw.githubusercontent.com"
VULNPM_REPO="curl/curl-www"
VULNPM_PATH="docs/vuln.pm"
CURL_REPO="curl/curl"
BOUNTY_PATH="docs/BUG-BOUNTY.md"

mkdir -p "${DATA_DIR}"
log() { echo "[$(date +%H:%M:%S)] $*"; }

TOKEN=""
if command -v gh >/dev/null 2>&1; then TOKEN=$(gh auth token 2>/dev/null || true); fi
if [[ -z "${TOKEN:-}" ]]; then
    log "FATAL: 无 GitHub token（无 token 时 api.github.com 返回 403）。先 gh auth login。"
    exit 1
fi

api_get() {
    curl -sfL --max-time "${TIMEOUT}" -H 'Accept: application/vnd.github+json' \
        -H 'User-Agent: pulse-cron' -H "Authorization: Bearer ${TOKEN}" "$1" -o "$2"
}

raw_get() {
    curl -sfL --max-time "${TIMEOUT}" -H 'User-Agent: pulse-cron' "$1" -o "$2"
}

# --- 1. 台账本体 -----------------------------------------------------------
# 台账是快照而非增量：每轮覆盖当日快照，历史由 git 保留
sync_ledger() {
    local out="${DATA_DIR}/vuln-${TODAY}.pm"
    if [[ -f "$out" ]]; then log "(cached) vuln.pm"; return; fi
    log "Fetching ${VULNPM_REPO}/${VULNPM_PATH} ..."
    if raw_get "${RAW}/${VULNPM_REPO}/HEAD/${VULNPM_PATH}" "$out"; then
        log "  Saved ($(wc -c < "$out") bytes, sha256 $(sha256sum "$out" | cut -c1-16))"
    else
        log "  FAILED"; rm -f "$out"; return 1
    fi
}

# --- 2. 台账自身的提交史（award 列何时被冻结） ------------------------------
sync_ledger_history() {
    local out="${DATA_DIR}/ledger-commits-${TODAY}.json"
    [[ -f "$out" ]] && { log "(cached) ledger-commits"; return; }
    log "Fetching vuln.pm commit history (100) ..."
    if api_get "${GH_API}/repos/${VULNPM_REPO}/commits?path=${VULNPM_PATH}&per_page=100" "$out"; then
        python3 - "$out" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"  {len(d)} commits; latest: {d[0]['commit']['author']['date'][:10]} {d[0]['commit']['message'].splitlines()[0][:60]}")
PY
    else
        log "  FAILED"; rm -f "$out"; return 1
    fi
}

# --- 3. 制度文本：BUG-BOUNTY.md 当前态 + 提交史 ----------------------------
sync_policy() {
    local cur="${DATA_DIR}/BUG-BOUNTY-${TODAY}.md"
    local hist="${DATA_DIR}/bounty-commits-${TODAY}.json"
    if [[ ! -f "$cur" ]]; then
        log "Fetching ${CURL_REPO}/${BOUNTY_PATH} ..."
        raw_get "${RAW}/${CURL_REPO}/HEAD/${BOUNTY_PATH}" "$cur" \
            && log "  Saved ($(wc -c < "$cur") bytes)" || { log "  FAILED"; rm -f "$cur"; }
    else
        log "(cached) BUG-BOUNTY.md"
    fi
    if [[ ! -f "$hist" ]]; then
        log "Fetching BUG-BOUNTY.md commit history ..."
        api_get "${GH_API}/repos/${CURL_REPO}/commits?path=${BOUNTY_PATH}&per_page=20" "$hist" \
            || { log "  FAILED"; rm -f "$hist"; }
    fi
}

# --- 4. 治理执行端：PR #20312 与直推 commit 的对照 --------------------------
# 同一制度变更的两种形态：PR（讨论存档，未合并）+ commit（BDFL 执行）
sync_governance() {
    local pr="${DATA_DIR}/pr20312-${TODAY}.json"
    local cm="${DATA_DIR}/commit-ca7ef4b817-${TODAY}.json"
    local cm2="${DATA_DIR}/commit-ed7bf43a0-${TODAY}.json"
    if [[ ! -f "$pr" ]]; then
        log "Fetching PR #20312 ..."
        api_get "${GH_API}/repos/${CURL_REPO}/pulls/20312" "$pr" || { log "  FAILED"; rm -f "$pr"; }
    fi
    if [[ ! -f "$cm" ]]; then
        log "Fetching commit ca7ef4b817 (2026-01-22 直推) ..."
        api_get "${GH_API}/repos/${CURL_REPO}/commits/ca7ef4b817" "$cm" || { log "  FAILED"; rm -f "$cm"; }
    fi
    if [[ ! -f "$cm2" ]]; then
        log "Fetching commit ed7bf43a0 (2026-03-10 固化) ..."
        api_get "${GH_API}/repos/${CURL_REPO}/commits/ed7bf43a0" "$cm2" || { log "  FAILED"; rm -f "$cm2"; }
    fi
}

# --- 5. 提取（核心）：逐条解析台账，算定价时间序列 --------------------------
do_verify() {
    echo ""
    echo "=== Bounty Ledger — 公地对漏洞发现的定价 ==="
    local vp
    vp=$(ls -1t "${DATA_DIR}"/vuln-*.pm 2>/dev/null | head -1 || true)
    if [[ -z "$vp" ]]; then echo "- ⚠️ 无台账快照（先跑 --sync）"; return; fi

    local out="${DATA_DIR}/ledger-${TODAY}.json"
    python3 - "$vp" "$out" <<'PY'
import collections, datetime as dt, json, re, sys

path, out_path = sys.argv[1:3]
text = open(path, encoding='utf-8', errors='ignore').read()
# 每行形如： "CVE-xxxx.html|first|last|name|CVE-xxxx|YYYYMMDD|YYYYMMDD|CWE-..|award|area|issue-type|both|severity|[issue URL]"
rows = re.findall(r'"([^"]*CVE-[^"]*)"', text)
recs, malformed = [], 0
for r in rows:
    f = r.split('|')
    if len(f) < 13:
        malformed += 1
        continue
    # 字段位置固定在前 13 位；第 14 位起为可选 issue URL —— 不按长度推断含义
    recs.append({
        'cve': f[4], 'announce': f[5], 'report': f[6],
        'cwe': f[7].split(':')[0], 'award': f[8], 'area': f[9],
        'severity': f[12],
        'issue_url': f[13] if len(f) > 13 and f[13].startswith('http') else None,
    })

def year(d): return d[:4] if len(d) == 8 and d.isdigit() else '?'
def d2date(x):
    try: return dt.date(int(x[:4]), int(x[4:6]), int(x[6:]))
    except Exception: return None

# 年度定价序列
by_year = collections.defaultdict(lambda: {'cve': 0, 'awarded': 0, 'usd': 0})
for r in recs:
    y = year(r['announce'])
    by_year[y]['cve'] += 1
    if r['award'].isdigit() and int(r['award']) > 0:
        by_year[y]['awarded'] += 1
        by_year[y]['usd'] += int(r['award'])

y2026 = [r for r in recs if r['announce'].startswith('2026')]
y2026_aw = [r for r in y2026 if r['award'].isdigit() and int(r['award']) > 0]

lags = []
for r in y2026:
    a, b = d2date(r['announce']), d2date(r['report'])
    if a and b: lags.append((a - b).days)
lags.sort()

issues = [r for r in recs if r['issue_url']]
report_ids = collections.Counter(
    m.group(1) for r in issues
    for m in [re.search(r'reports/(\d+)', r['issue_url'])] if m
)

rec = {
    'snapshot': path.split('/')[-1],
    'total_entries': len(recs),
    'malformed_rows': malformed,
    'rows_with_issue_url': len(issues),
    'distinct_report_ids': len(report_ids),
    'by_year': {k: by_year[k] for k in sorted(by_year)},
    'y2026': {
        'cve': len(y2026),
        'awarded': len(y2026_aw),
        'usd': sum(int(r['award']) for r in y2026_aw),
        'severity': dict(collections.Counter(r['severity'] for r in y2026)),
        'announce_dates': dict(sorted(collections.Counter(r['announce'] for r in y2026).items())),
        'lag_days': {'n': len(lags), 'min': lags[0], 'median': lags[len(lags)//2],
                     'max': lags[-1]} if lags else None,
        'last_awarded_report': max((r['report'] for r in y2026_aw), default=None),
    },
}
json.dump(rec, open(out_path, 'w'), indent=1, ensure_ascii=False)

print(f"- 台账快照 {rec['snapshot']}: {rec['total_entries']} 条 CVE（解析失败 {malformed} 行）")
print(f"- 带原始报告 URL 的行 {len(issues)}，去重报告 id {rec['distinct_report_ids']} 个")
for y in ('2022', '2023', '2024', '2025', '2026'):
    s = by_year.get(y)
    if s: print(f"- {y}: CVE {s['cve']:>3} | 有奖金 {s['awarded']:>3} | 合计 US${s['usd']:>7,}")
print(f"- 2026 年 {rec['y2026']['cve']} 条 CVE，其中 {rec['y2026']['awarded']} 条有奖金（US${rec['y2026']['usd']:,}）")
print(f"  最后一条带奖金的报告日: {rec['y2026']['last_awarded_report']}")
if rec['y2026']['lag_days']:
    l = rec['y2026']['lag_days']
    print(f"  报告→公布滞后（2026）: n={l['n']} min={l['min']} 中位={l['median']} max={l['max']} 天")
print(f"  严重级分布: {rec['y2026']['severity']}")
print(f"  公布日批次日: {rec['y2026']['announce_dates']}")
print("  ⚠️ award=0 有两种含义（未给奖 / 给 0 美元），本表只统计 >0 的行；n 与 sum 必须分开引用")
PY

    # 制度文本两阶段
    local hist
    hist=$(ls -1t "${DATA_DIR}"/bounty-commits-*.json 2>/dev/null | head -1 || true)
    if [[ -n "$hist" ]]; then
        python3 - "$hist" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print("- BUG-BOUNTY.md 提交史（近 20）:")
for c in d[:6]:
    print(f"    {c['sha'][:9]} {c['commit']['author']['date'][:10]} {c['commit']['message'].splitlines()[0][:72]}")
PY
    fi

    # PR vs 直推
    local pr cm
    pr=$(ls -1t "${DATA_DIR}"/pr20312-*.json 2>/dev/null | head -1 || true)
    cm=$(ls -1t "${DATA_DIR}"/commit-ca7ef4b817-*.json 2>/dev/null | head -1 || true)
    if [[ -n "$pr" && -n "$cm" ]]; then
        python3 - "$pr" "$cm" <<'PY'
import json, sys
pr = json.load(open(sys.argv[1])); cm = json.load(open(sys.argv[2]))
print(f"- 同一制度变更的两形态: PR #{pr['number']} state={pr['state']} merged={pr['merged']} "
      f"comments={pr['comments']} closed={pr['closed_at'][:10]}")
print(f"  commit {cm['sha'][:9]} {cm['commit']['author']['date'][:10]} by {cm['commit']['author']['name']} "
      f"({len(cm.get('files', []))} files, {sum(f['deletions'] for f in cm.get('files', []))} 行删除)")
print("  判据: PR 是讨论存档，commit 才是执行 —— 只引 PR 会漏掉真正的决定者")
PY
    fi

    local pol
    pol=$(ls -1t "${DATA_DIR}"/BUG-BOUNTY-*.md 2>/dev/null | head -1 || true)
    if [[ -n "$pol" ]]; then
        echo "- BUG-BOUNTY.md 当前态（$(wc -c < "$pol") bytes）:"
        sed -n '1,40p' "$pol" | grep -v '^$' | grep -v '^<!--' | grep -v 'SPDX' | grep -v 'Copyright' | sed 's/^/    /'
    fi
    echo ""
}

do_status() {
    echo ""
    echo "=== Bounty Ledger Cache ==="
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -10 | while read -r _ts fname; do
            printf "  %-46s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_ledger
            sync_ledger_history
            sync_policy
            sync_governance
            ;;
        --verify) do_verify ;;
        --extract) do_verify ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--verify|--extract|--status}"; exit 1 ;;
    esac
}

main "$@"
