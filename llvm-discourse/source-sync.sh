#!/usr/bin/env bash
# =============================================================================
# Project Pulse v2 — LLVM Discourse (治理级一手文本) Institutional Signals Sync
# Data sources (Discourse JSON API, no HTML parsing, no WAF):
#   - https://discourse.llvm.org/c/46.json   公告 (Announcements)
#   - https://discourse.llvm.org/c/20.json   社区 (Community)
# Institutional framing: 项目官方治理公告是「终止判据 / 投票 / 名册变更」这类
#   新闻稿从不写的信息的唯一一手渠道。LLVM 2014 重许可八年收尾帖（2026-11-19）
#   只出现在这里，媒体均为转述。North 轴（制度变迁文本）/ Ostrom 轴（边界与
#   终止规则）。
# 判据（2026-11-24 实测）：分类 id 46 = Announcements（395 主题），20 = Community
#   （412 主题）。旧路径 /c/announcements/8 与 /c/announcements.rss 已失效（8 现为
#   LLDB 分类）—— 必须按分类 id 取 .json，不要按 slug 猜。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/llvm-discourse"
TODAY=$(date +%Y-%m-%d)
TIMEOUT=25
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
BASE="https://discourse.llvm.org"
CATS=("46:announce" "20:community")

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

do_sync() {
    local fail=0
    for pair in "${CATS[@]}"; do
        local cid="${pair%%:*}" slug="${pair##*:}"
        local out="${DATA_DIR}/${slug}-${cid}-${TODAY}.json"
        if [[ -f "$out" ]]; then log "(cached) ${slug} ${cid} ${TODAY}"; continue; fi
        log "Fetching ${BASE}/c/${cid}.json ..."
        if retry "curl -s -L --max-time ${TIMEOUT} -A '${UA}' '${BASE}/c/${cid}.json' -o '${out}'"; then
            if grep -q '"topic_list"' "$out"; then
                log "  Saved ${out} ($(wc -c < "$out") bytes)"
            else
                log "  BAD payload (no topic_list)"; rm -f "$out"; fail=1
            fi
        else
            log "  FAILED"; rm -f "$out"; fail=1
        fi
    done
    # 最新快照软链，供下游读取
    for pair in "${CATS[@]}"; do
        local cid="${pair%%:*}" slug="${pair##*:}"
        [[ -f "${DATA_DIR}/${slug}-${cid}-${TODAY}.json" ]] && \
            ln -sf "${slug}-${cid}-${TODAY}.json" "${DATA_DIR}/${slug}-latest.json"
    done
    return "$fail"
}

do_verify() {
    local fail=0
    for pair in "${CATS[@]}"; do
        local cid="${pair%%:*}" slug="${pair##*:}"
        local f="${DATA_DIR}/${slug}-latest.json"
        printf '  %-12s ' "$slug"
        if [[ ! -f "$f" ]]; then echo "MISSING"; fail=1; continue; fi
        python3 - "$f" "$slug" "$cid" <<'PY' || fail=1
import json, sys
f, slug, cid = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(f))
t = d.get("topic_list", {}).get("topics", [])
if not t:
    print("EMPTY topic_list"); sys.exit(1)
# 置顶的 "About the <category> category" 主题 created_at 是最早而非最新，
# 取日期须按 created_at 排序而不是按数组顺序（Discourse 列表把 pinned 放最前）。
real = [x for x in t if not x.get("pinned")]
newest = max(real or t, key=lambda x: x.get("created_at") or "")
print("%-9s topics=%2d  newest=%s  %s" % ("OK", len(t), newest.get("created_at", "?")[:10], newest.get("title", "")[:52]))
PY
    done
    return "$fail"
}

do_status() {
    echo ""
    echo "=== LLVM Discourse Institutional Signals Cache ==="
    echo ""
    local total
    total=$(find "${DATA_DIR}" -maxdepth 1 -type f -name '*.json' 2>/dev/null | wc -l)
    echo "  Snapshot files: ${total}"
    echo ""
    find "${DATA_DIR}" -maxdepth 1 -type f -name '*.json' -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -10 \
        | while read -r _ts fname; do
            printf "  %-40s %8d bytes\n" "$fname" "$(wc -c < "${DATA_DIR}/${fname}")"
        done
    echo ""
    [[ -f "${DATA_DIR}/announce-latest.json" ]] && do_verify
    echo ""
}

main() {
    case "${1:-}" in
        --sync)   do_sync ;;
        --verify) do_verify ;;
        --status) do_status ;;
        *) echo "Usage: $0 {--sync|--verify|--status}"; exit 1 ;;
    esac
}

main "$@"
