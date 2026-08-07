#!/usr/bin/env bash
# LLVM signal extraction — llvm-project GitHub + LLVM Foundation
set -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_LL="$DIR/data/github-llvm"
TODAY=$(date +%Y-%m-%d)

L1_HEAD="## L1 信号（LLVM — llvm-project）"
echo "$L1_HEAD"

if [ -f "$GH_LL/llvm-project-latest.json" ]; then
  echo "### llvm-project (GitHub)"
  python3 - "$GH_LL/llvm-project-latest.json" << 'PY'
import json, sys
p = json.load(open(sys.argv[1]))
r = p.get("repos", {}).get("llvm-project", p.get("data", {}))
stars = r.get("stars", r.get("stargazers_count", "?"))
forks = r.get("forks", r.get("forks_count", "?"))
commits7 = r.get("commits_7d", 0)
pushed = r.get("pushed_at", "?")
rel = r.get("releases", [])
print("- ⭐", stars, "stars | 🍴", forks, "forks")
print("- 🔥 7日提交:", commits7, "| 最近推送:", pushed)
if rel:
    print("- 📦 Releases:", len(rel), "| 最新:", rel[0].get("tag_name","?"), "(", rel[0].get("published_at","?")[:10], ")")
PY
fi

echo ""
echo "### L2 信号（LLVM Foundation / 制度转型）"
echo "- LLVM Foundation 2023 年转型为独立 501(c)(6) 非营利"
echo "- llvm/llvm-project 为 monorepo（Clang/LLD/Lldb 等全部包含）"
echo "- 治理：技术委员会（TSC）+ 维护者委员会，去中心化"
echo ""
echo "### L3 信号（制度分析 — 从企业控制到公地治理）"
echo "- LLVM 曾是 Apple/Google 企业控制，2023 Foundation 转型 = 制度化"
echo "- Monorepo 架构 → 降低跨项目治理成本"
echo "- LLVM Foundation membership 含企业/学术界，跨利益相关者"
