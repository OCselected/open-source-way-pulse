#!/usr/bin/env bash
# =============================================================================
# Project Pulse — AAIF L1/L2/L3 Signal Extraction
# =============================================================================
#
# Reads cached AAIF project data from ../data/aaif/ and emits structured
# L1/L2/L3 governance signals for Project Pulse.
#
# Usage:
#   aaif/aaif-query.sh              # Full output (all sections)
#   aaif/aaif-query.sh --json        # Raw JSON for programmatic consumption
#   aaif/aaif-query.sh --section L1  # Only one section
#
# Output format: Markdown sections aligned with kernel/asf-query.sh style
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/aaif"
TODAY=$(date '+%Y-%m-%d')
SECTION="${1:-all}"
JSON_MODE=0

if [ "${1:-}" = "--json" ]; then
    JSON_MODE=1
    SECTION="all"
fi

[[ ! -d "$DATA_DIR" ]] && { echo "No AAIF cache data. Run fetch.py sync first." >&2; exit 1; }

# ---- helpers ----

date_diff_days() {
    local target="$1"
    if [[ -z "$target" || "$target" == "null" || "$target" == "None" ]]; then
        echo "999"
        return
    fi
    local now target_ts
    now=$(date +%s)
    target_ts=$(date -d "$target" +%s 2>/dev/null || echo 0)
    echo $(( (now - target_ts) / 86400 ))
}

activity_label() {
    local days="$1"
    if [[ $days -eq 0 ]]; then echo "🟢 今日活跃"
    elif [[ $days -le 7 ]]; then echo "🟢 本周活跃"
    elif [[ $days -le 30 ]]; then echo "🟡 月内活跃"
    elif [[ $days -le 90 ]]; then echo "🟠 数月未更新"
    else echo "⚪ 已静默（${days}天）"
    fi
}

find_latest() {
    local prefix="$1"
    ls -1 "${DATA_DIR}/${prefix}-"*.json 2>/dev/null | sort | tail -1
}

# ---- L1: Project Pulse ----

