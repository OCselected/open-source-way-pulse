#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Vouch Registry Sync
# 数据对象：ghostty-org/ghostty 把「谁能贡献」编译成 CI 的完整制度档案
#
# 为什么值得一个模块：准入规则通常只写在 CONTRIBUTING.md 的散文里 ——
#   规则存在、执行靠人、留痕为零。ghostty 把四个环节全部做成可 diff 的：
#   规则文本（AI_POLICY.md）→ 执行机制（vouch-*.yml）→ 状态（VOUCHED.td）→ 变更（bot PR）
#
# 已实测的坑（勿重复踩）：
#   - 无 token 打 api.github.com 一律 403（不是 401），看起来像仓库不存在
#   - VOUCHED.td 同时装 vouch 与 denounce，只数行数会得出完全错误的结论；
#     必须按行首 '-' 拆分，且 '-' 只在不带 'platform:' 前缀时才表示排除
#   - 名单 PR 全部由 bot 合并、零 review —— 『谁做的决定』在 PR 元数据里查不到，
#     人类动作在 discussion 里。引用 merged_by 时务必声明这一缺口
#   - 理由字段是自由书写文本，只能做关键词统计，不能当分类事实
#
# 2026-11-03 队列评估 P0 落地（10-29 / 10-30 / 11-03 三日信号汇聚）
# NIE 轴：Ostrom（自定规则+分级处置+可复用）/ North（规则与执行分离的可测证据）
#         / Williamson（治理成本从判断转移到记账）/ A&R（排除是否永久、有无申诉）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/vouch-registry"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=30
GH_API="https://api.github.com"
RAW="https://raw.githubusercontent.com"
REPO="ghostty-org/ghostty"

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

TOKEN=""
if command -v gh >/dev/null 2>&1; then TOKEN=$(gh auth token 2>/dev/null || true); fi
if [[ -z "${TOKEN}" ]]; then
    log "FATAL: 无 GitHub token（无 token 时 api.github.com 返回 403）。先 gh auth login。"
    exit 1
fi

api_get() {
    curl -sfL --max-time "${TIMEOUT}" -H 'Accept: application/vnd.github+json' \
        -H 'User-Agent: pulse-cron' -H "Authorization: Bearer ${TOKEN}" "$1" -o "$2"
}

# --- 1. 名单本体 -----------------------------------------------------------
sync_roster() {
    local out="${DATA_DIR}/VOUCHED-${TODAY}.td"
    if [[ -f "$out" ]]; then log "(cached) VOUCHED.td"; return; fi
    log "Fetching VOUCHED.td ..."
    curl -sfL --max-time "${TIMEOUT}" -H 'User-Agent: pulse-cron' \
        "${RAW}/${REPO}/main/.github/VOUCHED.td" -o "$out" \
        && log "  Saved ($(wc -c < "$out") bytes, sha256 $(sha256sum "$out" | cut -c1-16))" \
        || { log "  FAILED"; rm -f "$out"; }
}

# --- 2. 规则文本与执行机制 -------------------------------------------------
sync_rules() {
    local out="${DATA_DIR}/AI_POLICY-${TODAY}.md"
    if [[ ! -f "$out" ]]; then
        log "Fetching AI_POLICY.md ..."
        curl -sfL --max-time "${TIMEOUT}" -H 'User-Agent: pulse-cron' \
            "${RAW}/${REPO}/main/AI_POLICY.md" -o "$out" \
            && log "  Saved ($(wc -c < "$out") bytes)" || { log "  FAILED"; rm -f "$out"; }
    fi

    local wf_out="${DATA_DIR}/workflows-${TODAY}.json"
    if [[ ! -f "$wf_out" ]]; then
        log "Fetching .github/workflows listing ..."
        api_get "${GH_API}/repos/${REPO}/contents/.github/workflows" "$wf_out" || { log "  FAILED"; return; }
    fi
    python3 - "$wf_out" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
vouch = [x['name'] for x in d if x['name'].startswith('vouch-')]
print(f"  workflows 共 {len(d)} 个 | vouch-* 共 {len(vouch)} 个: {', '.join(sorted(vouch))}")
PY

    local yml
    for yml in vouch-check-pr.yml vouch-manage-by-discussion.yml; do
        local o="${DATA_DIR}/${yml%.yml}-${TODAY}.yml"
        [[ -f "$o" ]] && continue
        curl -sfL --max-time "${TIMEOUT}" -H 'User-Agent: pulse-cron' \
            "${RAW}/${REPO}/main/.github/workflows/${yml}" -o "$o" \
            && log "  Saved ${yml} ($(wc -c < "$o") bytes)" || rm -f "$o"
    done
}

