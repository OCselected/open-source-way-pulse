#!/usr/bin/env bash
# =============================================================================
# Project Pulse — Debian Signal Extraction
# =============================================================================
#
# Reads cached Debian data and emits L1/L2/L3 governance signals.
#
# Data sources:
#   data/debian/micronews-latest.json  — Micronews RSS (community activity)
#   data/debian/release-latest.json    — Stable release info
#   data/debian/announce-latest.json   — debian-announce archive (if exists)
#
# Usage:
#   debian-query.sh              # Full output
#   debian-query.sh --section L1 # Only L1
#   debian-query.sh --section L2
#   debian-query.sh --section L3
# =============================================================================

set -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODAY=$(date +%Y-%m-%d)

MICRO="$DIR/data/debian/micronews-latest.json"
REL="$DIR/data/debian/release-latest.json"
ANN="$DIR/data/debian/announce-latest.json"

SECTION="${1:---all}"

# --- L1: Releases ---
section_l1() {
    echo "## L1 信号（Debian — 发布 + 公告）"
    echo ""

    if [ -f "$REL" ]; then
        echo "### 当前稳定版"
        python3 - "$REL" << 'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(f"- **版本**: {d.get('version','?')} ({d.get('codename','?')})")
print(f"- **发布日期**: {d.get('release_date','?')}")
print(f"- **采集时间**: {d.get('fetched_at','?')}")
PY
        echo ""
    else
        echo "### 当前稳定版"
        echo "- ⚠️ 无缓存数据，请运行 debian-sync.sh --sync"
        echo ""
    fi

    # Recent announcements count
    if [ -f "$MICRO" ]; then
        echo "### 近 30 日社区新闻"
        python3 - "$MICRO" << 'PY'
import json, sys
d = json.load(open(sys.argv[1]))
items = d.get("items", [])
print(f"- **Micronews 条目数**: {d.get('total_items', 0)}")
print(f"- **最后构建**: {d.get('last_build', '?')}")
print(f"- **最新条目**: {items[0].get('pub_date', '?')[:16] if items else '无'}")
print("")
# Top events
events = [i for i in items if any(k in i.get('title','').lower() for k in ['debconf','release','dpl','election','vote','vote','announce'])]
if events:
    print(f"- **关键事件** ({len(events)} 条):")
    for e in events[:5]:
        print(f"  - {e['pub_date'][:16]} · {e['title'][:90]}")
PY
    fi

    # debian-announce archive (fallback)
    if [ -f "$ANN" ] && [ -s "$ANN" ]; then
        AN_COUNT=$(python3 -c "import json; d=json.load(open('$ANN')); print(d.get('total_threads',0))")
        if [ "$AN_COUNT" -gt 0 ]; then
            echo "### debian-announce 发布列表"
            python3 - "$ANN" << 'PY'
import json, sys
d = json.load(open(sys.argv[1]))
threads = d.get("threads", [])
print(f"- **年度公告**: {d.get('total_threads', 0)} 条")
for t in threads[:5]:
    print(f"  - {t.get('subject','')[:90]}")
PY
        fi
    fi
}

# --- L2: Governance ---
section_l2() {
    echo "### L2 信号（Debian 治理动态）"
    echo ""

    if [ -f "$MICRO" ]; then
        python3 - "$MICRO" << 'PY'
import json, sys
d = json.load(open(sys.argv[1]))
items = d.get("items", [])

# Governance keywords
gov_kw = ['election', 'vote', 'dpl', 'technical committee', 'policy', 'charter', 'constitution', 'governance', 'debconf']
gov_items = [i for i in items if any(k in i.get('title','').lower() for k in gov_kw)]

print(f"- **治理相关条目**: {len(gov_items)} / {len(items)}")
if gov_items:
    for i in gov_items[:5]:
        print(f"  - {i['pub_date'][:16]} · {i['title'][:100]}")
else:
    print("- 近 30 日无治理事件")

print("")
# Unique contributors
creators = set()
for i in items:
    c = i.get('creator', '')
    if c:
        creators.add(c)
print(f"- **Micronews 贡献者**: {len(creators)} 人")
for c in sorted(creators)[:5]:
    print(f"  - {c}")
PY
    else
        echo "- ⚠️ 无缓存数据"
    fi

    echo ""
    echo "### 制度结构"
    echo "- **DPL (Debian Project Leader)**: 每两年由全体 Debian 会员投票选举"
    echo "- **技术委员会 (Technical Committee)**: 解决维护者之间的技术/政策纠纷"
    echo "- **项目维护者 (Maintainers)**: 包级别的 meritocracy，贡献→责任→权利"
}

# --- L3: Participation & institutional analysis ---
section_l3() {
    echo "### L3 信号（参与结构 + 制度分析）"
    echo ""

    if [ -f "$MICRO" ]; then
        python3 - "$MICRO" << 'PY'
import json, sys
from collections import Counter
d = json.load(open(sys.argv[1]))
items = d.get("items", [])

# Top contributors
creators = [i.get('creator','') for i in items if i.get('creator')]
counter = Counter(creators)
print(f"- **Micronews 活跃贡献者**: {len(counter)} 人 / {len(items)} 条")
print(f"- **头部贡献者**: {counter.most_common(1)[0][0]} ({counter.most_common(1)[0][1]} 条)")
print(f"- **集中度**: 头部贡献者占 {counter.most_common(1)[0][1]/len(items)*100:.0f}%")

# Topics via hashtags
topics = []
for i in items:
    title = i.get('title', '')
    for m in __import__('re').finditer(r'#(\w+)', title):
        topics.append(m.group(1))
tc = Counter(topics).most_common(8)
if tc:
    print(f"- **热门话题**: {', '.join(f'{t}({c})' for t,c in tc[:5])}")
PY
        echo ""
    fi

    echo "### 制度分析 — 纯粹的 meritocracy"
    echo ""
    echo "- Debian = **开源世界最纯粹的 meritocracy 制度**"
    echo "  - 贡献即权利（无企业背书、无行政任命）"
    echo "  - DPL 民主选举 = **代码世界的民主合法性**"
    echo "  - 与 Fedora（Red Hat 驱动）/ openSUSE（SUSE 驱动）不可通约"
    echo "- **制度代价**：发布缓慢、创新惰性——这是 meritocracy 的固有张力"
    echo "- **制度优势**：长期稳定性（13 年 LTS 支持）、社区自主"
    echo "- **桥接概念**：Debian = **思想自治**（ideological autonomy），不是"
    echo "  工具而是制度标本——开源能否在没有企业资助的情况下自我维持"
}

# --- main ---
case "$SECTION" in
    --section*L1|L1)
        section_l1
        ;;
    --section*L2|L2)
        section_l2
        ;;
    --section*L3|L3)
        section_l3
        ;;
    *)
        section_l1
        echo "---"
        echo ""
        section_l2
        echo ""
        echo "---"
        echo ""
        section_l3
        ;;
esac