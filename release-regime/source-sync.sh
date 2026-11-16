#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — Release Regime Sync（公共资金建的系统，以什么形式释出）
# =============================================================================
# 数据对象：IRS-Public（美国政府开源软件官方发布组织）全部公开仓库的
#   **释出形式**字段 —— 不是发了几条新闻，而是「公共资金建的东西，
#   最终以什么许可、什么可达性、什么产权归属交到公众手上」。
#
# 为什么值得一个独立模块（第五个 P0）：
#   前四个 P0 的数据对象分别是 测量行为（oss-scanner / osv-origins）、
#   制度文本本体（ai-policy-registry）、规则被编译成 CI（vouch-registry）、
#   价格（bounty-ledger）。本模块的数据对象是 **产权释出形式** ——
#   公共资金 → 代码 → 许可 → 公众 这条链上唯一可批量计数的一环。
#
# NIE 轴：Coase（公共组织的生产边界：做成 repo 而不做成采购合同）
#         / A&R（同一发布组织的 10 个仓库给出 3 种产权形式 —— 包容性不是一个标签而是一个分布）
#         / North（成文法依据 SOURCE Act 2024 / OMB M-16-21 / FAR Part 27 / FITARA
#                  如何被翻译成仓库级实践）
#         / Ostrom（公共池塘：纳税人出资的产物被置于何种可复用边界内）
#
# ---
# 已实测的坑（勿重复踩）：
#   1. GitHub 的 `license` 字段为 `null` 不等于「无许可」—— direct-file 等仓库的
#      license=NOASSERTION 表示**有 LICENSE 文件但 GitHub 无法识别**，
#      而 `null` 只表示未检出文件。两者必须分开计数，否则会把「自定义许可」
#      误报成「未授权」。本脚本把这两种状态分别落到 licensed_recognized /
#      licensed_unrecognized / no_license_file 三档，并对每仓落一份 LICENSE 首 60 行。
#   2. 组织 API 一页 100 个，但 IRS-Public 目前 10 个仓库；仍按分页写死上限，
#      避免将来仓库变多时静默截断。
#   3. 仓库级 `pushed_at` 只能说明「有推送」，不说明「有释出」。判断释出活跃度
#      必须同时取默认分支最近提交日期与 release 列表。
#
# Usage:
#   release-regime-sync.sh --sync     抓取全部仓库元数据 + LICENSE 文本 + 提交/发布活动
#   release-regime-sync.sh --verify   从快照复算，输出释出形式分布
#   release-regime-sync.sh --status   查看缓存
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/release-regime"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=30
GH_API="https://api.github.com"
ORG="IRS-Public"

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

# --- 1. 仓库清单 -----------------------------------------------------------
sync_repos() {
    log "抓取 ${ORG} 仓库清单（分页，上限 3 页）"
    local all="${DATA_DIR}/repos-${TODAY}.json"
    echo '[]' > "${all}"
    local page=1 tmp
    while [[ $page -le 3 ]]; do
        tmp=$(mktemp)
        if ! api_get "${GH_API}/orgs/${ORG}/repos?per_page=100&page=${page}&sort=updated" "$tmp"; then
            log "WARN: 第 ${page} 页抓取失败，停止分页"
            rm -f "$tmp"; break
        fi
        python3 - "$all" "$tmp" <<'PY'
import json, sys
acc_path, page_path = sys.argv[1], sys.argv[2]
acc = json.load(open(acc_path))
try:
    page = json.load(open(page_path))
except Exception:
    page = []
if not isinstance(page, list):
    page = []
json.dump(acc + page, open(acc_path, 'w'), ensure_ascii=False, indent=1)
print(len(page))
PY
        local n
        n=$(python3 -c "import json;print(len(json.load(open('$tmp'))))" 2>/dev/null || echo 0)
        rm -f "$tmp"
        [[ "$n" -lt 100 ]] && break
        page=$((page + 1))
    done
    log "仓库数：$(python3 -c "import json;print(len(json.load(open('${all}'))))")"
}