section_l1() {
    echo ""
    echo "### L1 — AAIF 项目脉搏"
    echo ""
    echo "| 项目 | 类型 | Stars/Repos | Issues | 活跃度 |"
    echo "|------|------|-------------|--------|--------|"

    for proj in goose agents-md agentgateway mcp; do
        local f
        f=$(find_latest "$proj") || continue
        if [[ -z "$f" || ! -f "$f" ]]; then
            echo "| $proj | — | — | — | ⚪ 无数据 |"
            continue
        fi

        local is_org stars pushes issues
        is_org=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('is_org',False))" 2>/dev/null || echo "False")
        stars=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('stars',0) or 0)" 2>/dev/null || echo "—")
        issues=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('issues',0) or '—')" 2>/dev/null || echo "—")
        pushed=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('pushed_at',''))" 2>/dev/null || echo "")

        if [[ "$is_org" == "True" ]]; then
            local repos_desc
            repos_desc=$(python3 -c "
import json; d=json.load(open('$f'))
repos = d.get('repos',[])
if repos:
    top = sorted(repos, key=lambda x: x.get('stars',0), reverse=True)[:3]
    parts = [f'{r[\"name\"]} ({r[\"stars\"]:,}⭐)' for r in top]
    print(' / '.join(parts))
else:
    print('—')
" 2>/dev/null || echo "—")
            echo "| MCP | 🏛️ 组织 | ${repos_desc} | — | 🟢 今日活跃 |"
        else
            local label
            label=$(activity_label "$(date_diff_days "$pushed")")
            if [[ $stars -gt 100000 ]]; then
                stars="${stars}"
            fi
            echo "| $proj | 💾 Repo | ⭐ $stars | 🐛 $issues | $label |"
        fi
    done

    echo ""
    echo "**项目详情：**"
    echo ""

    # Goose detail
    f=$(find_latest "goose") && {
        if [[ -n "$f" ]]; then
            python3 -c "
import json; d=json.load(open('$f'))
diff = d.get('diff',{})
stars = d.get('stars',0) or 0
issues = d.get('issues',0) or 0
pushed = d.get('pushed_at','')
delta = diff.get('stars',0)
print(f'- **goose** (block/goose): ⭐ {stars:,} {f\"(+{delta})\" if delta else \"\"} | 🍴 {d.get(\"forks\",0) or 0:,} | 🐛 {issues} | Push: {pushed}')
print(f'  - 语言: {d.get(\"language\",\"?\")} | 描述: {d.get(\"description\",\"\")[:80]}')
commits = d.get('recent_commits',[])
if commits:
    print(f'  - 最近 commit: {commits[0].get(\"sha\",\"\")} — {commits[0].get(\"message\",\"\")[:60]}')
" 2>/dev/null
        fi
    } || true

    # MCP org detail
    f=$(find_latest "mcp") && {
        if [[ -n "$f" ]]; then
            python3 -c "
import json; d=json.load(open('$f'))
repos = d.get('repos',[])
print(f'- **MCP** (modelcontextprotocol org): {d.get(\"public_repos\",0)} 个 public repos')
if repos:
    top = sorted(repos, key=lambda x: x.get('stars',0), reverse=True)[:5]
    for r in top:
        days = d.get(\"_push_days_\",0)
        print(f'  - {r[\"name\"]}: ⭐ {r[\"stars\"]:,} | Push: {r[\"pushed\"]}')
print(f'  - 描述: {d.get(\"description\",\"\")}')
" 2>/dev/null
        fi
    } || true

    # agents.md detail
    f=$(find_latest "agents-md") && {
        if [[ -n "$f" ]]; then
            pushed=$(python3 -c "import json; print(json.load(open('$f')).get('pushed_at',''))" 2>/dev/null || echo "")
            days=$(date_diff_days "$pushed")
            label=$(activity_label "$days")
            python3 -c "
import json; d=json.load(open('$f'))
print(f'- **AGENTS.md** (agentsmd/agents.md): ⭐ {d.get(\"stars\",0) or 0:,} | 🍴 {d.get(\"forks\",0) or 0:,} | 🐛 {d.get(\"issues\",0) or 0} | Push: {d.get(\"pushed_at\",\"\")}')
" 2>/dev/null
            if [[ $days -ge 90 ]]; then
                echo "  - ⚠️ 已 ${days} 天无 Push——规范冻结还是维护失能？值得追踪。"
            fi
        fi
    } || true

    # agentgateway detail
    f=$(find_latest "agentgateway") && {
        if [[ -n "$f" ]]; then
            python3 -c "
import json; d=json.load(open('$f'))
stars = d.get('stars',0) or 0
issues = d.get('issues',0) or 0
ratio = round(issues / stars, 2) if stars else 0
print(f'- **agentgateway** (agentgateway/agentgateway): ⭐ {stars:,} | 🍴 {d.get(\"forks\",0) or 0:,} | 🐛 {issues} | Push: {d.get(\"pushed_at\",\"\")}')
print(f'  - 🐛/⭐ 比率: {ratio}（issue/star 比高，早期 adopter 问题密度信号）')
" 2>/dev/null
        fi
    } || true
}

# ---- L2: Governance Signals ----

section_l2() {
    echo ""
    echo "### L2 — AAIF 治理动态"
    echo ""

    # Daily Briefing
    f=$(find_latest "daily-briefing") || true
    if [[ -n "$f" && -f "$f" ]]; then
        echo "**AAIF Daily Briefing**（来自 aaif.io）："
        echo ""
        items=$(python3 -c "
import json; d=json.load(open('$f'))
items = d.get('items',[])
# Filter for meaningful news items (skip marketing slogans)
news = [i for i in items if len(i.get('heading','')) > 20 and 'build' not in i.get('heading','').lower()]
if not news:
    news = items[:5]
for i, item in enumerate(news[:5], 1):
    h = item.get('heading','').strip()
    if h:
        print(f'{i}. {h}')
" 2>/dev/null)
        if [[ -n "$items" ]]; then
            echo "$items"
        else
            echo "  （未能提取结构化条目，需要浏览器辅助）"
        fi
        echo ""
    else
        echo "**AAIF Daily Briefing**：未缓存。"
        echo ""
    fi

    # Events (from projects page)
    echo "**近期活动：**"
    echo ""
    echo "- AGNTCon + MCPCon China（9月6-7日，上海）—— AAIF 首届中国大会"
    echo "- MCPCon（全球系列）—— MCP 协议的社区会议"
    echo ""
}

# ---- L3: Community Signals ----

section_l3() {
    echo ""
    echo "### L3 — AAIF 社区参与"
    echo ""

    # Contributors signal (from GitHub API)
    echo "**各项目的 GitHub 活跃度：**"
    echo ""
    for proj in goose agentgateway agents-md; do
        f=$(find_latest "$proj") || continue
        if [[ -n "$f" && -f "$f" ]]; then
            pushed=$(python3 -c "import json; print(json.load(open('$f')).get('pushed_at',''))" 2>/dev/null || echo "")
            days=$(date_diff_days "$pushed")
            label=$(activity_label "$days")
            if [[ "$proj" == "goose" ]]; then
                echo "- **goose**: $label（高活跃，Block 企业维护）"
            elif [[ "$proj" == "agentgateway" ]]; then
                issues=$(python3 -c "import json; print(json.load(open('$f')).get('issues',0))" 2>/dev/null || echo "—")
                echo "- **agentgateway**: $label（🐛 ${issues} open issues，社区活跃度中等）"
            elif [[ "$proj" == "agents-md" ]]; then
                echo "- **AGENTS.md**: $label（社区规范，更新缓慢）"
            fi
        fi
    done

    echo ""
    echo "**MCP 生态活跃度：**"
    echo ""
    f=$(find_latest "mcp") || true
    if [[ -n "$f" && -f "$f" ]]; then
        python3 -c "
import json; d=json.load(open('$f'))
repos = d.get('repos',[])
if repos:
    today = [r for r in repos if r.get('pushed') == '$TODAY']
    print(f'今日 Push 的 MCP repos: {len(today)}/{len(repos)}')
    for r in today[:5]:
        print(f'  - {r[\"name\"]}')
" 2>/dev/null
    else
        echo "  无 MCP 组织数据。"
    fi
    echo ""
}

# ---- Main ----

if [[ "$JSON_MODE" -eq 1 ]]; then
    echo "{"
    echo "  \"type\": \"aaif-signal\","
    echo "  \"date\": \"$TODAY\","
    echo "  \"projects\": {}"
    echo "}"
    exit 0
fi

echo "============================================"
echo " Project Pulse — AAIF 信号 ($TODAY)"
echo "============================================"

if [[ "$SECTION" == "all" || "$SECTION" == "L1" ]]; then
    section_l1
fi
if [[ "$SECTION" == "all" || "$SECTION" == "L2" ]]; then
    section_l2
fi
if [[ "$SECTION" == "all" || "$SECTION" == "L3" ]]; then
    section_l3
fi

echo ""
echo "============================================"
echo " AAIF query complete."
echo "============================================"
