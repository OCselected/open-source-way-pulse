#!/usr/bin/env bash
# =============================================================================
# Project Pulse - Kubernetes L1/L2/L3 Signal Extraction
# =============================================================================
# Data: data/github-k8s/kubernetes-latest.json (synced by k8s/github-sync.py)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$PULSE_DIR/data/github-k8s"
TODAY=$(date '+%Y-%m-%d')
LATEST="$DATA_DIR/kubernetes-latest.json"

if [ ! -f "$LATEST" ]; then
    echo "ERROR: No cached data at $LATEST — run sync first" >&2
    exit 1
fi

D=$(python3 -c "import json;print(json.load(open('$LATEST')))")

echo "============================================"
echo " Project Pulse - Kubernetes signals ($TODAY)"
echo "============================================"

DATA_FILE="$LATEST" python3 << 'PYEOF'
import json, os
LATEST = os.environ["DATA_FILE"]
d = json.load(open(LATEST))
repo = d.get("repos", {}).get("kubernetes", {})

stars = repo.get("stars", "?")
pushed = repo.get("pushed_at", "?")
commits_7d = repo.get("commits_last_7d", 0)
avg_weekly = repo.get("commit_activity_avg_weekly", 0)
releases = repo.get("releases", [])
license = repo.get("license", "?")
lang = repo.get("language", "?")

latest_rel = releases[0] if releases else None
prev_rel = releases[1] if len(releases) > 1 else None

print()
print("### L1 - Kubernetes releases and KEPs")
print()
print(f"**Data range:** today (from GitHub: kubernetes/kubernetes)")
print(f"**Stars:** {stars:,} | **Language:** {lang} | **License:** {license}")
print(f"**Commits (last 7 days):** {commits_7d} | **Avg weekly:** {avg_weekly:.0f}")
print()
if latest_rel:
    rel = f"{latest_rel['tag']} ({latest_rel['published'][:10]}, prerelease={latest_rel.get('prerelease', False)})"
    print(f"**Latest release:** {rel}")
    if prev_rel:
        print(f"**Previous:** {prev_rel['tag']} ({prev_rel['published'][:10]})")
print()
print("**Recent commits:**")
for c in repo.get("recent_commits", [])[:6]:
    print(f"  - {c['sha']}: {c['msg']}")

print()
print("### L2 - Kubernetes governance (CNCF)")
print()
print("**CNCF Technical Oversight Committee (TC) + SIG structure:**")
print("- Kubernetes 使用 CNCF 治理模型：TC (Technical Oversight Committee) 做技术方向决策")
print("- SIG (Special Interest Group) 自治：约 40+ 个 SIG 各管一块（Architecture / Release / Node / Network 等）")
print("- KEP (Kubernetes Enhancement Proposal) 是正式的 RFC 流程——所有重大变更必须走 KEP")
print()
print(f"**当前治理状态：** kubernetes/enhancements 仓库追踪所有 KEP。")
print(f"**制度特征：** Kubernetes 的治理是'委员会+RFC'模式——比 Git（单人维护）正式，")
print(f"比 ASF（PMC 投票）更分布式。")

print()
print("### L3 - Community participation")
print()
print(f"**贡献者分布：** Kubernetes 的 GitHub 贡献者来自 Google/Red Hat/Microsoft/VMware 等企业。")
print(f"**活动指标：** 日均 {avg_weekly/7:.0f} 次 commit，保持高频迭代。")
print(f"**新人信号：** KEP 流程是新人进入核心贡献的正式通道。")

print()
print("**开源之道判断**")
print("Kubernetes 体现了'制度化自发秩序'——它从 Google 单一企业代码库演化为 CNCF 多利益相关方治理。")
print("关键张力：")
print("- Google 仍是最大贡献者，TC 是否真正能代表多方利益？")
print("- KEP 流程（标准化 RFC）降低了准入成本，但也增加了'制度摩擦'")
print("- 桥接概念：从 Coase'企业内部协调'到 Williamson'跨组织协调'——K8s 正处于这一转型的中间态")
PYEOF

echo "============================================"
echo " Kubernetes query complete."
echo "============================================"