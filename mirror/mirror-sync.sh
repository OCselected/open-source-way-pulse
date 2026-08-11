#!/usr/bin/env bash
# mirror-sync.sh — 抓取主要镜像站 RSS，增量记录到 data/
# 用法：bash mirror-sync.sh [--init]
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$DIR/data"
mkdir -p "$DATA"

DATE=$(date '+%F')

declare -A SITES=(
  ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/feed.xml"
  ["sjtu"]="https://mirror.sjtu.edu.cn/blog/feed.xml"
  ["ustc"]="https://mirrors.ustc.edu.cn/blog/feed.xml"
  ["zju"]="https://mirrors.zju.edu.cn/blog/feed.xml"
)

for site in tuna sjtu ustc zju; do
  url="${SITES[$site]}"
  echo "=== fetching $site from $url ==="
  curl -sSL --max-time 15 "$url" -o "$DATA/${site}-feed-${DATE}.xml" 2>/dev/null && \
    echo "  OK ($site)" || \
    echo "  FAIL ($site)"
done

echo "done."
