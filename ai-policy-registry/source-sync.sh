#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — AI Policy Registry Sync
# 数据对象：项目自愿提交的 AI 使用政策文本（AI_POLICY.md / AI_GUIDELINES.md）
#
# 为什么需要它：开源社区 2026 年的 AI 规则供给散在几千个仓库的单文件里，
#   基金会层只给 suggestions、平台层不可 diff、执行层仅有 ghostty 一类样本。
#   本模块把「政策文本」当作可计数、可 diff 的制度对象。
#
# 两种口径，分开计数，绝不混算：
#   1. curated 对照组（15 个重量级仓库，逐个探测路径）—— 高星、制度后果明确
#   2. 规模分母（GitHub code search filename:AI_POLICY.md）—— 覆盖面，但绝大多数是 0★
#
# 已实测的坑（勿重复踩）：
#   - code search 限速 10 req/min，连续调用会 403；本脚本每轮最多 1 次 search
#   - code search 不支持 stars: 限定（返回 total_count=0），星数只能事后用 core API 补
#   - `torvalds/linux` / `llvm/llvm-project` 等把政策写在文档树里，不在仓库根
#     → 「无独立政策文件」≠「无政策」，输出必须显式区分
#   - raw.githubusercontent 用 HEAD 跟随默认分支，比 hardcode main/master 稳
#
# 2026-11-03 队列评估 P0 落地（10-28 / 10-31 / 11-01 / 11-03 四日信号汇聚）
# NIE 轴：North（规则供给层形成）/ Ostrom（自定规则的基层形态）
#         / Williamson（契约完备性梯度）/ A&R（披露是否变成准入）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/ai-policy-registry"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=25
GH_API="https://api.github.com"
RAW="https://raw.githubusercontent.com"

mkdir -p "${DATA_DIR}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

TOKEN=""
if command -v gh >/dev/null 2>&1; then TOKEN=$(gh auth token 2>/dev/null || true); fi

api_get() {
    local url="$1" out="$2"
    if [[ -n "${TOKEN}" ]]; then
        curl -sfL --max-time "${TIMEOUT}" -H 'Accept: application/vnd.github+json' \
            -H 'User-Agent: pulse-cron' -H "Authorization: Bearer ${TOKEN}" "$url" -o "$out"
    else
        curl -sfL --max-time "${TIMEOUT}" -H 'Accept: application/vnd.github+json' \
            -H 'User-Agent: pulse-cron' "$url" -o "$out"
    fi
}

raw_get() {
    local url="$1" out="$2"
    curl -sfL --max-time "${TIMEOUT}" -H 'User-Agent: pulse-cron' "$url" -o "$out"
}

# 候选路径（按实测命中率排序）
PATHS=(
    "AI_POLICY.md"
    ".github/AI_POLICY.md"
    "AI_GUIDELINES.md"
    ".github/AI_GUIDELINES.md"
    "docs/AI_POLICY.md"
)

# --- curated 对照组：重量级仓库 --------------------------------------------
# 三星级以上、制度后果明确的样本。分「有/无独立政策文件」两组，
# 后者不代表无政策（政策可能在文档树里），只代表「没做成独立文件」。
CURATED=(
    "pytorch/pytorch"
    "grafana/grafana"
    "babel/babel"
    "docker/compose"
    "BurntSushi/ripgrep"
    "ghostty-org/ghostty"
    "rust-lang/rust"
    "nodejs/node"
    "kubernetes/kubernetes"
    "apache/kafka"
    "vercel/next.js"
    "microsoft/vscode"
    "go-gitea/gitea"
    "torvalds/linux"
    "llvm/llvm-project"
)

