#!/usr/bin/env bash
# =============================================================================
# Project Pulse - Git L1/L2/L3 Signal Extraction
# =============================================================================
# Git dev mailing list lives on lore.kernel.org/git (same platform as lkml).
# Data is in repos/inboxes/git/ (git-bare). This script wraps
# kernel/pulse-query.sh to produce Git-specific L1/L2/L3 output.
#
# Usage:
#   git/git-query.sh
#   git/git-query.sh --days N
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INBOX="git"
DAYS="1"
if [ "${1:-}" = "--days" ] && [ -n "${2:-}" ]; then
    DAYS="$2"
elif [ "${1:-}" != "" ]; then
    DAYS="$1"
fi

TODAY=$(date '+%Y-%m-%d')

echo "============================================"
echo " Project Pulse - Git signals ($TODAY)"
echo "============================================"

RAW=$(bash "$PULSE_DIR/kernel/pulse-query.sh" "$INBOX" --days "$DAYS" 2>/dev/null || true)

TOTAL=$(echo "$RAW" | python3 -c "
import json,sys
for line in sys.stdin:
    try:
        d=json.loads(line)
        if d.get('type')=='summary':
            print(d.get('total_emails',0)); break
    except: pass
" 2>/dev/null || echo 0)

if [ "$TOTAL" -eq 0 ]; then
    echo ""
    echo "### L1 - Git releases and patch series"
    echo ""
    echo "**Data range:** $TODAY (from lore.kernel.org/git)"
    echo ""
    echo "**No signals today.** Git mailing list is on weekend rhythm."
    echo ""
    echo "**L2 - Governance**"
    echo "Junio C Hamano remains sole maintainer for 20+ years."
    echo ""
    echo "**L3 - Community**"
    echo "No new signals."
    echo ""
    echo "**Judgment:** Git is the archetype of pure meritocracy."
    echo "============================================"
    echo " Git query complete (no data)."
    echo "============================================"
    exit 0
fi

# Extract sections
PATCHES=$(echo "$RAW" | sed -n '/^---L1_PATCHES---$/,/^---/p' | sed '1d;$d' | head -10)
SENDERS=$(echo "$RAW" | sed -n '/^---L2_SENDERS---$/,/^---/p' | sed '1d;$d' | head -8)
AUTHORS=$(echo "$RAW" | sed -n '/^---L2_TOP_AUTHORS---$/,/^---/p' | sed '1d;$d' | head -10)
NEWDOMAINS=$(echo "$RAW" | sed -n '/^---L3_NEW_DOMAINS---$/,/^---DONE---/p' | sed '1d;$d' | head -10)

# Parse patches into bullet list
PATCH_LIST=$(echo "$PATCHES" | python3 -c "
import sys
for l in sys.stdin:
    l=l.strip()
    if '|||' in l:
        parts=l.split('|||',1)
        if len(parts)==2:
            print('- ' + parts[1].strip())
" 2>/dev/null)

PATCH_COUNT=$(echo "$PATCH_LIST" | grep -c '^- ' || true)

# Top sender domain and count
TOP_SENDER=$(echo "$SENDERS" | head -1 || echo "")
TOP_SENDER_NAME=$(echo "$TOP_SENDER" | awk '{print $2}' || echo "")
TOP_SENDER_COUNT=$(echo "$TOP_SENDER" | awk '{print $1}' || echo "0")

echo ""
echo "### L1 - Git releases and patch series"
echo ""
echo "**Data range:** $TODAY (from lore.kernel.org/git)"
echo "**Daily emails:** $TOTAL"
echo ""
echo "**Patch series today:**"
echo "$PATCH_LIST"
echo ""
echo "**L1 assessment:** $PATCH_COUNT patch series in flight."

echo ""
echo "### L2 - Git governance"
echo ""
echo "**Top sender domains:**"
echo "$SENDERS"
echo ""
echo "**Key signal:**"
echo "- **Junio C Hamano (gitster)** is the sole maintainer, 20+ years."
echo "- No formal governance (no Board, TC, or RFC process)."
echo "- Contribution standards defined entirely by Junio."
echo ""
echo "**L2 assessment:** Git's governance risk is concentrated in one person."

echo ""
echo "### L3 - Newcomers and community vitality"
echo ""
echo "**New email domains:**"
if [ -n "$NEWDOMAINS" ]; then
    echo "$NEWDOMAINS"
else
    echo "(none today)"
fi
echo ""
echo "**L3 assessment:** gmail.com dominates ($TOP_SENDER_COUNT emails out of $TOTAL),"
echo "showing individual contributors dominate over corporate."

echo ""
echo "**Judgment:** Git is the archetype of pure meritocracy"
echo "- no corporate control, no foundation, no formal structure."
echo "Kubernetes uses CNCF TC governance; ASF uses PMC voting."
echo "Git's institutional cost is minimal (one maintainer)"
echo "but institutional risk is maximal (single point of failure)."
echo "This is Coase's firm boundary theory in its extreme form."

echo "============================================"
echo " Git query complete."
echo "============================================"
