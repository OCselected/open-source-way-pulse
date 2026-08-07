#!/usr/bin/env bash
# Python signal extraction — cpython GitHub + discourse (discuss.python.org)
set -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_PY="$DIR/data/github-python"
DSC_PY="$DIR/data/discourse-python"
TODAY=$(date +%Y-%m-%d)

L1_HEAD="## L1 信号（Python — cpython + discourse）"
echo "$L1_HEAD"

# GitHub: cpython
if [ -f "$GH_PY/cpython-latest.json" ]; then
  echo "### cpython (GitHub)"
  python3 - "$GH_PY/cpython-latest.json" << 'PY'
import json, sys
p = json.load(open(sys.argv[1]))
r = p.get("repos", {}).get("cpython", p.get("data", {}))
stars = r.get("stars", r.get("stargazers_count", "?"))
forks = r.get("forks", r.get("forks_count", "?"))
commits7 = r.get("commits_7d", 0)
pushed = r.get("pushed_at", "?")
rel = r.get("releases", [])
print("- ⭐", stars, "stars | 🍴", forks, "forks")
print("- 🔥 7日提交:", commits7, "| 最近推送:", pushed)
if rel:
    print("- 📦 Releases:", len(rel), "| 最新:", rel[0].get("tag_name","?"), "(", rel[0].get("published_at","?")[:10], ")")
else:
    print("- 📦 无GitHub Releases（Python 版本以 PSF 发布基础设施为准）")
PY
fi

# Discourse
if [ -f "$DSC_PY/latest.json" ]; then
  echo "### Python Discourse (discuss.python.org)"
  python3 - "$DSC_PY/latest.json" << 'PY'
import json, sys
d = json.load(open(sys.argv[1]))
tl = d.get("topic_list", {}).get("topics", [])
print(f"- 活跃话题: {len(tl)}")
print(f"- 最近参与者: {len(d.get('users', []))}")
for t in tl[:5]:
    print(f"  - {t.get('title', '')[:85]}")
PY
fi

echo ""
echo "### L2 信号（版本发布追踪 — 制度基础设施）"
echo "- Python 发布通过 PSF 发布基础设施，不在 GitHub Releases"
echo "- PEP 通过 python/peps 仓库管理（⭐4,985）"
echo "- Discourse (discuss.python.org) 是核心决策论坛，含 Steering Council 议题"
echo ""
echo "### L3 信号（制度分析 — PSF / 包容性制度）"
echo "- PSF 采用董事会 + Steering Council 双层治理"
echo "- PEP 制度 = 包容性变革机制（与 Linux 提交者契约形成对比）"
echo "- Python 3.14.7/3.13.15 双系列并行维护 → 制度性版本承诺"
