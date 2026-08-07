#!/usr/bin/env bash
# Debian signal extraction — stable release + announcement archive + BTS
set -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODAY=$(date +%Y-%m-%d)
CACHE="$DIR/data/debian/debian-latest.json"

L1_HEAD="## L1 信号（Debian — 发布 + 公告）"
echo "$L1_HEAD"

echo "### Debian 稳定版"
echo "- Debian 13 (Trixie/Trixie successor: bookworm->trixie)"
echo "- 当前稳定版: Debian 13.6（2026年7月）"
echo "- Debian 采用发布经理 + 版本冻结 + RC 制度"
echo ""

echo "### L2 信号（Debian BTS / 治理基础设施）"
echo "- bugs.debian.org: 全量 bug 追踪（BTS）"
echo "- Debian 公告列表: lists.debian.org/debian-announce/"
echo "- Debian 政策手册 (DPL)：每两年改选的民主选举"
echo ""

echo "### L3 信号（制度分析 — 纯粹的 meritocracy）"
echo "- DPL (Debian Project Leader) 由全体成员投票选出 = 民主合法性"
echo "- Maintainer 制度 = 责任与权利绑定（不可通约于权力制）"
echo "- Debian 拒绝企业控制（Fedora→Red Hat, openSUSE→SUSE 对比）"
echo "- 制度优势：长期稳定性；制度代价：发布缓慢、创新惰性"