# --- 3. 名单变更史（规则生命周期） ----------------------------------------
sync_history() {
    local out="${DATA_DIR}/list-commits-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) list commits"; return; fi
    log "Fetching VOUCHED.td commit history (100) ..."
    api_get "${GH_API}/repos/${REPO}/commits?path=.github/VOUCHED.td&per_page=100" "$out" \
        && log "  Saved ($(python3 -c "import json;print(len(json.load(open('$out'))))") commits)" \
        || { log "  FAILED"; rm -f "$out"; }
}

sync_policy_history() {
    local out="${DATA_DIR}/policy-commits-${TODAY}.json"
    if [[ -f "$out" ]]; then log "(cached) policy commits"; return; fi
    log "Fetching AI_POLICY.md commit history ..."
    api_get "${GH_API}/repos/${REPO}/commits?path=AI_POLICY.md&per_page=100" "$out" || { log "  FAILED"; rm -f "$out"; }
}

# --- 4. 复算：名单结构 + 变更频率 + 抽样评审覆盖 --------------------------
do_verify() {
    local roster
    roster=$(ls -1t "${DATA_DIR}"/VOUCHED-*.td 2>/dev/null | head -1 || true)
    [[ -z "$roster" ]] && { log "先跑 --sync"; return 1; }

    local commits
    commits=$(ls -1t "${DATA_DIR}"/list-commits-*.json 2>/dev/null | head -1 || true)
    local pcommits
    pcommits=$(ls -1t "${DATA_DIR}"/policy-commits-*.json 2>/dev/null | head -1 || true)

    local out="${DATA_DIR}/verification-${TODAY}.json"
    log "Recomputing roster metrics ..."
    python3 - "$roster" "$commits" "$pcommits" "$out" "$TODAY" <<'PY'
import json, sys, re, datetime

roster_path, commits_path, pcommits_path, out_path, today = sys.argv[1:6]

lines = [l.rstrip('\n') for l in open(roster_path, encoding='utf-8')]
data = [l for l in lines if l.strip() and not l.lstrip().startswith('#')]
vouched, denounced = [], []
for l in data:
    s = l.lstrip()
    if s.startswith('-'):
        body = s[1:].strip()
        parts = body.split(None, 1)
        handle = parts[0] if parts else ''
        reason = parts[1].strip() if len(parts) > 1 else ''
        denounced.append({'handle': handle, 'reason': reason})
    else:
        vouched.append(s.split()[0])

# 理由的关键词编码（只作分布指标，不作分类事实）
AI_PAT = re.compile(r'\b(ai|llm|bot|slop|hitl|human[- ]in[- ]the[- ]loop|meatproxy|meat[- ]proxy|automated|model)\b', re.I)
for d in denounced:
    d['ai_related_keyword'] = bool(AI_PAT.search(d['reason'])) if d['reason'] else False

rec = {
    'date': today,
    'roster_file': roster_path.split('/')[-1],
    'total_data_rows': len(data),
    'vouched': len(vouched),
    'denounced': len(denounced),
    'denounced_with_reason': sum(1 for d in denounced if d['reason']),
    'denounced_ai_keyword': sum(1 for d in denounced if d['ai_related_keyword']),
    'denounced_entries': denounced,
}

# 名单变更频率（最近 30 天）
if commits_path:
    try:
        cs = json.load(open(commits_path))
        dates = [c['commit']['author']['date'][:10] for c in cs]
        d30 = (datetime.date.fromisoformat(today) - datetime.timedelta(days=30)).isoformat()
        rec['list_commits_total'] = len(cs)
        rec['list_commits_30d'] = sum(1 for x in dates if x >= d30)
        rec['list_commit_oldest'] = min(dates) if dates else None
        rec['list_commit_newest'] = max(dates) if dates else None
    except Exception as e:
        rec['list_commits_error'] = str(e)

# 规则文本的生命周期（对照：政策不动，名单天天动）
if pcommits_path:
    try:
        ps = json.load(open(pcommits_path))
        rec['policy_commits_total'] = len(ps)
        rec['policy_dates'] = [c['commit']['author']['date'][:10] for c in ps]
    except Exception as e:
        rec['policy_commits_error'] = str(e)

json.dump(rec, open(out_path, 'w'), indent=1, ensure_ascii=False)

print(f"  数据行 {rec['total_data_rows']} | vouch {rec['vouched']} | denounce {rec['denounced']}")
print(f"  denounce 带理由 {rec['denounced_with_reason']} | 理由含 AI 相关词 {rec['denounced_ai_keyword']}")
if 'list_commits_30d' in rec:
    print(f"  名单提交: 近 30 天 {rec['list_commits_30d']} 次 | 历史窗口 {rec['list_commit_oldest']} ~ {rec['list_commit_newest']}")
if 'policy_commits_total' in rec:
    print(f"  政策提交: {rec['policy_commits_total']} 次 {rec.get('policy_dates')}")
PY
}