sync_curated() {
    log "=== curated 对照组（${#CURATED[@]} 仓库） ==="
    local out="${DATA_DIR}/curated-${TODAY}.json"
    local rows="${DATA_DIR}/.curated-rows.tsv"
    : > "$rows"

    local repo p sz path found
    for repo in "${CURATED[@]}"; do
        found=""
        for p in "${PATHS[@]}"; do
            if api_get "${GH_API}/repos/${repo}/contents/${p}" /tmp/.apc 2>/dev/null; then
                sz=$(python3 -c "import json;d=json.load(open('/tmp/.apc'));print(d.get('size',''))" 2>/dev/null || true)
                if [[ -n "$sz" ]]; then found="$p"; path="$p"; break; fi
            fi
        done

        local stars="" pushed="" license=""
        if api_get "${GH_API}/repos/${repo}" /tmp/.apr 2>/dev/null; then
            read -r stars pushed license < <(python3 -c "
import json
d=json.load(open('/tmp/.apr'))
print(d.get('stargazers_count',''), d.get('pushed_at','')[:10], (d.get('license') or {}).get('spdx_id',''))
" 2>/dev/null || echo "  ")
        fi

        if [[ -n "$found" ]]; then
            log "  ${repo} → ${found} (${sz}B, ${stars}★)"
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "yes" "$found" "$sz" "$stars" "$pushed" >> "$rows"
        else
            log "  ${repo} → 无独立政策文件"
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "no" "" "" "$stars" "$pushed" >> "$rows"
        fi
    done

    python3 - "$rows" "$out" "$TODAY" <<'PY'
import csv, json, sys
rows_path, out_path, today = sys.argv[1:4]
out = []
with open(rows_path) as f:
    for line in f:
        parts = line.rstrip('\n').split('\t')
        if len(parts) < 6:
            continue
        repo, has, path, size, stars, pushed = parts[:6]
        out.append({'repo': repo, 'has_standalone_policy': has == 'yes', 'path': path or None,
                    'size_bytes': int(size) if size else None, 'stars': int(stars) if stars else None,
                    'pushed_at': pushed or None})
json.dump({'date': today, 'cohort': 'curated', 'n': len(out), 'repos': out},
          open(out_path, 'w'), indent=1, ensure_ascii=False)
yes = sum(1 for r in out if r['has_standalone_policy'])
print(f"  curated: {yes}/{len(out)} 有独立政策文件")
PY
    rm -f "$rows"
}

# --- 规模分母：code search ------------------------------------------------
# 每次运行只打 1 次 search（限速 10/min，连续打会 403）
sync_denominator() {
    log "=== 规模分母（code search，单次） ==="
    local out="${DATA_DIR}/denominator-${TODAY}.json"
    local q="filename:AI_POLICY.md"
    local enc="filename%3AAI_POLICY.md"
    if api_get "${GH_API}/search/code?q=${enc}&per_page=1" "$out" 2>/dev/null; then
        python3 - "$out" "$TODAY" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"  filename:AI_POLICY.md total_count = {d.get('total_count')}")
print("  ⚠️ 该分母含大量个人/低星仓库，只作『扩散』指标，不作质量证据")
PY
    else
        log "  FAILED（可能触发 code search 限速 10/min，下轮再试）"
    fi
}

