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
    # 用 "名字-YYYY..." 的日期模式精确匹配，避免前缀互相吞掉：
    # find_latest "mcp" 曾匹配到 mcp-directory-*.json，导致 MCP 组织数据显示为 0 star。
    ls -1 "${DATA_DIR}/${prefix}-"[0-9][0-9][0-9][0-9]-*.json 2>/dev/null | sort | tail -1
}

# ---- L1: Project Pulse ----

section_l1() {
    echo ""
    echo "### L1 — AAIF 项目脉搏"
    echo ""
    echo "| 项目 | 类别 | Stars/Repos | Issues | 活跃度 |"
    echo "|------|------|-------------|--------|--------|"

    # 项目列表完全由注册表驱动（v2 起 10 个项目）。
    # 硬编码项目名的写法在 2026-10 已经失效：注册表扩到 10 个，
    # 硬编码只覆盖 4 个，新增 6 个永远不会出现在日报里。
    local projs
    projs=$(AAIF_DIR="$SCRIPT_DIR" python3 - "$DATA_DIR" <<'PYEOF'
import sys, os, glob, json
sys.path.insert(0, os.environ['AAIF_DIR'])
from fetch import parse_registry, REGISTRY
data_dir = sys.argv[1]
for p in parse_registry(REGISTRY):
    name = p.get('name')
    files = sorted(glob.glob(os.path.join(data_dir, f"{name}-*.json")))
    if not files:
        print(f"{name}\t{p.get('category','?')}\tSKIP\t\t")
        continue
    d = json.load(open(files[-1]))
    is_org = d.get('is_org', False)
    if is_org:
        repos = d.get('repos', [])
        latest = max((r.get('pushed', '') for r in repos), default='') or '—'
        print(f"{name}\t{p.get('category','?')}\tORG\t{len(repos)}\t—\t最新 push {latest}")
        continue
    stars = d.get('stars', 0) or 0
    issues = d.get('issues', 0)
    issues = issues if issues is not None else '—'
    pushed = d.get('pushed_at', '') or ''
    if not stars and not pushed:
        # 区分「真的是非仓库源」和「取数失败」——后者绝不能显示成正常状态，
        # 否则 rate limit 会把 10 个项目全伪装成网站。
        err = d.get('_error', '')
        if err:
            short = 'rate limit' if '403' in err else err[:30]
            print(f"{name}\t{p.get('category','?')}\tERR\t—\t—\t取数失败: {short}")
        else:
            print(f"{name}\t{p.get('category','?')}\tWEB\t—\t—\t（非仓库源）")
        continue
    print(f"{name}\t{p.get('category','?')}\tREPO\t{stars}\t{issues}\t{pushed}")
PYEOF
)

    while IFS=$'\t' read -r name cat kind stars issues pushed; do
        [[ -z "$name" ]] && continue
        if [[ "$kind" == "SKIP" ]]; then
            echo "| $name | $cat | — | — | ⚪ 无数据 |"
            continue
        fi
        if [[ "$kind" == "WEB" ]]; then
            echo "| $name | $cat | 🌐 网站 | — | — |"
            continue
        fi
        if [[ "$kind" == "ERR" ]]; then
            echo "| $name | $cat | ❓ 取数失败 | — | $pushed |"
            continue
        fi
        if [[ "$kind" == "ORG" ]]; then
            # org 没有 stars / pushed_at 字段，不能按 repo 的活跃度口径判定，
            # 否则会显示成「静默 999 天」的假信号。
            echo "| $name | $cat | 🏛️ org（$stars repos） | — | $pushed |"
            continue
        fi
        local label days
        days=$(date_diff_days "$pushed")
        label=$(activity_label "$days")
        echo "| $name | $cat | ⭐ $stars | 🐛 $issues | $label |"
    done <<< "$projs"

    echo ""
    echo "**项目详情：**"
    echo ""

    # 详情同样由注册表驱动：只对 watch_level=high 且近 90 天有 push 的项目展开
    AAIF_DIR="$SCRIPT_DIR" python3 - "$DATA_DIR" <<'PYEOF'
import sys, os, glob, json, datetime
sys.path.insert(0, os.environ['AAIF_DIR'])
from fetch import parse_registry, REGISTRY
data_dir = sys.argv[1]
today = datetime.date.today()

for p in parse_registry(REGISTRY):
    name = p.get('name')
    files = sorted(glob.glob(os.path.join(data_dir, f"{name}-*.json")))
    if not files:
        continue
    d = json.load(open(files[-1]))
    if d.get('is_org'):
        repos = d.get('repos', [])
        print(f"- **{name}** (org, {d.get('public_repos',0)} public repos)")
        for r in sorted(repos, key=lambda x: x.get('stars', 0), reverse=True)[:3]:
            print(f"  - {r['name']}: ⭐ {r['stars']:,} | Push: {r.get('pushed','')}")
        continue
    stars = d.get('stars', 0) or 0
    if not stars:
        continue
    pushed = d.get('pushed_at', '') or ''
    days = 999
    if pushed:
        try:
            days = (today - datetime.date.fromisoformat(pushed[:10])).days
        except Exception:
            pass
    delta = d.get('diff', {}).get('stars', 0)
    dtxt = f" (+{delta})" if delta else ""
    lic = p.get('license', '') or '-'
    print(f"- **{name}** ({p.get('repo','')}): ⭐ {stars:,}{dtxt} | 🍴 {d.get('forks',0) or 0:,} | 🐛 {d.get('issues',0) or 0} | Push: {pushed}")
    print(f"  - 类别: {p.get('category','?')} | 许可: {lic} | 赞助: {p.get('sponsor','-')}")
    commits = d.get('recent_commits', [])
    if commits:
        print(f"  - 最近 commit: {commits[0].get('sha','')[:8]} — {commits[0].get('message','')[:60]}")
    if stars and (d.get('issues') or 0):
        ratio = round((d.get('issues') or 0) / stars, 2)
        if ratio >= 0.03:
            print(f"  - 🐛/⭐ 比率: {ratio}（issue/star 偏高，问题密度信号）")
    if days >= 90:
        print(f"  - ⚠️ 已 {days} 天无 Push——规范冻结还是维护失能？值得追踪。")
    if lic in ('NONE', '', '-') or lic.startswith('NOASSERTION'):
        print(f"  - 🚨 许可证异常（{lic}）：AAIF 自我定位是 open standards，此项是制度风险。")
PYEOF
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
    # 由注册表驱动（v2 起 10 个项目），不再硬编码 —— 硬编码只能覆盖部分项目，
    # 新增项目永远不会出现在日报里。
    AAIF_DIR="$SCRIPT_DIR" python3 - "$DATA_DIR" <<'PYEOF'
import sys, os, glob, json, datetime
sys.path.insert(0, os.environ['AAIF_DIR'])
from fetch import parse_registry, REGISTRY
data_dir = sys.argv[1]
today = datetime.date.today()
rows = []
for p in parse_registry(REGISTRY):
    name = p.get('name')
    files = sorted(glob.glob(os.path.join(data_dir, f"{name}-*.json")))
    if not files:
        continue
    d = json.load(open(files[-1]))
    if d.get('is_org') or not (d.get('stars') or 0):
        continue
    pushed = d.get('pushed_at', '') or ''
    try:
        days = (today - datetime.date.fromisoformat(pushed[:10])).days
    except Exception:
        days = 999
    if days <= 1:
        label = "🟢 今日活跃"
    elif days <= 7:
        label = "🟢 本周活跃"
    elif days <= 30:
        label = "🟡 本月活跃"
    elif days <= 90:
        label = "🟠 数月未更新"
    else:
        label = f"⚪ 已静默（{days}天）"
    rows.append((days, name, label, d.get('issues') or 0, p.get('sponsor', '-')))
for days, name, label, issues, sponsor in sorted(rows):
    print(f"- **{name}**: {label}（🐛 {issues} open issues｜{sponsor}）")
PYEOF

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
section_l4() {
    local f
    f=$(find_latest "mcp-governance") || true
    if [[ -z "$f" || ! -f "$f" ]]; then
        echo ""
        echo "### L4 — MCP 治理演化"
        echo ""
        echo "**MCP 治理信号**：未缓存。运行 \`mcp-governance-fetch.py sync\`。"
        echo ""
        return
    fi

    echo ""
    echo "### L4 — MCP 治理演化"
    echo ""

    # 基础表格
    echo "| 指标 | 当前值 | 说明 |"
    echo "|------|--------|------|"
    local spec_ver servers publishers compliance_hits org_repos
    spec_ver=$(python3 -c "import json; d=json.load(open('$f')); print(d['spec_versions']['current'] or '?')" 2>/dev/null)
    servers=$(python3 -c "import json; d=json.load(open('$f')); s=d['mcp_directory'].get('stats',{}); print(s.get('servers','?'))" 2>/dev/null)
    publishers=$(python3 -c "import json; d=json.load(open('$f')); s=d['mcp_directory'].get('stats',{}); print(s.get('publishers','?'))" 2>/dev/null)
    compliance_hits=$(python3 -c "import json; d=json.load(open('$f')); print(d['compliance_scan'].get('total_hits',0))" 2>/dev/null)
    org_repos=$(python3 -c "import json; d=json.load(open('$f')); print(d['mcp_org'].get('repos_count',0))" 2>/dev/null)

    echo "| MCP spec 版本 | ${spec_ver} | 当前最新协议版本 |"
    echo "| MCP.org 仓库数 | ${org_repos} | GitHub 组织下 public repos |"
    echo "| mcp.directory Server 数 | ${servers} | 第三方目录，代表生态规模 |"
    echo "| mcp.directory Publisher 数 | ${publishers} | 第三方目录，代表生态参与度 |"
    echo "| 合规关键词命中 | ${compliance_hits}/10 页 | license/compliance/sbom 等 |"

    echo ""

    # Publisher 分布 — 剩余控制权信号
    echo "**Publisher 分布（剩余控制权信号）：**"
    echo ""
    python3 -c "
import json
d = json.load(open('$f'))
md = d['mcp_directory']
top = md['top_publishers'][:10]
print('| Publisher | Server 数 | 归属 |')
print('|-----------|----------|------|')
china = {p['slug'] for p in md.get('china_publishers',[])}
enterprise = {p['slug'] for p in md.get('enterprise_publishers',[])}
for p in top:
    slug = p['slug']
    if slug in china:
        tag = '🇨🇳 中国'
    elif slug in enterprise:
        tag = '🏢 企业'
    else:
        tag = '👤 社区/个人'
    print(f\"| {p['name']} | {p['server_count']} | {tag} |\")
" 2>/dev/null

    echo ""

    # 合规关键词详情
    hits=$(python3 -c "
import json
d = json.load(open('$f'))
kws = d['compliance_scan'].get('unique_keywords', [])
if kws:
    print(', '.join(kws))
else:
    print('无')
" 2>/dev/null)

    if [[ "$hits" != "无" ]]; then
        echo "**合规关键词命中详情**：$hits"
        echo ""
        python3 -c "
import json
d = json.load(open('$f'))
for h in d['compliance_scan'].get('hits_detail', []):
    print(f\"  - {h['keyword']}: {h['count']} 次（在 {h['page']}）\")
" 2>/dev/null
        echo ""
    fi

    # 剩余控制权信号判定
    echo "**剩余控制权信号判定**："
    echo ""
    python3 -c "
import json
d = json.load(open('$f'))
top = d['mcp_directory']['top_publishers'][:30]
china = d['mcp_directory']['china_publishers']
enterprise = d['mcp_directory']['enterprise_publishers']

# 判定逻辑：
# 1. 企业 publisher 是否占比过大
ent_total = sum(p['server_count'] for p in enterprise)
all_total = sum(p['server_count'] for p in top) if top else 1
ent_ratio = ent_total / all_total

# 2. 合规关键词是否出现（制度扩张信号）
hits = d['compliance_scan'].get('total_hits', 0)
kws = d['compliance_scan'].get('unique_keywords', [])

# 3. 中国区信号
china_names = ', '.join(p['name'] for p in china) if china else '无'
ent_names = ', '.join(f\"{p['name']}({p['server_count']})\" for p in enterprise[:5])

print(f'- 企业 Publisher 生态占比: {ent_ratio:.0%}（{ent_names}）')
print(f'- 中国区 Publisher: {china_names}')
print(f'- 合规关键词: {len(kws)} 种（{len(kws)} = 制度扩张信号）')

if ent_ratio > 0.6:
    print()
    print('**信号判定：🟡 需关注** — 企业 Publisher 占比过高，剩余控制权可能向企业倾斜。')
elif ent_ratio > 0.4:
    print()
    print('**信号判定：🟢 稳定** — 企业 Publisher 占比正常，生态分布健康。')
else:
    print()
    print('**信号判定：🟢 社区主导** — 企业占比低，社区/个人驱动。')

if hits > 3:
    print()
    print('**制度扩张信号：⚠️ 合规关键词显著增加** — MCP spec 正在向合规层扩张。')
elif hits > 0:
    print()
    print(f'**制度扩张信号：ℹ️ 合规关键词微量出现（{len(kws)} 种）** — 尚处于早期讨论。')
else:
    print()
    print('**制度扩张信号：✅ 协议层暂无合规概念** — \"协议不管合规\"的分层设计稳定。')
" 2>/dev/null

    echo ""
}

# ---- L5: AAIF 制度监视面（v2 新增）----

section_l5() {
    echo ""
    echo "### L5 — AAIF 制度监视面（2026-10 重估新增）"
    echo ""

    AAIF_DIR="$SCRIPT_DIR" python3 - <<'PYEOF'
import sys, os
sys.path.insert(0, os.environ['AAIF_DIR'])
import re

# 从注册表直接读 watch_surfaces，保持「配置即真相」：
# 新增监视面只改 yaml，不必再改脚本。
path = os.path.join(os.environ['AAIF_DIR'], 'aaif-registry-v2.yaml')
txt = open(path).read()
sec = txt.split('watch_surfaces:')[-1]

items = []
for block in re.split(r'\n  - name:', sec):
    if not block.strip():
        continue
    name = block.strip().split('\n')[0].strip()
    def g(k):
        m = re.search(rf'^\s+{k}:\s*"?(.*?)"?\s*$', block, re.M)
        return m.group(1).strip() if m else ''
    items.append({'name': name, 'url': g('url'), 'what': g('what'), 'signal': g('signal')})

labels = {
    'working-groups': '① 制度建设（WG 是真正在立规矩的地方）',
    'governance-structure': '② 治理结构（TC/Board 的公司分布）',
    'landscape': '③ 生态地图（landscape 成型度）',
    'license-governance-audit': '④ 许可与治理合规（开源边界在这里被检验）',
}

for it in items:
    label = labels.get(it['name'], it['name'])
    print(f"**{label}**")
    if it['url']:
        print(f"- 出处: {it['url']}")
    if it['what']:
        print(f"- 现状: {it['what']}")
    if it['signal']:
        print(f"- 关注信号: {it['signal']}")
    print()

print("**本期必须回答的四个问题：**")
print("1. WG 是否开始产出可引用的规范文档？（项目是既成事实，WG 才是规则）")
print("2. TC 主席来自 Anthropic、MCP 也来自 Anthropic——中立性如何自证？")
print("3. landscape Watchlist 上的非会员项目，是在被「事实标准化」还是被边缘化？")
print("4. anthropics/skills 18 万星却无 LICENSE——「open standards」的定义权归谁？")
PYEOF

    echo ""
}


if [[ "$SECTION" == "all" || "$SECTION" == "L4" ]]; then
    section_l4
fi
if [[ "$SECTION" == "all" || "$SECTION" == "L5" ]]; then
    section_l5
fi

# ---- L6: 技术思考 × 制度思考 对照 ----

section_l6() {
    echo ""
    echo "### L6 — 技术思考 × 制度思考 对照"
    echo ""
    echo "> 每个技术分野都要给两条线：技术层回答「在做什么」，制度层回答「凭什么这样安排、谁承担后果」。"
    echo ""

    AAIF_DIR="$SCRIPT_DIR" DATA_DIR="$DATA_DIR" python3 - <<'PYEOF'
import sys, os, re, glob, json, datetime

path = os.path.join(os.environ['AAIF_DIR'], 'aaif-tech-institution-pairs.yaml')
if not os.path.exists(path):
    print("（未找到对照表 aaif-tech-institution-pairs.yaml）")
    sys.exit(0)

txt = open(path).read()
body = txt.split('pairs:')[-1].split('\ndiscipline:')[0]
data_dir = os.environ.get('DATA_DIR', '')
today = datetime.date.today()

# 当日各项目活跃度，用于把对照落到具体项目上。
# 必须按文件名日期排序后取最后一个 —— 直接遍历 glob 会被旧文件覆盖，
# 导致「今天在动」的项目显示成「81 天前」。
proj_state = {}
if data_dir:
    for f in sorted(glob.glob(os.path.join(data_dir, '*-[0-9][0-9][0-9][0-9]-*.json'))):
        try:
            d = json.load(open(f))
        except Exception:
            continue
        name = d.get('name') or os.path.basename(f).split('-20')[0]
        pushed = d.get('pushed_at', '') or ''
        # org 类型没有 pushed_at，用它名下 repo 的最新 push
        if not pushed and d.get('is_org'):
            pushed = max((r.get('pushed', '') for r in d.get('repos', [])), default='') or ''
        try:
            days = (today - datetime.date.fromisoformat(pushed[:10])).days
        except Exception:
            days = None
        proj_state[name] = {'days': days, 'stars': d.get('stars'), 'issues': d.get('issues')}

def field(block, key):
    m = re.search(rf'^\s+{key}:\s*"?(.*?)"?\s*$', block, re.M)
    return m.group(1).strip() if m else ''

for block in re.split(r'\n  - layer:', body):
    if not block.strip():
        continue
    layer = block.strip().split('\n')[0].strip().strip('"')
    tech = field(block, 'tech')
    inst = field(block, 'institution')
    probe = field(block, 'probe')
    watch = field(block, 'watch')

    print(f"#### {layer}")
    print(f"- **技术思考：** {tech}")
    print(f"- **制度思考：** {inst}")
    if probe:
        print(f"- **本期追问：** {probe}")
    if watch:
        parts = []
        for w in [x.strip() for x in watch.split(',') if x.strip()]:
            st = proj_state.get(w)
            if not st:
                parts.append(f"{w}（无数据）")
            elif st['days'] is None:
                parts.append(f"{w}（取数失败）")
            else:
                parts.append(f"{w}（{st['days']} 天前 push）")
        if parts:
            print(f"- **数据落点：** {' / '.join(parts)}")
    print()

print("**判定纪律：** 两列都写才构成一条洞察；只写技术描述视为未完成。制度层只描述机制与后果，不做道德评判。")
PYEOF

    echo ""
}

if [[ "$SECTION" == "all" || "$SECTION" == "L6" ]]; then
    section_l6
fi

echo ""
echo "============================================"
echo " AAIF query complete."
echo "============================================"