# --- 2. 逐仓释出形态 -------------------------------------------------------
sync_release_form() {
    local repos="${DATA_DIR}/repos-${TODAY}.json"
    mapfile -t names < <(python3 -c "
import json
for r in json.load(open('${repos}')):
    print(r['name'])
")
    log "逐仓抓取默认分支最近提交 / releases / 根 LICENSE（${#names[@]} 个仓库）"
    for name in "${names[@]}"; do
        local out="${DATA_DIR}/repo-${name}-${TODAY}.json"
        local commit_file="${DATA_DIR}/commits-${name}-${TODAY}.json"
        local rel_file="${DATA_DIR}/releases-${name}-${TODAY}.json"
        api_get "${GH_API}/repos/${ORG}/${name}" "${out}" || log "WARN: repo meta 失败 ${name}"
        api_get "${GH_API}/repos/${ORG}/${name}/commits?per_page=30" "${commit_file}" \
            || echo '[]' > "${commit_file}"
        api_get "${GH_API}/repos/${ORG}/${name}/releases?per_page=20" "${rel_file}" \
            || echo '[]' > "${rel_file}"
        # LICENSE 文本（大小写两种常见文件名都试一次）
        local lic="${DATA_DIR}/LICENSE-${name}-${TODAY}.txt"
        : > "${lic}"
        for cand in LICENSE LICENSE.md LICENSE.txt COPYING; do
            local branch
            branch=$(python3 -c "import json;print(json.load(open('${out}')).get('default_branch','main'))" 2>/dev/null || echo main)
            local code
            code=$(curl -sSL --max-time "${TIMEOUT}" -w '%{http_code}' -o "${lic}.tmp" \
                -H 'User-Agent: pulse-cron' \
                "https://raw.githubusercontent.com/${ORG}/${name}/${branch}/${cand}" || echo 000)
            if [[ "$code" == "200" ]]; then
                { echo "# file: ${cand}"; head -60 "${lic}.tmp"; } > "${lic}"
                rm -f "${lic}.tmp"
                break
            fi
            rm -f "${lic}.tmp"
        done
    done
}

# --- 3. 复算 -----------------------------------------------------------------
do_verify() {
    local repos="${DATA_DIR}/repos-$(date +%Y-%m-%d).json"
    [[ -f "$repos" ]] || repos=$(ls -1t "${DATA_DIR}"/repos-*.json 2>/dev/null | head -1 || true)
    if [[ -z "${repos}" || ! -f "$repos" ]]; then
        echo "❌ 无快照，先跑 --sync"; exit 1
    fi
    python3 - "$repos" "${DATA_DIR}" <<'PY'
import json, sys, glob, os, collections
repos_path, data_dir = sys.argv[1], sys.argv[2]
repos = json.load(open(repos_path))

def lic_class(r):
    lic = r.get('license')
    if not lic:
        return 'no_license_file'
    spdx = lic.get('spdx_id')
    if spdx in (None, 'NOASSERTION', ''):
        return 'licensed_unrecognized'
    return 'licensed_recognized'

cls = collections.Counter(lic_class(r) for r in repos)
spdx = collections.Counter(((r.get('license') or {}).get('spdx_id') or 'NONE') for r in repos)
archived = sum(1 for r in repos if r.get('archived'))
fork = sum(1 for r in repos if r.get('fork'))
stars = sorted(((r.get('stargazers_count', 0), r['name']) for r in repos), reverse=True)

print("=== 释出形式分布（{} 个仓库，{}）====".format(len(repos), os.path.basename(repos_path)))
for k in ('licensed_recognized', 'licensed_unrecognized', 'no_license_file'):
    print("  {:<24} {}".format(k, cls.get(k, 0)))
print("  spdx 明细: " + ", ".join("{}×{}".format(k, v) for k, v in spdx.most_common()))
print("  archived {} / fork {} ".format(archived, fork))

# 活动度：默认分支 30 条提交的时间跨度 + releases 数
rows = []
for r in repos:
    name = r['name']
    cf = sorted(glob.glob(os.path.join(data_dir, "commits-{}-*.json".format(name))))
    rf = sorted(glob.glob(os.path.join(data_dir, "releases-{}-*.json".format(name))))
    ncommits = nrel = 0
    span_days = None
    if cf:
        try:
            c = json.load(open(cf[-1]))
            c = c if isinstance(c, list) else []
            ncommits = len(c)
            dates = [x['commit']['committer']['date'][:10] for x in c if x.get('commit')]
            if dates:
                import datetime as dt
                d = sorted(dates)
                span_days = (dt.date.fromisoformat(d[-1]) - dt.date.fromisoformat(d[0])).days
        except Exception:
            pass
    if rf:
        try:
            rr = json.load(open(rf[-1]))
            nrel = len(rr) if isinstance(rr, list) else 0
        except Exception:
            pass
    rows.append((r.get('stargazers_count', 0), name, lic_class(r), r.get('pushed_at', '')[:10],
                 ncommits, span_days, nrel))

print("\n=== 逐仓（按星数降序）===")
print("  stars  repo                  lic_class              pushed       commits30 span(d) releases")
for s, n, c, p, nc, sd, nr in sorted(rows, reverse=True):
    print("  {:>5}  {:20} {:22} {:12} {:>3}     {:>5}    {:>3}".format(
        s, n, c, p, nc, ('-' if sd is None else sd), nr))
print("\n判据：licensed_recognized 占比 = 公众能否用机器读到产权边界；")
print("      licensed_unrecognized = 有产权声明但不可机检（自定义/修改过的许可）；")
print("      no_license_file = GitHub 未检出任何许可文件，法律上默认保留全部权利。")
PY
}

do_status() {
    echo ""
    echo "=== Release Regime Cache ==="
    echo "  Total cached: $(find "${DATA_DIR}" -maxdepth 1 -type f 2>/dev/null | wc -l)"
    find "${DATA_DIR}" -maxdepth 1 -type f -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -8 | while read -r _ts fname; do
            printf "  %-46s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
}

main() {
    case "${1:-}" in
        --sync)   sync_repos; sync_release_form ;;
        --verify) do_verify ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--verify|--status}"; exit 1 ;;
    esac
}

main "$@"
