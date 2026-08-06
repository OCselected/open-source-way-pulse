#!/usr/bin/env bash
# pulse-query.sh — extract structured signals from a lore.inbox git-bare repo.
#
# Reads the kernel inbox git log and emits structured JSON for the
# L1/L2/L3 signal framework used by Project Pulse.
#
# Usage:
#   pulse-query.sh <inbox_name> [--since <YYYY-MM-DD>] [--days <N>]
#   pulse-query.sh lkml --days 1
#   pulse-query.sh lkml --since 2026-08-04
#
# Example output (one JSON line per signal):
#   {"type":"L1","subject":"...","date":"...","author":"..."}
#   {"type":"L2","signal":"top_sender","domain":"intel.com","count":42}
#   {"type":"L3","signal":"new_contributor","email":"name@example.com"}
#
# Output categories:
#   summary     — overall counts (new commits, active threads, senders)
#   L1_patches  — top-level PATCH series (vN 0/N subjects), major versions
#   L2_governance — top sender domains, maintainer-level signals
#   L3_newbies  — first-time contributor emails

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INBOX_DIR="$PULSE_DIR/repos/inboxes"

INBOX="${1:-lkml}"
SINCE=""
DAYS=1

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --days)  DAYS="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; shift ;;
  esac
done

REPO="$INBOX_DIR/$INBOX"
if [ ! -d "$REPO/.git" ]; then
  echo "ERROR: Inbox '$INBOX' not found at $REPO" >&2
  exit 1
fi

if [ -z "$SINCE" ]; then
  SINCE="$(date -d "$DAYS day ago" '+%Y-%m-%d')"
fi

cd "$REPO"

# Total count since SINCE
TOTAL=$(git log --since="$SINCE" --format="%H" | wc -l)
echo "{\"type\":\"summary\",\"inbox\":\"$INBOX\",\"since\":\"$SINCE\",\"total_emails\":$TOTAL}"

# NEW patch series (subjects matching "[PATCH ... 0/N" — series openers)
echo "---L1_PATCHES---"
{ git log --since="$SINCE" --format="%ai ||| %s" | \
  grep -E '\[PATCH .+ 0/' | head -60 || true; }

# syzbot / fuzz reports (L1 bug signal) — may be empty, use || true
echo "---L1_SYZBOT---"
git log --since="$SINCE" --format="%ai ||| %s" | \
  { grep "\[syzbot\]" | head -30 || true; }

# Top sender domains (L2 governance)
echo "---L2_SENDERS---"
{ git log --since="$SINCE" --format="%ae" | \
  sed 's/^[^@]*@//' | sort | uniq -c | sort -rn | head -20 || true; }

# Top individual contributors (L2)
echo "---L2_TOP_AUTHORS---"
{ git log --since="$SINCE" --format="%ae" | sort | uniq -c | sort -rn | head -15 || true; }

# New contributors (L3) — email domains that appear for the first time
# Compare against a running contributor list (stored per inbox)
CONTRIB_LOG="$INBOX_DIR/${INBOX}.contributors"
NEW_DOMAINS=$(git log --since="$SINCE" --format="%ae" | sed 's/^[^@]*@//' | sort -u)

echo "---L3_NEW_DOMAINS---"
if [ -f "$CONTRIB_LOG" ]; then
  echo "$NEW_DOMAINS" | while read -r dom; do
    grep -qFx "$dom" "$CONTRIB_LOG" || echo "NEW: $dom"
  done || true
else
  echo "$NEW_DOMAINS" | while read -r dom; do echo "NEW: $dom"; done
fi

# Update contributor log
echo "$NEW_DOMAINS" | sort -u >> "$CONTRIB_LOG"
# De-duplicate contributor log (keep latest 5000)
sort -u "$CONTRIB_LOG" | head -5000 > "${CONTRIB_LOG}.tmp"
mv "${CONTRIB_LOG}.tmp" "$CONTRIB_LOG"

echo "---DONE---"
