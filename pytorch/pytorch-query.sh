#!/usr/bin/env bash
# =============================================================================
# Project Pulse - PyTorch L1/L2/L3 Signal Extraction
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_FILE="$PULSE_DIR/data/github-pytorch/pytorch-latest.json"

if [ ! -f "$DATA_FILE" ]; then
    echo "ERROR: No cached data at $DATA_FILE" >&2
    exit 1
fi

TODAY=$(date '+%Y-%m-%d')

echo "============================================"
echo " Project Pulse - PyTorch signals ($TODAY)"
echo "============================================"

DATA_FILE="$DATA_FILE" python3 << 'PYEOF'
import json, os
d = json.load(open(os.environ["DATA_FILE"]))
repo = d.get("repos", {}).get("pytorch", {})

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
print("### L1 - PyTorch releases")
print()
print(f"**Data range:** today (from GitHub: pytorch/pytorch)")
print(f"**Stars:** {stars:,} | **Language:** {lang} | **License:** {license}")
print(f"**Commits (last 7 days):** {commits_7d} | **Avg weekly:** {avg_weekly:.0f}")
print()
if latest_rel:
    print(f"**Latest release:** {latest_rel['tag']} ({latest_rel['published'][:10]})")
    if prev_rel:
        print(f"**Previous:** {prev_rel['tag']} ({prev_rel['published'][:10]})")
print()
print("**Recent commits:**")
for c in repo.get("recent_commits", [])[:6]:
    print(f"  - {c['sha']}: {c['msg']}")

print()
print("### L2 - PyTorch governance (PyTorch Foundation)")
print()
print("**PyTorch Foundation (成立 2023):**")
print("- 成员包括 Meta（创始者）+ Apple + Amazon + Google + NVIDIA 等")
print("- 治理目标：将 PyTorch 从 Meta 主导的企业项目转化为多方治理的开源基础设施")
print()
print("**关键张力：**")
print("- Meta 仍是最大贡献者——PyTorch 的'基金会独立性'是否真正成立？")
print("- 对比 TensorFlow：Google 在 2024 年宣布不再维护 TF 主线，PyTorch 是否面临同样风险？")
print("- 桥接概念：PyTorch Foundation 是'企业将核心基础设施放在基金会治理下'的制度实验——")
print("  类似 AAIF 的 Block goose 模式，但 PyTorch 的 Meta 依赖度更高")

print()
print("### L3 - Community participation")
print()
print(f"**活动指标：** 周均 {avg_weekly:.0f} commits，高活跃度。")
print(f"**贡献结构：** Meta 工程师贡献占比较高，外部贡献者增长中。")

print()
print("**开源之道判断**")
print("PyTorch 的治理问题本质上是'企业开源的独立性悖论'：")
print("- 当创始企业（Meta）的贡献占比过高时，基金会是否只是'治理外壳'？")
print("- PyTorch Foundation 能否真正分散决策权，还是仅仅为 Meta 的开源策略提供合法性？")
print("- 桥接概念：Williamson 四层框架——这一层发生在 L3（跨组织协调），")
print("  PyTorch 正从 L2（企业内部协调）向 L3 迁移，但转移程度有限")
PYEOF

echo "============================================"
echo " PyTorch query complete."
echo "============================================"