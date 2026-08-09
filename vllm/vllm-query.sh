#!/usr/bin/env bash
# =============================================================================
# Project Pulse - vLLM L1/L2/L3 Signal Extraction
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_FILE="$PULSE_DIR/data/github-vllm/vllm-latest.json"

if [ ! -f "$DATA_FILE" ]; then
    echo "ERROR: No cached data at $DATA_FILE" >&2
    exit 1
fi

TODAY=$(date '+%Y-%m-%d')

echo "============================================"
echo " Project Pulse - vLLM signals ($TODAY)"
echo "============================================"

DATA_FILE="$DATA_FILE" python3 << 'PYEOF'
import json, os
d = json.load(open(os.environ["DATA_FILE"]))
repo = d.get("repos", {}).get("vllm", {})

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
print("### L1 - vLLM releases")
print()
print(f"**Data range:** today (from GitHub: vllm-project/vllm)")
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
print("### L2 - vLLM governance")
print()
print("**当前状态：PyTorch Foundation 正式项目（制度化的 AI 推理层）。**")
print("- vLLM 是 PyTorch Foundation 伞下项目，与 DeepSpeed / Ray / Helion / Safetensors 并列。")
print("- PyTorch Foundation 有 Governing Board + Technical Advisory Council，Meta 主导。")
print("- 这意味着 vLLM 不是「原生社区项目」，而是被基金会收编的 AI 基础设施组件。")
print()
print("**制度判断：**")
print("- 与 vLLM 同期、同领域（LLM 推理引擎）的 SGLang（sgl-project/sglang）")
print("  则是完全独立社区（Stanford 起源），无基金会伞下支持。")
print("- vLLM vs SGLang 的对比，是「基金会制度化」vs「原生社区自治」的制度分野。")

print()
print("### L3 - Community participation")
print()
print(f"**活动指标：** 周均 {avg_weekly:.0f} commits，高速增长阶段。")
print(f"**贡献结构：** 创始团队 + 企业贡献者。PyTorch Foundation 伞下意味着")
print(f"  Meta/NVIDIA/AMD 等企业有制度性通道参与治理。")

print()
print("**开源之道判断**")
print("vLLM 是一个'治理真空期'的标本——高 stars（88k+）、高活跃度，但无正式治理结构。")
print("关键问题：")
print("- 当项目达到这个规模，治理结构会自然涌现（如 K8s 的 SIG）还是需要设计（如 PyTorch Foundation）？")
print("- 与 PyTorch/TensorFlow 对比：AI 推理框架的开源治理是否趋向于'AI 基金会化'？")
print("- 桥接概念：这是 North 制度演进理论的现场——治理结构是在'问题倒逼'中产生的，")
print("  不是设计出来的。vLLM 什么时候建立治理，取决于什么时候出现需要治理的冲突。")
PYEOF

echo "============================================"
echo " vLLM query complete."
echo "============================================"