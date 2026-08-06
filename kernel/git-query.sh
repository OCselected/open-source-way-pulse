#!/usr/bin/env bash
# git-query.sh — Git mailing list L1/L2/L3 signal extraction
# Reads lore.kernel.org/git/1 bare repo, outputs Markdown sections
# aligned with kernel/ASF/AAIF query output format.
#
# Usage:
#   bash kernel/git-query.sh              # full output
#   bash kernel/git-query.sh --days N     # look back N days
#   bash kernel/git-query.sh --json       # raw JSON
#
# Output format (Markdown):
#   ### L1 — Git 版本发布与 PATCH 系列
#   ### L2 — Git 治理结构
#   ### L3 — Git 社区参与
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DAYS=1
JSON_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_MODE=1; shift ;;
    --days) DAYS="${2:-1}"; shift 2 ;;
    *) shift ;;
  esac
done

if [ "$JSON_MODE" = "1" ]; then
  bash "$SCRIPT_DIR/pulse-query.sh" git --days "$DAYS"
  exit 0
fi

RAW=$(bash "$SCRIPT_DIR/pulse-query.sh" git --days "$DAYS" 2>/dev/null || echo "")
if [ -z "$RAW" ]; then
  echo "ERROR: no output from pulse-query" >&2
  exit 1
fi

TOTAL=$(echo "$RAW" | head -1 | python3 -c "import json,sys; d=json.loads(sys.stdin.readline()); print(d.get('total_emails',0))" 2>/dev/null || echo "0")
SINCE=$(echo "$RAW" | head -1 | python3 -c "import json,sys; d=json.loads(sys.stdin.readline()); print(d.get('since','?'))" 2>/dev/null || echo "?")

YMD=$(date '+%Y-%m-%d')

echo "============================================"
echo " Project Pulse — Git 信号 ($YMD)"
echo "============================================"
echo ""
echo "**数据范围：** $SINCE（${DAYS}天前）"
echo "**当日邮件量：** $TOTAL 封"

# L1
echo ""
echo "### L1 — Git 版本发布与 PATCH 系列"
echo ""
if [ "$TOTAL" -eq 0 ]; then
  echo "本日无新邮件。"
else
  PATCHES=$(echo "$RAW" | sed -n '/---L1_PATCHES---/,/---L1_SYZBOT---/p' | sed '1d' | head -8)
  HAS_PATCHES=0
  if [ -n "$PATCHES" ]; then
    HAS_PATCHES=$(echo "$PATCHES" | grep -c '[^ ]' || true)
  fi
  if [ "$HAS_PATCHES" -gt 0 ]; then
    echo "**主要 PATCH 系列：**"
    echo ""
    echo "$PATCHES" | while IFS= read -r line; do
      [ -z "$line" ] && continue
      d=$(echo "$line" | awk -F' ||| ' '{print $1}')
      s=$(echo "$line" | awk -F' ||| ' '{print $2}')
      [ -z "$s" ] && continue
      echo "- $d — $s"
    done
  else
    echo "本日无大版本 PATCH 系列。"
  fi
fi

# L2
echo ""
echo "### L2 — Git 治理结构"
echo ""
echo "**Top 贡献者（按域名）：**"
echo ""
TOP_AUTHORS=$(echo "$RAW" | sed -n '/---L2_TOP_AUTHORS---/,/---L3_NEW_DOMAINS---/p' | sed '1d' | head -10)
HAS_AUTHORS=0
if [ -n "$TOP_AUTHORS" ]; then
  HAS_AUTHORS=$(echo "$TOP_AUTHORS" | grep -c '[^ ]' || true)
fi
if [ "$HAS_AUTHORS" -gt 0 ]; then
  echo "| 域名 | 邮件数 | Top 贡献者 |"
  echo "|------|--------|------------|"
  echo "$TOP_AUTHORS" | head -8 | while read -r count email rest; do
    [ -z "$email" ] && continue
    domain="${email##*@}"
    user="${email%%@*}"
    echo "| $domain | $count | $user |"
  done
fi

# L3
echo ""
echo "### L3 — Git 社区参与"
echo ""
NEW_DOMAINS=$(echo "$RAW" | sed -n '/---L3_NEW_DOMAINS---/,/---DONE---/p' | sed '1d' | grep -v "^$" | head -8)
HAS_NEW=0
if [ -n "$NEW_DOMAINS" ]; then
  HAS_NEW=$(echo "$NEW_DOMAINS" | grep -c '[^ ]' || true)
fi
if [ "$HAS_NEW" -gt 0 ]; then
  echo "**首次出现的新邮箱域名：**"
  echo ""
  echo "$NEW_DOMAINS" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "- $line"
  done
else
  echo "本日无新域名首次出现。"
fi

echo ""
echo "============================================"
echo " Git query complete. ($YMD)"
echo "============================================"