# --- 政策文本条款抽取（核心） ---------------------------------------------
# 从已缓存的正文中抽取可机检/不可机检条款。星数需另外传入。
analyze_text() {
    local repo="$1" path="$2" stars="${3:-}" out_file="$4"
    local body="/tmp/.apc-body"
    if ! raw_get "${RAW}/${repo}/HEAD/${path}" "$body"; then
        log "  SKIP ${repo}: 正文抓取失败"
        return
    fi

    local commit_date=""
    if api_get "${GH_API}/repos/${repo}/commits?path=${path}&per_page=1" /tmp/.apc-commits 2>/dev/null; then
        commit_date=$(python3 -c "
import json
try:
    d=json.load(open('/tmp/.apc-commits'))
    print(d[0]['commit']['author']['date'][:10] if d else '')
except Exception:
    print('')
" 2>/dev/null || true)
    fi

    python3 - "$repo" "$path" "$stars" "$commit_date" "$body" "$out_file" <<'PY'
import json, re, sys

repo, path, stars, commit_date, body_path, out_path = sys.argv[1:7]
text = open(body_path, encoding='utf-8', errors='ignore').read()
low = text.lower()

def has(*pats):
    return any(re.search(p, low) for p in pats)

rec = {
    'repo': repo,
    'path': path,
    'size_bytes': len(text.encode('utf-8')),
    'stars': int(stars) if stars and stars.isdigit() else None,
    'last_commit_date': commit_date or None,
    # 可机检条款
    'has_disclosure_clause': has(r'disclos'),
    'has_trailer': has(r'assisted-by', r'co-authored-by', r'generated-by', r'trailer'),
    'trailer_names': re.findall(r'(assisted-by|co-authored-by|generated-by)', low),
    # 不可机检条款（judgment-based）
    'has_human_understanding': has(r'human[- ]in[- ]the[- ]loop', r'fully understand', r'do you understand'),
    # 作用域与排除
    'has_maintainer_exemption': has(r'maintainers?\s+(are|is)\s+exempt', r'appl(y|ies)\s+only\s+to\s+(outside|external)'),
    'has_denounce_or_ban': has(r'denounc', r'blocked? from contributing', r'rejected'),
    'has_aml_specific': has(r'autonomous agents?', r'fully autonomous'),
    # 规则自身的修改规则（Ostrom：规则能不能被改、谁改）
    'has_meta_rule': has(r'changes? to this policy', r'updates? to this policy', r'policy (may|can) change'),
}
rec['machine_checkable_count'] = sum([
    bool(rec['has_disclosure_clause']), bool(rec['has_trailer']),
])
rec['judgment_based_count'] = sum([
    bool(rec['has_human_understanding']), bool(rec['has_maintainer_exemption']),
])
json.dump(rec, open(out_path, 'w'), indent=1, ensure_ascii=False)
print(f"  {repo}: trailer={rec['trailer_names']} exemption={rec['has_maintainer_exemption']} "
      f"human_understanding={rec['has_human_understanding']} last={rec['last_commit_date']}")
PY
}

analyze_all_curated() {
    log "=== 条款抽取（curated 中有政策的样本） ==="
    local cur
    cur=$(ls -1t "${DATA_DIR}"/curated-*.json 2>/dev/null | head -1 || true)
    if [[ -z "$cur" ]]; then log "  先跑 --sync"; return; fi
    local out="${DATA_DIR}/clauses-${TODAY}.jsonl"
    : > "$out"
    python3 - "$cur" <<'PY' | while IFS=$'\t' read -r repo path stars; do
import json, sys
d = json.load(open(sys.argv[1]))
for r in d['repos']:
    if r['has_standalone_policy']:
        print(f"{r['repo']}\t{r['path']}\t{r['stars'] or ''}")
PY
        analyze_text "$repo" "$path" "$stars" /tmp/.apc-clause.json
        cat /tmp/.apc-clause.json >> "$out"
        echo >> "$out"
    done
}

# --- 提取报告（供上游日报消费） -------------------------------------------
do_extract() {
    echo ""
    echo "=== AI Policy Registry — 项目级 AI 政策文本 ==="
    local cur den cl
    cur=$(ls -1t "${DATA_DIR}"/curated-*.json 2>/dev/null | head -1 || true)
    den=$(ls -1t "${DATA_DIR}"/denominator-*.json 2>/dev/null | head -1 || true)
    cl=$(ls -1t "${DATA_DIR}"/clauses-*.jsonl 2>/dev/null | head -1 || true)

    if [[ -n "$cur" ]]; then
        python3 - "$cur" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
yes = [r for r in d['repos'] if r['has_standalone_policy']]
no = [r for r in d['repos'] if not r['has_standalone_policy']]
print(f"- curated 队列: {d['n']} 仓库 | 有独立政策文件 {len(yes)} | 无 {len(no)}")
print(f"- 有政策的: {', '.join(r['repo'] for r in yes)}")
print(f"- 无独立文件的: {', '.join(r['repo'] for r in no)}")
print("  ⚠️ 无文件 ≠ 无政策（内核/LLVM 写在文档树里），引用时必须区分")
PY
    else
        echo "- ⚠️ 无 curated 记录（先跑 --sync）"
    fi

    if [[ -n "$den" ]]; then
        python3 - "$den" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- 规模分母 filename:AI_POLICY.md total_count = {d.get('total_count')}")
PY
    fi

    echo "- 判据: 同一份政策文件里『可机检条款 vs 判断型条款』的比值，就是这份契约的执行成本结构"
    echo ""
}

do_status() {
    echo ""
    echo "=== AI Policy Registry Cache ==="
    echo "  Total cached: $(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)"
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -8 | while read -r _ts fname; do
            printf "  %-46s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)
            sync_curated
            sync_denominator
            ;;
        --analyze) analyze_all_curated ;;
        --extract) do_extract ;;
        --status)  do_status ;;
        *) echo "Usage: $0 {--sync|--analyze|--extract|--status}"; exit 1 ;;
    esac
}

main "$@"
