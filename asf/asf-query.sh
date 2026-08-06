#!/usr/bin/env bash
# =============================================================================
# Project Pulse — ASF Mailing List Signal Extraction
# =============================================================================
#
# Reads cached ASF lists stats from data/asf/<name>-<YYYY-MM>.json and
# emits L1/L2/L3 governance signals for the current month.
#
# Signals:
#   L1_LIFECYCLE  — Releases, CVEs, announcements, [DISCUSS], [VOTE]
#   L2_GOV        — Governance decisions (votes, incubator moves, board)
#   L3_PARTICIPATION — Sender count, participants, monthly trend context
#
# Usage:
#   asf-query.sh
#   asf-query.sh --section L1_LIFECYCLE
#   asf-query.sh --list announce
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PULSE_DIR}/data/asf"
REGISTRY="${PULSE_DIR}/asf/asf-registry.yaml"
CURRENT="${1:-}"

[[ ! -d "$DATA_DIR" ]] && { echo "No ASF cache data. Run asf-sync.sh --sync first."; exit 1; }

month_YYYYMM() { date +%Y-%m; }
YYYYMM=$(month_YYYYMM)

list_data_file() {
    local name="$1"
    local f="${DATA_DIR}/${name}-${YYYYMM}.json"
    [[ -f "$f" ]] && echo "$f"
}

section_l1_lifecycle() {
    echo "### L1 — ASF Lifecycle Signals"
    echo ""
    echo "**Releases, CVEs, and high-signal announcements for ${YYYYMM}.**"
    echo ""

    # announce list: releases + CVEs
    local f
    f=$(list_data_file "announce") || true
    if [[ -n "$f" ]]; then
        echo "<details><summary><b>announce@apache.org — 发布与安全公告</b></summary>"
        echo ""
        python3 - "$f" << 'PY' || true
import json, sys, re
d=json.load(open(sys.argv[1]))
emails=d.get("emails",[])
releases=[]
cves=[]
others=[]
for e in emails:
    s=e.get("subject","")
    if s.upper().startswith("[ANNOUNCE]") or s.upper().startswith("[ANN]"):
        releases.append(e)
    elif "CVE-" in s:
        cves.append(e)
    elif "[VOTE]" in s.upper() or "[DISCUSS]" in s.upper():
        others.append(e)
print(f"- Release announcements: {len(releases)}")
for e in releases[:8]:
    print(f"  - {e.get('subject','')[:110]}")
    if len(releases)>8:
        print(f"  - ... and {len(releases)-8} more")
        break
print("")
print(f"- Security / CVE notices: {len(cves)}")
for e in cves[:5]:
    print(f"  - {e.get('subject','')[:120]}")
print("")
PY
        echo "</details>"
        echo ""
    fi

    # project lists: votes / discuss
    echo "<details><summary><b>Project dev lists — [VOTE] / [DISCUSS] threads</b></summary>"
    echo ""
    for name in incubator httpd kafka hadoop; do
        f=$(list_data_file "$name") || true
        [[ -z "$f" ]] && continue
        python3 - "$name" "$f" << 'PY' || true
import json, sys
name=sys.argv[1]
d=json.load(open(sys.argv[2]))
votes=[]
discuss=[]
for t in d.get("thread_struct",[]):
    s=t.get("subject","")
    if "[VOTE]" in s.upper():
        votes.append(s)
    elif "[DISCUSS]" in s.upper() or "[VOTE]?" in s.upper():
        discuss.append(s)
print(f"- {name}: VOTE={len(votes)}, DISCUSS={len(discuss)}")
for s in votes[:4]:
    print(f"  - [VOTE] {s[:95]}")
for s in discuss[:3]:
    print(f"  - [DISCUSS] {s[:95]}")
if votes or discuss:
    print("")
PY
    done
    echo "</details>"
    echo ""
}

section_l2_governance() {
    echo "### L2 — ASF Governance Signals"
    echo ""
    echo "**Incubator movement and board-level governance for ${YYYYMM}.**"
    echo ""

    # incubator: new podlings, graduation, status changes
    f=$(list_data_file "incubator") || true
    if [[ -n "$f" ]]; then
        echo "<details><summary><b>ASF Incubator — 孵化动态</b></summary>"
        echo ""
        python3 - "$f" << 'PY' || true
import json, sys, re
d=json.load(open(sys.argv[1]))
subjects=[]
for t in d.get("thread_struct",[]):
    s=t.get("subject","")
    if any(k in s.upper() for k in ["PODLING","GRADUAT","NEW","STATUS","[VOTE]","REPORT"]):
        subjects.append(s)
print(f"- Governance threads: {len(subjects)}")
for s in subjects[:8]:
    print(f"  - {s[:120]}")
PY
        echo "</details>"
        echo ""
    fi

    # participant stats per list
    echo "<details><summary><b>Active participants by list</b></summary>"
    echo ""
    echo "| List | Participants | Top contributor |"
    echo "|------|-------------|-----------------|"
    for name in announce incubator httpd kafka; do
        f=$(list_data_file "$name") || true
        [[ -z "$f" ]] && continue
        python3 - "$name" "$f" << 'PY' || true
import json, sys
d=json.load(open(sys.argv[2]))
p=d.get("participants",{})
n=len(p)
top="—"
if p:
    first=p[0]
    top=f"{first.get('name','?')} ({first.get('count',0)})"
print(f"| {sys.argv[1]} | {n} | {top} |")
PY
    done
    echo "</details>"
    echo ""
}

section_l3_participation() {
    echo "### L3 — Participation Signals"
    echo ""
    echo "**Mail traffic trend and newcomer detection for ${YYYYMM}.**"
    echo ""
    echo "| List | Emails | Threads | Participants | Top sender |"
    echo "|------|--------|---------|--------------|------------|"
    for name in announce incubator httpd kafka hadoop; do
        f=$(list_data_file "$name") || true
        [[ -z "$f" ]] && continue
        python3 - "$name" "$f" << 'PY' || true
import json, sys
d=json.load(open(sys.argv[2]))
emails=len(d.get("emails",[]))
threads=len(d.get("thread_struct",[]))
participants=len(d.get("participants",[]))
top="—"
p=d.get("participants",[])
if p:
    first=p[0]
    top=f"{first.get('name','?')} ({first.get('count',0)})"
print(f"| {sys.argv[1]} | {emails} | {threads} | {participants} | {top} |")
PY
    done
    echo ""
}

# ---- main ----
main() {
    echo "# ASF Pulse — Signal Report"
    echo ""
    echo "**Month:** ${YYYYMM}"
    echo "**Source:** lists.apache.org JSON API (PonyMail)"
    echo ""

    section_l1_lifecycle
    echo "---"
    echo ""
    section_l2_governance
    echo "---"
    echo ""
    section_l3_participation
}

main