# --- 5. 抽样：名单 PR 的评审覆盖（可选，耗 1 次 search + N 次 core） ------
do_sample_prs() {
    local n="${1:-10}"
    local out="${DATA_DIR}/pr-sample-${TODAY}.json"
    log "Sampling ${n} VOUCHED list PRs ..."
    api_get "${GH_API}/search/issues?q=repo:${REPO}+is:pr+%22Update+VOUCHED+list%22+is:merged&sort=created&order=desc&per_page=${n}" /tmp/.vpr || {
        log "  FAILED（code search 限速 10/min，稍后再试）"; return; }
    python3 - "$n" "$out" <<PY
import json, subprocess, urllib.request, time, os
n = int("$n"); out = "$out"
tok = os.environ.get('TOKEN') or subprocess.check_output(['gh','auth','token']).decode().strip()
items = json.load(open('/tmp/.vpr')).get('items', [])[:n]
rows = []
for it in items:
    url = 'https://api.github.com/repos/${REPO}/pulls/%d' % it['number']
    req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + tok,
                                              'User-Agent': 'pulse-cron',
                                              'Accept': 'application/vnd.github+json'})
    try:
        pr = json.load(urllib.request.urlopen(req, timeout=30))
    except Exception as e:
        continue
    rows.append({'number': pr['number'], 'created': pr['created_at'][:10],
                 'merged_by': (pr.get('merged_by') or {}).get('login'),
                 'review_comments': pr.get('review_comments', 0),
                 'comments': pr.get('comments', 0),
                 'additions': pr.get('additions'), 'deletions': pr.get('deletions')})
    time.sleep(0.2)
bot = sum(1 for r in rows if r['merged_by'] and 'bot' in r['merged_by'].lower())
rev = sum(1 for r in rows if (r['review_comments'] or 0) + (r['comments'] or 0) > 0)
json.dump({'date': "$TODAY", 'sampled': len(rows), 'bot_merged': bot,
           'with_review_or_comment': rev, 'rows': rows}, open(out, 'w'), indent=1, ensure_ascii=False)
print(f"  抽样 {len(rows)} | bot 合并 {bot} | 有评审/评论 {rev}")
PY
}

# --- 6. 提取报告 -----------------------------------------------------------
do_extract() {
    echo ""
    echo "=== Vouch Registry — 准入规则被编译成 CI ==="
    local v
    v=$(ls -1t "${DATA_DIR}"/verification-*.json 2>/dev/null | head -1 || true)
    if [[ -n "$v" ]]; then
        python3 - "$v" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 名单: vouch {d['vouched']} / denounce {d['denounced']}（数据行 {d['total_data_rows']}）")
print(f"- denounce 带理由 {d['denounced_with_reason']} 条；其中理由含 AI 相关词 {d['denounced_ai_keyword']} 条")
if 'list_commits_30d' in d:
    print(f"- 名单变更: 近 30 天 {d['list_commits_30d']} 次提交")
if 'policy_commits_total' in d:
    print(f"- 政策文本变更: {d['policy_commits_total']} 次，日期 {d.get('policy_dates')}")
print("- 判据: 规则不动而名单天天动 = 规则与执行已分离；denounce 只增不减 = 排除即永久")
PY
    else
        echo "- ⚠️ 无 verification 记录（先跑 --sync && --verify）"
    fi
    local s
    s=$(ls -1t "${DATA_DIR}"/pr-sample-*.json 2>/dev/null | head -1 || true)
    if [[ -n "$s" ]]; then
        python3 - "$s" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 名单 PR 抽样 {d['sampled']} 个: bot 合并 {d['bot_merged']} | 有评审/评论 {d['with_review_or_comment']}")
print("  ⚠️ merged_by 全为 bot 意味着『谁做的决定』不在 PR 元数据里（人类动作在 discussion）")
PY
    fi
    echo ""
}

do_status() {
    echo ""
    echo "=== Vouch Registry Cache ==="
    echo "  Total cached: $(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)"
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -10 | while read -r _ts fname; do
            printf "  %-44s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_roster
            sync_rules
            sync_history
            sync_policy_history
            ;;
        --verify)   do_verify ;;
        --sample-prs) do_sample_prs "${2:-10}" ;;
        --extract)  do_extract ;;
        --status)   do_status ;;
        *) echo "Usage: $0 {--sync|--verify|--sample-prs [n]|--extract|--status}"; exit 1 ;;
    esac
}

main "$@"
