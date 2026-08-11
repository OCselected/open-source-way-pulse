#!/usr/bin/env bash
# mirror-query.sh — 从 data/ 下抓取到的 RSS 提取 L1/L2/L3 信号
# 用法：bash mirror-query.sh [--days N]
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$DIR/data"
DAYS=${1:-1}
echo "querying mirror pulse for last $DAYS day(s)"

if [ ! -d "$DATA" ] || [ -z "$(ls -A "$DATA" 2>/dev/null)" ]; then
  echo "---L1_EVENTS---"
  echo "(no data — run mirror-sync.sh first)"
  echo "---L2_POLICY---"
  echo "(no data)"
  echo "---L3_UPSTREAM---"
  echo "(no data)"
  exit 0
fi

# 提取最近 $DAYS 天的 RSS 文件
for f in $(ls -t "$DATA"/*feed*.xml 2>/dev/null | head -$DAYS); do
  site=$(basename "$f" | sed 's/-feed-.*//')
  echo "=== $site ==="
  # 用 grep 找关键事件关键词（中文）
  grep -Ei "移除|停止|暂停|下线|删除|不再提供" "$f" 2>/dev/null | head -10 || echo "(no event keywords)"
done

echo "---L1_EVENTS---"
echo "(parse RSS titles/descriptions for 'removed'/'removed mirror' keywords)"
echo "---L2_POLICY---"
echo "(parse for policy-change language: 不定期检视, 未来可能, 不再通知)"
echo "---L3_UPSTREAM---"
echo "(cross-check removed projects' upstream status)"
