#!/usr/bin/env bash
# SGLang signal extraction — sgl-project/sglang GitHub (native community governance)
set -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_SL="$DIR/data/github-sglang"

L1_HEAD="## L1 信号（SGLang — sgl-project/sglang）"
echo "$L1_HEAD"

if [ -f "$GH_SL/sglang-latest.json" ]; then
  echo "### sglang (GitHub)"
  python3 - "$GH_SL/sglang-latest.json" << 'PY'
import json, sys
p = json.load(open(sys.argv[1]))
r = p.get("repos", {}).get("sglang", p.get("data", {}))
stars = r.get("stars", r.get("stargazers_count", "?"))
forks = r.get("forks", r.get("forks_count", "?"))
issues = r.get("open_issues", "?")
lang = r.get("language", "?")
created = r.get("created_at", "?")[:10]
pushed = r.get("pushed_at", "?")
rel = r.get("releases", [])
print("- ⭐", stars, "stars | 🍴", forks, "forks | 🐛", issues, "open issues")
print("- 语言:", lang, "| 创建:", created, "| 最近推送:", pushed)
if rel:
    print("- 📦 Releases:", len(rel), "| 最新:", rel[0].get("tag_name","?"), "(", rel[0].get("published_at","?")[:10], ")")
PY
fi

echo ""
echo "### L2 信号（SGLang / 原生社区治理）"
echo "- SGLang 由 Stanford 团队发起（2024年1月），独立社区项目"
echo "- 无基金会伞下支持，无 Governing Board，无 TSC"
echo "- 与 vLLM（PyTorch Foundation 正式项目）形成鲜明制度对比"
echo "- 社区驱动，发布节奏由核心团队主导"
echo ""
echo "### L3 信号（制度分析 — 自治 vs 收编的分野）"
echo "- SGLang 代表：AI 基础设施的'原生社区自治'路径"
echo "- vLLM 代表：AI 基础设施的'基金会收编'路径"
echo "- 二者同领域（LLM 推理引擎），制度演化路径完全分叉"
echo "- North 制度演进理论：治理结构在'冲突倒逼'中产生，不是设计出来的"
echo "- 关键观察：SGLang 什么时候会建立正式治理结构？取决于什么时候出现需要治理的冲突"
echo "- 桥接概念：vLLM vs SGLang 是 AI 时代的 K8s vs OpenStack——一个被收编，一个保持自治"
